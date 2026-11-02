# Licensing map (from version 1.2.0)

Copyright 2026 juanmacasado, except where other copyright holders are identified.

## Original module and tooling — GPL-3.0-or-later

The original scripts in `module/`, packaging scripts in `scripts/`, tests in
`tests/`, project documentation and original repository metadata/configuration
are licensed under the GNU General Public License, version 3 or (at your option)
any later version. The complete GPLv3 text is in `LICENSE`. These programs are
distributed without any warranty; see the license for details. The preferred
source form is included in this repository; the ZIP's module shell scripts are
also distributed directly as source.

New contributions in these areas use GPL-3.0-or-later. Copyright and attribution
notices are retained. Licensing changes apply to this release onward; permissions
already granted with previous Apache-2.0 releases are not withdrawn.

## Separately licensed HAL and integration components — Apache-2.0

The following components retain Apache License 2.0:

- `prebuilt/vendor/bin/hw/vendor.lineage.livedisplay-service.oplus` (packaged under
  `system/vendor/bin/hw/` in the module ZIP).
- All source and tooling under `patches/`, including the trampoline assembly,
  linker script, Python binary patcher and authored source-integration patch.

The upstream implementation is copyright 2019–2025 The LineageOS Project.
Project additions in these components are copyright 2026 juanmacasado.
`LICENSES/Apache-2.0.txt`, `NOTICE`, `AUTHORS` and `SOURCE.md` preserve the license,
attribution and immediate binary provenance. Upstream rights are not replaced
by the GPL license used for the separate module scripts. Keeping the integration
patch Apache-2.0 also permits its inclusion in the Apache-licensed upstream HAL.

The prebuilt remains a documented binary-patched Android 16 object, not a new
source-built Android 17 object. It has not been relicensed as a GPL binary;
patch reproduction and source-build provenance are distinguished in `SOURCE.md`.
The module does not redistribute the ROM's dynamically linked system/vendor
libraries or change their separate licenses.

## Distribution

Flashable ZIPs include `LICENSE`, `LICENSES/Apache-2.0.txt`, this licensing map
and `NOTICE`. GitHub's license summary is not a substitute for this component
map. Release source archives include the project source and build instructions.
