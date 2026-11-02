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

ROMs can compile identical source with different toolchains, build IDs and optimization output, so their HAL SHA-256 values differ. Version 1.1.0 no longer requires an Infinity-X hash, with semantic checks on Android 16 / SDK 36. Version 1.2.0 also admits only the audited Android 17 / SDK 37 Infinity-X 4.1 build, after a reversible runtime test of the unchanged payload. It verifies the device, Android generation, AIDL service, Oplus panel interface, stable NDK dependency, standard profile names and OnePlus 7 companion interfaces.

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

## Android 17 RC and deterministic packaging

See `docs/ANDROID17-VALIDATION.md` for the exact ROM and hashes. The stock SDK 37
HAL has different code addresses: the old patch must never be applied to it.
The distributed payload has **not** changed and is **not** a newly source-built
Android 17 HAL. Its private C++ ABI was checked by loading/running on the tested
ROM; matching AIDL V1 signatures alone would not establish compatibility.

Run `bash scripts/build-module.sh` with Python 3 to generate the ZIP. All paths
are sorted; permissions and UTC timestamps are fixed (default 1980-01-01).
`SOURCE_DATE_EPOCH` may override the timestamp; use the same value to reproduce
the same bytes. ZIP_STORED avoids compression-library differences. This
reproduces the package from the source tree and prebuilt, not the upstream HAL
from C++ source. `python3 -m unittest discover -s tests -v` checks reproducibility
and installer safety gates.

## Licensing by component

From 1.2.0, the project's original module scripts, packaging tools, tests and
documentation use GPL-3.0-or-later. The existing HAL and `patches/` components
remain Apache-2.0. The payload bytes and source-integration patch are unchanged;
no claim is made that the prebuilt has been relicensed to GPL. See `LICENSING.md`.
