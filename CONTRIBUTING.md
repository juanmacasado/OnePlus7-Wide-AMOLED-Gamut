# Contributing

## Reporting compatibility on another device or ROM

This module is validated end-to-end only on `guacamoleb`. Reports for any
other OnePlus 7 family codename or ROM build are the most valuable
contribution right now — see the [device compatibility table](README.md#supported-scope).

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

## Contribution licensing

New contributions to the original module, packaging tools, tests and project
documentation are submitted under GPL-3.0-or-later unless explicitly agreed
otherwise. Contributions to the Apache-2.0 HAL patch tooling and ROM integration
patch retain Apache-2.0. Preserve existing copyright and SPDX notices. See
`LICENSING.md`; previously published versions keep their original licenses.

For 1.3.0-rc1 portable detection, LineageOS/crDroid source review is distinguished
from physical testing. Include `compatibility.info` and post-boot Action output;
never bypass a rejected contract check. See `docs/PORTABLE-COMPATIBILITY.md`.
