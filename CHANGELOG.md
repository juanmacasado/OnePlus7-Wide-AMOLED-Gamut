# Changelog

## Unreleased

* Documents the immediate build provenance of the bundled HAL (Infinity-X, 2026-06-15, guacamoleb) alongside the upstream LineageOS Apache-2.0 source in `NOTICE`, `SOURCE.md` and `AUTHORS`.
* Adds SPDX headers to all original scripts and patch tooling.
* Adds a trademark disclaimer and a risk/safety note to the README.
* Adds a "Background" section documenting this as independent research.
* Adds a device compatibility table, `CONTRIBUTING.md` and a compatibility-report issue template to support extending validated coverage across the OnePlus 7 family.
* Adds `SECURITY.md` for reporting bootloops/bricks and safety issues.
* Adds CI (ShellCheck, Python lint, and a build/HAL-integrity check) via GitHub Actions.

No functional change to the flashable module itself; `module.prop` version remains 1.1.0.

## 1.1.0 — 2026-06-20

* Adds Wide AMOLED Gamut as a fifth native LiveDisplay color profile.
* Preserves the original Vivid, Natural, Cinematic and Brilliant profiles.
* Supports compatible Android 16 ROMs based on the standard Oplus AIDL LiveDisplay stack.
* Adds semantic and ABI compatibility checks for the OnePlus 7.
* Verifies the integrity of the bundled five-mode HAL.
* Persists and reapplies the selected profile after boot.
* Verifies both the active QDCM profile and Oplus seed.
* Provides a safe uninstall path that restores a stock-compatible profile.
* Includes a source-level integration patch for ROM maintainers.
* Does not require or install a companion APK.

