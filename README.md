# OnePlus 7 Wide AMOLED Gamut — portable LineageOS edition

A KernelSU/Magisk module that adds **Wide AMOLED Gamut** as a fifth native profile inside LiveDisplay on the OnePlus 7. It does not install or require a companion APK.

## Portable compatibility model

This release is not tied to an Infinity-X build hash. Custom ROMs often compile the same LineageOS/Oplus LiveDisplay source into different binaries, so exact SHA-256 matching would reject otherwise compatible ROMs.

The installer instead validates the runtime contract:

- OnePlus 7 identity (`guacamoleb`, `OnePlus7` or GM190x).
- Android 16 (SDK 36).
- OxygenOS 12-compatible Oplus display stack (`/dev/oplus_display` and the panel seed node).
- The standard AIDL service `vendor.lineage.livedisplay.IDisplayModes/default`.
- The standard four profiles: Vivid, Natural, Cinematic and Brilliant.
- The expected OnePlus 7 LiveDisplay companion interfaces.
- The stable `vendor.lineage.livedisplay-V1-ndk.so` dependency.

The ROM's HAL hash is recorded for diagnostics but is no longer used as a ROM lock.

## Supported scope

Designed for **LineageOS-derived Android 16 ROMs for the OnePlus 7 that use the standard Oplus AIDL LiveDisplay service and OxygenOS 12 display firmware**. Infinity-X Android 16 is tested. Other matching ROMs are supported by compatibility detection but remain community-tested until reported.

This does not mean every ROM that merely contains a menu named LiveDisplay is automatically compatible. The installer aborts before changing anything unless the service, panel interface and standard profile signatures all match.

## Display profiles

| ID | LiveDisplay profile | QDCM mode | Oplus seed |
|---:|---|---|---:|
| 0 | Vivid | `zhal_native` | 0 |
| 1 | Natural | `SRGB` | 1 |
| 2 | Cinematic / P3 | `zhal_native` | 1 |
| 3 | Brilliant | `advance_p3` | 0 |
| 4 | Wide AMOLED Gamut | `advance_native` | 3 |

The fifth mode is exposed by the LiveDisplay HAL itself and appears directly in **Settings → Display → LiveDisplay → Color profile**.

## Installation

1. Flash the ZIP in KernelSU Next or Magisk.
2. Read the compatibility result in the installer log.
3. Reboot completely.
4. Select any of the five profiles in LiveDisplay.

The module can be disabled without modifying the physical vendor partition. On uninstall it first switches to Natural so the stock four-mode HAL never receives persisted mode ID 4.

## Runtime behaviour

- Persists the selected profile through the HAL's normal `makeDefault` mechanism.
- Reapplies the profile after Android finishes booting.
- Verifies both QDCM and the Oplus seed.

## Diagnostics

KernelSU/Magisk module Action shows the ROM, Android version, selected mode, seed, QDCM state, service state and HAL hashes.

Runtime log:

```text
/data/adb/modules/oneplus7_extended_display_modes/display-modes.log
```

Installation compatibility record:

```text
/data/adb/modules/oneplus7_extended_display_modes/compatibility.info
```

## Author

**juanmacasado**

See `SOURCE.md`, `NOTICE` and `LICENSE` for source, attribution and licensing information.

## ROM maintainers

The preferred way to integrate this feature into a ROM is at source level. The flashable module is provided primarily as a tested reference implementation and as a way to validate the feature without rebuilding the ROM.

Resources:

* [ROM integration guide](docs/INTEGRATION.md)
* [Source integration patch](patches/0001-oplus-livedisplay-add-Wide-AMOLED-Gamut-display-mode.patch)
* [Source and reproducibility notes](SOURCE.md)

The source change adds the following fifth entry to the Oplus LiveDisplay mode map:

```cpp
{4, {"Wide AMOLED Gamut", 2, 3}},
```

This exposes Wide AMOLED Gamut directly in the standard LiveDisplay color profile menu, using QDCM mode `2` (`advance_native`) and Oplus seed `3`.

ROM maintainers are requested to preserve the original Git authorship by applying the supplied patch with `git am` or cherry-picking the original commit.

The prebuilt HAL included in the module should not be incorporated into a ROM build. ROM maintainers should apply the source patch and rebuild `vendor.lineage.livedisplay-service.oplus` as part of the ROM.

