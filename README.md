# OnePlus 7 Wide AMOLED Gamut — LineageOS / crDroid / Infinity-X

A KernelSU/Magisk module by **juanmacasado** that adds **Wide AMOLED Gamut** as a
fifth native LiveDisplay profile on the OnePlus 7. No companion APK is required.

**1.3.0-rc1 adds ROM-independent compatibility detection for Android 16/17.**
LineageOS 24, crDroid Android 17 and other LineageOS-derived ROMs are admitted
when their Oplus LiveDisplay, panel and loader contract matches. No Infinity-X
build string or stock HAL hash is required.

This is a **prerelease**: the unchanged HAL was tested on Infinity-X 4.1, while
the newly broadened installer has source/host-test coverage and awaits device
reports on the other ROMs. Keep 1.2.0 as the stable reference. See the
[portable compatibility audit](docs/PORTABLE-COMPATIBILITY.md),
[earlier device validation](docs/ANDROID17-VALIDATION.md) and
[recovery instructions](docs/RECOVERY.md).

Independent community project; not affiliated with or endorsed by LineageOS,
OnePlus, OxygenOS, Infinity-X or any other ROM project. Names identify
compatibility only. The module overlays a vendor HAL and requests panel modes;
an incompatible HAL or mounting setup can break LiveDisplay or system startup.

## Supported scope

| Device / platform | Detection and evidence |
| --- | --- |
| OnePlus 7 / Android 17 / Infinity-X 4.1 | Earlier physical HAL validation; new contract gates await a new device run |
| OnePlus 7 / Android 17 / LineageOS 24 or crDroid | Matching HAL/device sources reviewed; runtime-contract detection enabled; physical tests pending |
| OnePlus 7 / Android 17 / other LineageOS-derived ROMs | Same contract required, independent of branding; physical tests pending |
| OnePlus 7 / Android 16 / SDK 36 | Same new contract gates; prior-version scope retained |
| Other devices or SDKs | Rejected |

Every install requires arm64, 4 KiB pages, Oplus panel support, exactly the
supported companion services, the frozen AIDL V1 version/hash, the standard
four-profile map and QDCM modes, plus integrity and vendor-namespace linker
validation. Unknown service/profile maps fail closed. Sharing a LineageOS base
alone is insufficient; see the [full contract](docs/PORTABLE-COMPATIBILITY.md).
Recovery installation is rejected. No ROM, kernel or partition is flashed by
the compatibility checks.

## Profiles

| ID | LiveDisplay profile | QDCM panel mode | Oplus seed |
| --- | --- | --- | --- |
| 0 | Vivid | zhal_native | 0 |
| 1 | Natural | SRGB | 1 |
| 2 | Cinematic / P3 | zhal_native | 1 |
| 3 | Brilliant | advance_p3 | 0 |
| 4 | Wide AMOLED Gamut | advance_native | 3 |

Wide AMOLED Gamut uses the display firmware's existing `advance_native` mode;
this project exposes it in the native profile list while preserving all four
stock profiles. Driver/QDCM verification is not a colorimeter measurement of
gamut or accuracy. Settings reads the fifth profile from the HAL; no overlay,
SurfaceFlinger property override or feature spoof is installed.

## Build and installation

```sh
bash scripts/build-module.sh
python3 -m unittest discover -s tests -v
```

Python 3 is the only packaging dependency. The output and SHA-256 file are in
`out/`. Sorted paths, fixed UTC timestamps and permissions, and uncompressed ZIP
entries make builds byte reproducible. Optional `SOURCE_DATE_EPOCH` must be the
same for comparisons. The HAL remains the original documented binary-patched
prebuilt; see [source and reproducibility notes](SOURCE.md).

1. Preserve the previous ZIP on the computer.
2. Install the ZIP in KernelSU Next/Magisk on a matching ROM. KernelSU requires
   a working mount-capable metamodule.
3. Read the installer results and copy its independent backup from
   `/data/adb/oneplus7-gamut-backups/` to the computer before rebooting.
4. With recovery access prepared, perform a controlled reboot and confirm the
   five profiles in Settings → Display → LiveDisplay → Color profile.

The payload is packaged under `system/vendor/bin/hw/`, the standard module
mount layout. The physical vendor partition is never written. Do not disable
and immediately reboot while persisted mode 4 is selected: use the
[safe-disable helper](docs/RECOVERY.md), which selects and verifies Natural.
Uninstall also normalizes the profile; independent backups are retained.

## Diagnostics and runtime

The module Action is read only. It reports persisted/current mode, seed,
Qualcomm panel QDCM, ROM, service state, visible HAL hash and installation record.
SF's framework `ColorMode::SRGB` is a different field from Qualcomm's panel mode.

- Runtime log: `/data/adb/modules/oneplus7_extended_display_modes/display-modes.log`
- Installation record: `/data/adb/modules/oneplus7_extended_display_modes/compatibility.info`
- Dependency check: `/data/adb/modules/oneplus7_extended_display_modes/linker-check.txt`

The service waits at most 240 seconds for boot/HAL readiness, makes at most three
boot repair attempts and stops on repeated failures. The monitor checks seed
at five-second intervals; it does not claim continuous QDCM or HDR verification.
No SELinux policy changes are shipped. Logs are bounded throughout operation.

## ROM integration and attribution

The preferred fully source-built route is to apply the authored
[source patch](patches/0001-oplus-livedisplay-add-Wide-AMOLED-Gamut-display-mode.patch)
and build the HAL with the ROM. The existing prebuilt was binary-patched from an
Infinity-X Android 16 HAL; it should not be incorporated into a ROM build.
See the [integration guide](docs/INTEGRATION.md), [SOURCE.md](SOURCE.md),
[NOTICE](NOTICE), [LICENSE](LICENSE) and [contribution guide](CONTRIBUTING.md).
Preserve original Git authorship when applying the integration patch.

## License

Original module scripts, packaging tools, tests and project documentation are
licensed under **GNU GPL version 3 or later** (`GPL-3.0-or-later`). See [LICENSE](LICENSE).

The bundled LineageOS-derived HAL, its binary-patch tooling and ROM integration
patch retain **Apache-2.0**, with their original notices and license text. These
are separately identified components, not relicensed GPL binaries. See the
[licensing map](LICENSING.md), [Apache license](LICENSES/Apache-2.0.txt) and
[NOTICE](NOTICE). Previous Apache-2.0 releases retain their original permissions.
