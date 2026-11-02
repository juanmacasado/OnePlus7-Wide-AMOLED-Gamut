# Portable Android 16/17 compatibility — 1.3.0-rc1

Audited 2026-11-03. Device scope remains **OnePlus 7 / guacamoleb / GM190x**;
OnePlus 7 Pro, 7T and other devices are not added by this release.

## Source comparison

LineageOS `lineage-24.0` and crDroid `17.0` have byte-identical
`DisplayModes.cpp`, `service.cpp` and `Android.bp` in the reviewed Oplus HAL.
Both OnePlus sm8150 common trees enable AntiFlicker and DisplayModes, while
PictureAdjustment and SunlightEnhancement remain enabled by default and
AdaptiveBacklight is disabled by default. Both use LiveDisplay's stable AIDL V1.
crDroid's Android 17 manifest inherits
`LineageOS/android_hardware_lineage_interfaces` from `lineage-24.0`.

The frozen V1 interface hash is
`1cf17f6e8d1bc4b3fe962ea0144d00e414201811`, also embedded in the original
Infinity-X HAL and the distributed five-profile payload. A ROM name or a hash
of the whole stock executable is not a portable ABI test: toolchain/build
changes can change the executable without changing this contract.

Reviewed source links (full commits are also in `compatibility-sources.json`):

- [LineageOS/android_hardware_oplus](https://github.com/LineageOS/android_hardware_oplus/blob/eaa32c03dc4efe177517e8293eaa43e9ffedb361/aidl/livedisplay/DisplayModes.cpp)
- [crdroidandroid/android_hardware_oplus](https://github.com/crdroidandroid/android_hardware_oplus/blob/2a8a5230ec006ada813c45ec7893140b0a0f043e/aidl/livedisplay/DisplayModes.cpp)
- [LineageOS/android_hardware_lineage_interfaces](https://github.com/LineageOS/android_hardware_lineage_interfaces/blob/68dca0c523594fb7c34e94782d0f21660530a2dc/livedisplay/aidl/Android.bp)
- [LineageOS/android_device_oneplus_sm8150-common](https://github.com/LineageOS/android_device_oneplus_sm8150-common/blob/21cb9a45801be6bd73c25e0e0e7d02dd75605965/common.mk)
- [crdroidandroid/android_device_oneplus_sm8150-common](https://github.com/crdroidandroid/android_device_oneplus_sm8150-common/blob/33cb3764334296b7ccc8bc52eb7e8842ec4c0a9c/common.mk)
- [crdroidandroid/android](https://github.com/crdroidandroid/android/blob/88b3209af69a52d852699509d4b395d966473514/snippets/lineage.xml)
- [LineageOS/android_bionic](https://github.com/LineageOS/android_bionic/blob/ff3bb041547924ac1a7504e4b3bd3ea18169ca2f/linker/linker_main.cpp)

## Installer contract, independent of ROM branding

1. Running Android, root, arm64, 4096-byte pages, OnePlus 7 identity, SDK 36 or 37.
2. Standard Oplus HAL signatures and `/dev/oplus_display` plus the readable seed node.
3. The framework advertises `org.lineageos.livedisplay`.
4. Exactly the four expected LiveDisplay interface instances are registered:
   IDisplayModes, IAntiFlicker, IPictureAdjustment and ISunlightEnhancement.
   Extra interfaces are rejected so replacing the complete service cannot
   silently remove an optional feature such as AdaptiveBacklight.
5. Every interface reports version 1 and the exact frozen V1 hash through the
   read-only stable AIDL introspection transactions.
6. `getDisplayModes` returns the standard IDs/names: 0 Vivid, 1 Natural,
   2 Cinematic and 3 Brilliant. A fifth profile is accepted only when upgrading
   the project's integrity-verified payload. Unknown/custom native maps abort.
7. The panel dump contains the QDCM pairs 0/zhal_native, 1/SRGB,
   2/advance_native and 4/advance_p3 in the same available-mode block.
8. The installed linker configuration explicitly assigns the private test
   directory to the vendor namespace. The unchanged payload passes integrity
   verification and `linker64 --list` in that namespace with inherited LD path
   overrides cleared for that command only.

Bionic's `--list` path links/relocates the executable and dependencies, then
exits before target constructors or service main run. This checks missing
libraries and unresolved imported symbols without starting another HAL. It does
not prove all private C++ semantics, firmware behavior or boot-manager behavior.

All service queries are getters; their timeouts are bounded. No test changes a
profile, stops a service, modifies partitions, adds SELinux rules or modifies
linker configuration. Successful installation keeps the independent backups
and normal root-manager system/vendor overlay used by 1.2.0.

The installer records the original visible HAL hash for diagnostics, not as a
ROM allowlist. LineageOS/crDroid/Infinity-X properties are informational only.
There is no "force", brand whitelist or bypass for a failed contract check.
A custom ROM sharing a LineageOS base can still fail a legitimate check.

## Validation matrix and limitations

| ROM / platform | Evidence | Current status |
| --- | --- | --- |
| Infinity-X 4.1 / Android 17 / GM1901 | Earlier ADB five-mode, seed, QDCM, persistence and disable tests; successful RC2 install; maintainer reports working | HAL validated on device; 1.3.0's additional getters/gates not rerun on device |
| LineageOS 24 / Android 17 | Oplus HAL and OnePlus 7 common source review above | Installer permits matching contract; real-device validation pending |
| crDroid Android 17 (`17.0`) | Same Oplus sources and relevant sm8150 flags; inherited stable interface | Installer permits matching contract; real-device validation pending |
| Other LineageOS-derived Android 17 ROMs | Same runtime contract required; no brand check | Detected compatibility only; real-device validation pending |
| Android 16 / SDK 36 | Previous release's device scope, plus the new contract gates | No new Android 16 device test |

The phone was disconnected during this change. No ROM was flashed, no new
module was installed and no LineageOS/crDroid boot test was performed. This is
therefore published as a **prerelease**, retaining 1.2.0 as the stable release.

Host regression tests exercise captured four/five-mode service replies,
malformed/custom/denied replies, frozen AIDL version/hash replies, differing
ROM names and HAL hashes, missing/extra services, features, panel modes and
loader failures. Mode-list fixtures are sanitized captures from the earlier
Infinity-X audit. Version/hash fixtures encode the frozen interface format;
those new live getter replies have not yet been captured on a device.

The HAL bytes and profile mapping remain unchanged. There is no new C++ HAL
build, new binary patch or expansion to other panel/device families. Long-term
HDR/FOD/sleep behavior, recovery and actual measured gamut retain the limitations
in `ANDROID17-VALIDATION.md`. Source review and installer acceptance do not make
untested ROMs equivalent to physically validated ones.

## Reporting a matching ROM

On a matching ROM, install the prerelease with a recovery route available and
retain the independently created backup. Report the ROM/build, device, installer
result, `compatibility.info`, post-boot Action output and whether all five modes
work after reboot and sleep/wake. Remove unrelated private log data before
sharing. A failed check should be investigated from its message; do not bypass it.
