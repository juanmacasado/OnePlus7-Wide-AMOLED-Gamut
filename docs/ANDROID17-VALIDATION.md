# Android 17 / Infinity-X 4.1 validation — 2026-11-02

Public release: **1.2.0**, using the same payload as the tested RC2.
The initial audit below used reversible runtime tests. RC2 was subsequently
installed successfully through KernelSU Next / Hybrid Mount and the maintainer
reported that the module works. A separate agent-captured post-install boot
audit was not completed: the phone disconnected before the read-only inspection.

## Device and observed contract

- OnePlus 7, GM1901, ROM codename guacamoleb; product device property OnePlus7.
- Infinity-X 4.1 Vanilla as identified by the user; device reports
  `Project_Infinity-X-4.1-guacamoleb-02.11.2026`, Android 17, SDK 37,
  build ID `CP2A.260605.016`.
- Kernel 4.14.357, arm64, 4096-byte pages, SELinux Enforcing.
- KernelSU Next 3.4.2 with Hybrid Mount 6.2.5 observed; no Termux package was
  present. Diagnostics and tests used explicitly authorized temporary ADB root.
- `/vendor` is a separate read-only ext4 partition on slot B (`sde44`), with
  `vendor_a` and `vendor_b` block aliases. No vendor remount or block write.
- The build fingerprint reports Android 12/OxygenOS; it is unsuitable for
  determining the Android generation. SDK and ROM properties report 17/37.
- The same four AIDL companions remain: IDisplayModes, IAntiFlicker,
  IPictureAdjustment and ISunlightEnhancement, with the V1 NDK library.
- Composer is still the Qualcomm HIDL 2.4 service. SF reports wide-color support,
  NATIVE, SRGB and DISPLAY_P3. Qualcomm's own dump lists advance_native ID 2.
- Existing framework/Oplus/Settings/Lineage overlays and the
  `org.lineageos.livedisplay` feature are present. No RRO or feature override was
  necessary to expose the fifth HAL entry during the runtime test.

There was no captured Android 16 full-system baseline for overlays/partitions.
These are observations of the current ROM, not a claimed exhaustive 16→17 diff.
The old ZIP and its binary were compared against the current repository and
on-device HAL. Its module scripts and payload match the original repository.

## Binary and ABI assessment

Original Android 17 HAL SHA-256:
`e560a2af35908d40e6f564f2f72bb315ddd3bd3cc3da13fca49c2bcdc3ce40e5`

Distributed five-mode HAL (unchanged from 1.1.1.1):
`277edf431056e91a8dbf69582b4dd788abe13958b9222deb21247254dcfeeb3f`

The current stock binary has different instructions/layout from the old one;
applying the old address patch to it would be invalid. Instead, the existing
known payload was verified against this ROM. Android's loader resolved the
libraries using the actual `/vendor/bin/hw/…` path in a temporary mount, and the
HAL then ran under `u:r:hal_lineage_livedisplay_qti:s0` with its four companions.
Stable AIDL V1 is not sufficient proof for private libbinder/libutils C++ ABI.
SDK 37 is therefore limited to the observed ROM build and stock HAL hash, or
the already installed known payload. SDK 36 retains semantic compatibility.
No Android-17-native source compilation was performed.

The trampoline was assembled with GNU AArch64 tools and exactly matched all
100 embedded bytes. Reversing the documented patch recreated the known
Android 16 reference hash `bcd4bebb44de0328c87b0b5bbbb10bb328edf8119fbe500e65aabd8937664b24`;
reapplying the repository's patch tool recreated the distributed payload byte
for byte. This verifies patch reproducibility, not a source-to-binary build.

## Reversible runtime test

The original HAL and persisted mode were copied first. A rollback trap and an
independent 90-second watchdog were created **before** replacing the visible
file. The replacement used a bind mount only; a reboot would also drop it.
Only the LiveDisplay service was restarted, never SurfaceFlinger/HWC.

The first staging attempt from `/data/local/tmp` was denied by SELinux
`nosuid_transition`/`execute_no_trans` and was rolled back. The second used a
suid-capable tmpfs in RAM with the original executable label. No SELinux policy
was changed; enforcing mode remained active.

| ID | HAL name | Verified panel QDCM | Verified seed |
| --- | --- | --- | --- |
| 0 | Vivid | zhal_native | 0 |
| 1 | Natural | SRGB | 1 |
| 2 | Cinematic | zhal_native | 1 |
| 3 | Brilliant | advance_p3 | 0 |
| 4 | Wide AMOLED Gamut | advance_native | 3 |

Each `setDisplayMode` returned success and `getCurrentDisplayMode` returned the
requested ID. All temporary calls used `makeDefault=false`; persisted mode
remained 0. SF's **framework** `ColorMode::SRGB (7)` remained distinct from the
Qualcomm **panel** `Current Color Mode: advance_native`. Conflating those dump
fields would incorrectly report failure or success.

