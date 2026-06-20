# ROM integration guide

This document describes the preferred source-level integration for ROM maintainers.

## Target

Repository:

```text
LineageOS/android_hardware_oplus
```

File:

```text
aidl/livedisplay/DisplayModes.cpp
```

## Source change

Add the following entry to `DisplayModes::kModeMap`:

```cpp
{4, {"Wide AMOLED Gamut", 2, 3}},
```

The complete map becomes:

```cpp
const std::map<int32_t, DisplayModes::ModeInfo> DisplayModes::kModeMap = {
        {0, {"Vivid", 0, 0}},
        {1, {"Natural", 1, 1}},
        {2, {"Cinematic", 0, 1}},
        {3, {"Brilliant", 4, 0}},
        {4, {"Wide AMOLED Gamut", 2, 3}},
};
```

## Resulting profiles

| ID | Profile           |            QDCM mode | Oplus seed |
| -: | ----------------- | -------------------: | ---------: |
|  0 | Vivid             |    0 (`zhal_native`) |          0 |
|  1 | Natural           |           1 (`SRGB`) |          1 |
|  2 | Cinematic         |    0 (`zhal_native`) |          1 |
|  3 | Brilliant         |     4 (`advance_p3`) |          0 |
|  4 | Wide AMOLED Gamut | 2 (`advance_native`) |          3 |

LiveDisplay obtains the profile list from the HAL, so the fifth entry appears automatically in the standard color profile menu.

## Apply the supplied patch

From the root of `android_hardware_oplus`:

```bash
git am /path/to/0001-oplus-livedisplay-add-Wide-AMOLED-Gamut-display-mode.patch
```

Alternatively, maintainers may cherry-pick the original commit when the repository containing it is available.

## Attribution

The preferred integration method is to preserve the original Git authorship.

## Requirements

* OnePlus 7 display stack compatible with OxygenOS 12 firmware.
* Oplus AIDL LiveDisplay service.
* Display Modes support enabled in `android_hardware_oplus`.
* `/dev/oplus_display` and panel seed support.
* QDCM modes 0, 1, 2 and 4 available.

## Validation

The implementation was validated on the OnePlus 7 (`guacamoleb`) with Infinity-X Android 16.

Expected Wide AMOLED Gamut state:

```text
mode ID: 4
QDCM: advance_native
seed: 3
```

