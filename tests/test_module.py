# SPDX-FileCopyrightText: 2026 juanmacasado
# SPDX-License-Identifier: GPL-3.0-or-later
"""Safety regressions for installer gates and reproducible packaging."""
import hashlib
import os
import shutil
import subprocess
import tempfile
import unittest
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STOCK = 'e560a2af35908d40e6f564f2f72bb315ddd3bd3cc3da13fca49c2bcdc3ce40e5'
PAYLOAD = '277edf431056e91a8dbf69582b4dd788abe13958b9222deb21247254dcfeeb3f'


class ModuleTests(unittest.TestCase):
    def shell(self, script, **env):
        return subprocess.run(['sh', '-c', script], text=True, capture_output=True,
                              env={**os.environ, **env}, check=False)

    def test_service_not_found_is_rejected(self):
        common = str(ROOT / 'module/common.sh')
        for output, expected in [('Service x: found', 0),
                                 ('Service x: not found', 1),
                                 ('Service x does not exist', 1)]:
            result = self.shell(f'. "{common}"; service() {{ echo "$REPLY"; }}; service_ready',
                                REPLY=output)
            self.assertEqual(result.returncode, expected)

    def test_panel_state_is_distinct_from_sf_color_mode(self):
        result = self.shell(f'''. "{ROOT / 'module/common.sh'}"
            dumpsys() {{ printf '%s\\n' 'Current color mode: ColorMode::SRGB (7)' 'Current Color Mode: advance_native'; }}
            read_qdcm''')
        self.assertEqual(result.stdout.strip(), 'advance_native')

    def test_binder_exception_is_rejected(self):
        for reply, expected in [("Result: Parcel(\t00000000    '....')", 0),
                                ('Result: Parcel( ffffffff )', 1),
                                ('service: Service does not exist', 1)]:
            result = self.shell(f'. "{ROOT / "module/common.sh"}"; mode_succeeded "$REPLY"',
                                REPLY=reply)
            self.assertEqual(result.returncode, expected)

    def test_installer_gates_before_backups(self):
        cases = [({}, True), ({'SDK': '36'}, True), ({'SDK': '38'}, False),
                 ({'SDK': 'bad'}, False), ({'MODEL': 'OnePlus7Pro'}, False),
                 ({'PAGES': '16384'}, False), ({'HAL_HASH': 'unknown'}, False),
                 ({'ROM': 'different'}, False), ({'MOCK_PAYLOAD_HASH': 'corrupt'}, False),
                 ({'SERVICE_REPLY': 'Service x: not found'}, False),
                 ({'LINK_STATUS': '1'}, False), ({'BOOTMODE': 'false'}, False)]
        for override, accept in cases:
            with self.subTest(override=override), tempfile.TemporaryDirectory() as folder:
                root = Path(folder)
                stage = root / 'module'
                shutil.copytree(ROOT / 'module', stage)
                target = root / 'stock-hal'
                seed = root / 'seed'
                mode = root / 'mode'
                panel = root / 'panel'
                seed.write_text('0')
                mode.write_text('0')
                panel.touch()
                target.write_text(' '.join(['vendor.lineage.livedisplay-V1-ndk.so',
                    'IDisplayModes', '/dev/oplus_display', str(mode), 'DisplayModesService',
                    'Natural', 'Cinematic', 'Brilliant', 'IAntiFlicker',
                    'IPictureAdjustment', 'ISunlightEnhancement']))
                payload = stage / 'system/vendor/bin/hw/vendor.lineage.livedisplay-service.oplus'
                payload.parent.mkdir(parents=True)
                payload.write_bytes(b'payload')
                common = (stage / 'common.sh').read_text()
                for key, value in [('BIN', target), ('SEED_NODE', seed), ('MODE_FILE', mode)]:
                    common = '\n'.join(f'{key}={value}' if line.startswith(key + '=') else line
                                       for line in common.split('\n'))
                (stage / 'common.sh').write_text(common)
                installer = (stage / 'customize.sh').read_text()
                installer = installer.replace('[ -e /dev/oplus_display ]', f'[ -e {panel} ]')
                installer = installer.replace('/system/bin/linker64 --list', 'fake_linker')
                installer = installer.replace('LINKER_ROOT=/data/local/tests/vendor',
                                              f'LINKER_ROOT={root / "vendor-test"}')
                installer = installer.replace('/data/adb/oneplus7-gamut-backups', str(root / 'backups'))
                installer = installer.replace('/data/adb/modules/oneplus7_extended_display_modes', str(root / 'previous'))
                (stage / 'customize.sh').write_text(installer)
                wrapper = '''
                  ui_print() { echo "$*"; }; abort() { echo "$*"; exit 99; }
                  id() { echo 0; }; getconf() { echo "$PAGES"; }
                  getprop() { case "$1" in
                    ro.product.device|ro.product.vendor.device|ro.product.model|ro.infinity.device) echo "$MODEL" ;;
                    ro.build.version.sdk) echo "$SDK" ;;
                    ro.infinity.build.version) echo "$ROM" ;; esac; }
                  service() { echo "$SERVICE_REPLY"; }
                  fake_linker() { return "$LINK_STATUS"; }
                  sha256sum() { case "$1" in
                    */stock-hal) echo "$HAL_HASH  $1" ;;
                    *) echo "$MOCK_PAYLOAD_HASH  $1" ;; esac; }
                  set_perm() { :; }; set_perm_recursive() { :; }
                  . "$MODPATH/customize.sh"
                '''
                env = {'SDK': '37', 'MODEL': 'guacamoleb', 'PAGES': '4096', 'HAL_HASH': STOCK,
                       'MOCK_PAYLOAD_HASH': PAYLOAD, 'ROM': 'Project_Infinity-X-4.1-guacamoleb-02.11.2026',
                       'SERVICE_REPLY': 'Service x: found', 'BOOTMODE': 'true', 'ARCH': 'arm64',
                       'LINK_STATUS': '0', 'MODPATH': str(stage)}
                result = self.shell(wrapper, **(env | override))
                self.assertEqual(result.returncode == 0, accept, result.stdout + result.stderr)
                self.assertEqual((root / 'backups').exists(), accept)
                self.assertEqual(mode.read_text(), '0')
                if (root / 'vendor-test').exists():
                    self.assertEqual(list((root / 'vendor-test').iterdir()), [])

    def test_zip_determinism_and_mount_layout(self):
        with tempfile.TemporaryDirectory() as folder:
            copy = Path(folder) / 'repo'
            shutil.copytree(ROOT, copy, ignore=shutil.ignore_patterns('.git', 'out', '__pycache__'))
            build = ['python3', str(copy / 'scripts/build-module.py')]
            env = {**os.environ, 'SOURCE_DATE_EPOCH': '315532800'}
            subprocess.run(build, env=env, check=True, capture_output=True)
            archive = next((copy / 'out').glob('*.zip'))
            before = archive.read_bytes()
            for path in (copy / 'module').rglob('*'):
                os.utime(path, (1700000000, 1700000000))
                if path.is_file():
                    path.chmod(0o600)
            subprocess.run(build, env=env, check=True, capture_output=True)
            self.assertEqual(before, archive.read_bytes())
            with zipfile.ZipFile(archive) as z:
                name = 'system/vendor/bin/hw/vendor.lineage.livedisplay-service.oplus'
                self.assertEqual(hashlib.sha256(z.read(name)).hexdigest(), PAYLOAD)
                self.assertEqual(z.getinfo(name).external_attr >> 16 & 0o777, 0o755)
                self.assertFalse(any(n.startswith('vendor/') for n in z.namelist()))
                self.assertIn('GNU GENERAL PUBLIC LICENSE', z.read('LICENSE').decode())
                self.assertIn('Apache License', z.read('LICENSES/Apache-2.0.txt').decode())
                self.assertIn('GPL-3.0-or-later', z.read('common.sh').decode())
                self.assertIn('LICENSING.md', z.namelist())
                self.assertIsNone(z.testzip())


if __name__ == '__main__':
    unittest.main()