Composer PID 1247 and SurfaceFlinger PID 1362 remained unchanged across the
five-profile test. The successful test had no observed HAL fatal/linker error
or new SELinux execution denial. Binder thread-pool warnings were present both
before and during testing. No unrelated existing ROM errors are claimed fixed.

After rollback, stock HAL hash, four-mode enumeration, persisted/current mode
0, seed 0 and SELinux Enforcing were verified. No temporary HAL bind mount
remained in init's mount namespace. No module was persistently installed.

A second successful temporary test persisted ID 4 (`makeDefault=true`), restarted
only LiveDisplay and verified both current/default ID 4 and seed 3. The final
`service.sh` confirmed `advance_native`/3 and started its monitor. Read-only
Action reported the state correctly. `disable.sh` persisted Natural and the
monitor stopped on the disable marker. Rollback then restored original persisted
and current ID 0 and the stock HAL. This is service-restart persistence, not a
full-device boot test.

The final installer was executed with KernelSU BusyBox in an isolated staging
directory outside the module slots, with real device properties/permissions.
It passed and created an independent HAL/mode backup. The initial staging run
caught an over-strict `Vivid` string check: this compiler embeds that name in
instructions, so the check was removed; runtime enumeration verifies the name.
Five host tests (including 12 installer acceptance/rejection scenarios),
ShellCheck 0.11.0 and Ruff passed. Rebuilding after changing source permissions
and timestamps produced identical ZIP bytes.

## Validation limits

- No reboot, cold boot, OTA, root-manager mount at boot, recovery or safe-mode
  recovery test. The standard `system/vendor` packaging is corrected but its
  Hybrid Mount/Magisk boot behavior still requires a controlled reboot test.
- No prolonged sleep/wake, HDR/FOD, anti-flicker interaction or battery test.
- No colorimeter measurement: QDCM/seed prove requested driver state, not the
  panel's measured gamut, calibration or color accuracy.
- Companion service registration was checked; each companion's complete
  functionality was not exercised. Other ROMs/SDK 37 builds are blocked.
- The ROM integration source patch remains the preferred fully source-built
  route. The packaged HAL is still a documented binary-patched Android 16 build.

## References

- [Project source and original provenance](../SOURCE.md)
- [LineageOS DisplayModes implementation](https://github.com/LineageOS/android_hardware_oplus/blob/lineage-23.2/aidl/livedisplay/DisplayModes.cpp)
- [AOSP stable AIDL](https://source.android.com/docs/core/architecture/aidl/stable-aidl)
- [Magisk module layout](https://topjohnwu.github.io/Magisk/guides.html)

## Real manager installation and RC2 correction

The subsequent authorized RC1 installation via KernelSU Next was rejected by
its dependency gate before activation. Logcat recorded that
`vendor.lineage.livedisplay-V1-ndk.so` could not be found. Unlike the earlier
isolated harness under `/data/local/tmp`, `/data/adb/modules_update` uses the
isolated **system** linker namespace. The ROM's `/linkerconfig/ld.config.txt`
explicitly assigns `/data/local/tests/vendor` to the **vendor** namespace.

The same payload was tested from private temporary directories in both
namespaces: system failed with the identical missing-library error; vendor
resolved all dependencies, including the V1 library, and retained the expected
SHA-256. RC2 performs the dependency check on an integrity-verified temporary
copy in the vendor test namespace and removes it afterward. It keeps all ROM,
SDK, architecture, page-size and hash gates; it changes no linker configuration,
LD_LIBRARY_PATH or SELinux policy. Errors are printed before installer cleanup.

The attempted permanent RC1 install was cleaned up by the manager. Original
HAL hash remained intact. RC2 requires a new installation; earlier RC1 installer
success referred only to the isolated harness, not the manager path.

## Publication status (1.2.0)

KernelSU Next reported successful permanent installation of RC2 and Hybrid Mount
created the expected `vendor -> ./system/vendor` link. The staged executable had
SHA-256 `277edf431056e91a8dbf69582b4dd788abe13958b9222deb21247254dcfeeb3f`, mode 0755,
owner root:shell and the expected LiveDisplay executable SELinux label. The
installer retained a separate pre-installation backup. At that point, before a
reboot, the stock HAL was still running as expected.

The maintainer subsequently confirmed that the module works and requested
publication. This is recorded as a maintainer report, not an independent
post-boot or long-duration test. Version 1.2.0 changes version/license metadata,
license packaging and publication documentation from RC2; it does not change
the HAL payload, profile mapping or compatibility contract. No private ADB logs,
device serial numbers or unrelated app/module inventory are published.
