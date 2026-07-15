# Security policy

This project replaces a `/vendor` HAL binary and writes to kernel display
nodes on the OnePlus 7. The most relevant "security" issues here are safety
issues: a bootloop, a bricked vendor partition, or a corrupted display state
caused by an unexpected ROM build passing the compatibility checks it
shouldn't have.

## Reporting a bootloop, brick, or a compatibility check that passed incorrectly

Please open a GitHub issue rather than a private report — these are safety
issues for other users too, and public tracking helps identify which ROM
builds are actually affected.

Include, if you can still access them (e.g. via a data backup or before
reflashing):

* `/data/adb/modules/oneplus7_extended_display_modes/compatibility.info`
* `/data/adb/modules/oneplus7_extended_display_modes/display-modes.log`
* Your ROM's `ro.build.fingerprint` / `ro.build.display.id`
* Whether you recovered by reflashing the stock `vendor` image, and how

## Reporting a genuine vulnerability

If you believe you've found an issue with security impact beyond device
recovery (e.g. a way the module could be used to escalate privileges or
weaken SELinux enforcement beyond what's documented in `module/customize.sh`),
please open a GitHub issue marked clearly as a security concern, or contact
the maintainer listed in `AUTHORS` directly.

## Scope

This module only targets the OnePlus 7 family running LineageOS-derived
Android 16 ROMs with the standard Oplus AIDL LiveDisplay stack described in
`README.md`. Reports about unrelated devices or ROMs are out of scope.
