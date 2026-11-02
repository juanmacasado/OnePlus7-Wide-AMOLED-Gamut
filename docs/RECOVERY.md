# Installation and recovery for 1.2.0

The HAL was tested through a temporary mount, with stock restored afterward.
The corrected RC2 was subsequently installed through KernelSU Next / Hybrid Mount
and the maintainer reported that it works. A separate post-install boot audit
and recovery test were not captured. Keep the original ZIP and the ROM's
recovery/firmware available. Do not assume a bootloop is impossible.

## Before installation

1. Keep the SHA-256-verified original 1.1.1.1 ZIP outside the phone as well.
2. Install the ZIP in the running KernelSU/Magisk manager. Recovery installs
   are rejected. KernelSU needs a working mount-capable metamodule.
3. Read the compatibility result and backup path. The installer saves the
   visible HAL, mode file, metadata and any previously installed module tar to
   `/data/adb/oneplus7-gamut-backups/<UTC-time>-<pid>/`, outside both module slots.
   A visible HAL may already be a module overlay; it is not claimed to be stock.
4. Copy that backup to the computer before reboot. Never restore a vendor HAL
   by blindly writing it to the physical vendor partition.

The installer performs no service restarts or partition writes. The manager
activates `system/vendor/bin/hw/vendor.lineage.livedisplay-service.oplus` at
reboot. Successful installer checks alone do not prove boot compatibility.

## Disable safely while Android is running

Run as root:

```sh
sh /data/adb/modules/oneplus7_extended_display_modes/disable.sh
```

This persists Natural (ID 1), confirms the mode file, and creates the module's
`disable` marker. Reboot when ready. Using this helper avoids handing persisted
mode ID 4 to the stock four-mode HAL. The normal service monitor also tries to
select Natural when it sees a disable/remove marker; do not rely on that race
when rebooting immediately. Uninstall also normalizes the persisted ID.

## If Android will not start normally

Use the root manager's documented safe mode / module-disable recovery procedure.
If recovery or a root-capable ADB session can access decrypted `/data`, run:

```sh
touch /data/adb/modules/oneplus7_extended_display_modes/disable
# Also disable a pending update, if its directory exists:
[ ! -d /data/adb/modules_update/oneplus7_extended_display_modes ] ||
  touch /data/adb/modules_update/oneplus7_extended_display_modes/disable
# Normalize a potentially persisted fifth profile, preserving file context:
[ ! -f /data/vendor/display/default_display_mode ] ||
  printf 1 > /data/vendor/display/default_display_mode
```

These paths require actual root and decrypted data; ordinary ADB shell cannot
access them. Reboot after disabling. These recovery paths were documented, not
exercised during this audit. A raw `adb shell su` recovery route is unavailable
once the temporary Shell root grant has been removed unless you grant it again.

To return to an older module, disable this version and boot stock first, then reinstall
the retained older ZIP **only on an Android version it supports**. The original
1.1.1.1 installer rejects Android 17; a backup is not permission to bypass that
check. Retain independent backups until the new version has been boot-tested.
