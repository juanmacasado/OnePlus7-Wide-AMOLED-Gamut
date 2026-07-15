# Contributing

## Reporting compatibility on another device or ROM

This module is validated end-to-end only on `guacamoleb`. Reports for any
other OnePlus 7 family codename or ROM build are the most valuable
contribution right now — see the [device compatibility table](README.md#device-compatibility).

To report a result (working or not), open an issue with:

* Whether the module installed, and whether the fifth profile appeared and worked correctly.
* Device codename and model (`ro.product.device`, `ro.product.model`).
* ROM name/build (`ro.build.display.id`, `ro.build.fingerprint`).
* `/data/adb/modules/oneplus7_extended_display_modes/compatibility.info`
* `/data/adb/modules/oneplus7_extended_display_modes/display-modes.log`

## Source-level ROM integration

If you maintain a ROM and want to integrate this at source level instead of
via the flashable module, see `docs/INTEGRATION.md` and apply
`patches/0001-oplus-livedisplay-add-Wide-AMOLED-Gamut-display-mode.patch` with
`git am` to preserve original authorship.

## Code changes

Shell scripts under `module/` and `scripts/` are linted with ShellCheck in CI.
`patches/build-five-mode-hal.py` is linted with `ruff`. Please keep both
clean, and run `scripts/build-module.sh` locally to confirm the flashable
module still builds before opening a pull request.
