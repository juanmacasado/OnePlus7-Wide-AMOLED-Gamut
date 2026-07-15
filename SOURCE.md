# Source, portability and reproducibility

## Upstream implementation

This module derives from the LineageOS OnePlus LiveDisplay implementation in:

- Repository: `LineageOS/android_hardware_oplus`
- File: `aidl/livedisplay/DisplayModes.cpp`
- License: Apache-2.0

The upstream map is unchanged across the reviewed LineageOS 22.2, 23.0 and 23.2 branches:

```text
0 Vivid      -> display mode 0, seed 0
1 Natural    -> display mode 1, seed 1
2 Cinematic  -> display mode 0, seed 1
3 Brilliant  -> display mode 4, seed 0
```

The modification preserves those modes and adds:

```text
4 Wide AMOLED Gamut -> display mode 2, seed 3
```

## Immediate build provenance

The tested and bundled prebuilt is not built by this project from source. It is
a binary patch applied to the `vendor.lineage.livedisplay-service.oplus`
extracted from the Infinity-X (Android 16, guacamoleb) build dated
2026-06-15, before this project's modification. That input binary is treated
as an unmodified compile of the upstream `android_hardware_oplus` Apache-2.0
source for `DisplayModes.cpp`: no Infinity-X-specific changes to that file are
known to exist, and the patch tooling (`patches/build-five-mode-hal.py`)
verifies the input against a known SHA-256 before touching it, so it will
refuse to run against an unexpected or differently-modified binary.

Copyright in the underlying source remains with The LineageOS Project
(Apache-2.0). Infinity-X and other ROM projects are credited as the immediate
build source of the specific bytes, per `NOTICE`, and are not otherwise
affiliated with this project.

## Why this installer is portable across ROM builds

ROMs can compile identical source with different toolchains, build IDs and optimization output, so their HAL SHA-256 values differ. Version 1.1.0 no longer requires an Infinity-X hash, but the bundled prebuilt is intentionally limited to Android 16 / SDK 36. It verifies the device, Android generation, AIDL service, Oplus panel interface, stable NDK dependency, standard profile names and OnePlus 7 companion interfaces.

The replacement binary is still a known, integrity-checked prebuilt. The installer does not byte-patch an unknown ROM binary and does not claim compatibility when the semantic/ABI checks fail.

## Reproducing the current prebuilt

The source archive contains the exact patching tools used for the tested binary:

- `patches/build-five-mode-hal.py`
- `patches/five_mode_trampoline.S`
- `patches/five_mode_trampoline.ld`

The bundled replacement SHA-256 is:

```text
277edf431056e91a8dbf69582b4dd788abe13958b9222deb21247254dcfeeb3f
```

For a future fully source-built release, apply the following logical source change before building `vendor.lineage.livedisplay-service.oplus`:

```cpp
{4, {"Wide AMOLED Gamut", 2, 3}},
```

inside `DisplayModes::kModeMap`.
