# Changelog

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

