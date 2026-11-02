# Changelog

## 1.2.0 — 2026-11-02

* Publishes Android 17 support for the audited Infinity-X 4.1 guacamoleb build, with the same integrity-checked HAL tested in RC2.
* Includes the corrected vendor-namespace dependency check, system/vendor packaging, independent backups, safe disable, bounded monitoring and reproducible ZIP builder.
* RC2 installed successfully through KernelSU Next / Hybrid Mount; the maintainer confirmed the module works. The test scope and remaining limitations are recorded in `docs/ANDROID17-VALIDATION.md`.
* Licenses original module scripts, packaging tools, tests and documentation under GPL-3.0-or-later. The LineageOS-derived HAL and its patch/integration components retain Apache-2.0 and their notices. Existing releases are unchanged.


## 1.2.0-rc2 — 2026-11-02

* Fixes the install-time linker check: `/data/adb/modules_update` maps to the isolated system namespace, which cannot resolve the private vendor AIDL library. Check the integrity-verified payload in a private temporary directory under `/data/local/tests/vendor`, then remove it.
* Retains the dependency gate and all ROM/hash checks. No global linker configuration, library path environment or SELinux policy is changed.
* Prints loader errors before the root manager removes a failed installation.
* The RC1 permanent installation attempt stopped safely before staging a usable module; no reboot occurred. The unchanged HAL passed the earlier live tests.


## 1.2.0-rc1 — 2026-11-02

* Adds narrowly scoped Android 17 support for the audited Infinity-X 4.1 build, with an original HAL hash gate, page-size/architecture checks and dependency diagnostics.
* Keeps the existing payload after a reversible five-profile runtime test; no blind address patch of the Android 17 stock HAL.
* Corrects packaging to `system/vendor`, the exact service-presence check, and device identity matching.
* Adds independent upgrade backups and a safe-disable helper; diagnostics are read only.
* Bounds boot/repair retries and log growth; stops on Binder/verification failures.
* Produces byte-reproducible ZIPs using sorted paths, fixed timestamps/permissions and ZIP_STORED.
* Adds safety regression tests and a detailed validation/recovery record.
* Reboot/mount-manager activation and long-term behavior remain unvalidated; this is a release candidate.


## 1.1.1.1 — 2026-07-15

* Documents the immediate build provenance of the bundled HAL (Infinity-X, 2026-06-15, guacamoleb) alongside the upstream LineageOS Apache-2.0 source in `NOTICE`, `SOURCE.md` and `AUTHORS`.
* Adds SPDX headers to all original scripts and patch tooling.
* Adds a trademark disclaimer and a risk/safety note to the README.
* Adds a "Background" section documenting this as independent research.
* Adds a device compatibility table, `CONTRIBUTING.md` and a compatibility-report issue template to support extending validated coverage across the OnePlus 7 family.
* Adds `SECURITY.md` for reporting bootloops/bricks and safety issues.
* Adds CI (ShellCheck, Python lint, and a build/HAL-integrity check) via GitHub Actions.
* Fixes an unused `MODE_FILE` variable in `module/customize.sh` (ShellCheck SC2034); no behavioural change.

No change to the bundled HAL binary or the fifth display profile's behaviour; this is a documentation, licensing-hygiene and tooling release.

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

