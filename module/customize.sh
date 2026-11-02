#!/system/bin/sh
# SPDX-FileCopyrightText: 2026 juanmacasado
# SPDX-License-Identifier: GPL-3.0-or-later
# Sourced by the root manager after extraction; Android must be running.
# shellcheck source=module/common.sh
. "$MODPATH/common.sh"
PAYLOAD="$MODPATH/system/vendor/bin/hw/vendor.lineage.livedisplay-service.oplus"
INFO="$MODPATH/compatibility.info"
ANDROID17_STOCK_HASH=e560a2af35908d40e6f564f2f72bb315ddd3bd3cc3da13fca49c2bcdc3ce40e5
ui_print 'OnePlus 7 Wide AMOLED Gamut 1.2.0'
[ "${BOOTMODE:-false}" = true ] || abort 'Install from the root manager in running Android; recovery is not supported.'
[ "$(id -u)" = 0 ] || abort 'Root is required.'
[ "${ARCH:-}" = arm64 ] || abort 'Only arm64 is supported.'
[ "$(getconf PAGESIZE)" = 4096 ] || abort 'This HAL requires a 4 KiB page-size device.'

DEVICE=$(getprop ro.product.device)
VENDOR_DEVICE=$(getprop ro.product.vendor.device)
MODEL=$(getprop ro.product.model)
SDK=$(getprop ro.build.version.sdk)
RELEASE=$(getprop ro.build.version.release)
ROM_DISPLAY=$(getprop ro.build.display.id)
DEVICE_OK=false
for IDENTITY in "$DEVICE" "$VENDOR_DEVICE" "$MODEL" "$(getprop ro.infinity.device)"; do
  IDENTITY=$(printf '%s' "$IDENTITY" | tr '[:upper:]' '[:lower:]')
  case "$IDENTITY" in guacamoleb|oneplus7|gm190[0-9]) DEVICE_OK=true ;; esac
done
[ "$DEVICE_OK" = true ] || abort "Unsupported device: $DEVICE / $VENDOR_DEVICE / $MODEL"
case "$SDK" in 36|37) ;; *) abort "Unsupported SDK: $SDK (only 36/37)" ;; esac
[ -f "$BIN" ] || abort "Oplus LiveDisplay HAL missing: $BIN"
[ -f "$PAYLOAD" ] || abort 'Bundled five-mode HAL missing'
[ -r "$SEED_NODE" ] && [ -e /dev/oplus_display ] || abort 'Oplus panel interface missing'
service_ready || abort 'LineageOS IDisplayModes is not accessible'
for NEEDLE in vendor.lineage.livedisplay-V1-ndk.so IDisplayModes /dev/oplus_display \
  "$MODE_FILE" DisplayModesService Natural Cinematic Brilliant \
  IAntiFlicker IPictureAdjustment ISunlightEnhancement; do
  grep -Fqa "$NEEDLE" "$BIN" || abort "Unexpected HAL; missing signature: $NEEDLE"
done
TARGET_HASH=$(sha256sum "$BIN" | awk '{print $1}')
ACTUAL_PAYLOAD_HASH=$(sha256sum "$PAYLOAD" | awk '{print $1}')
[ "$ACTUAL_PAYLOAD_HASH" = "$PAYLOAD_HASH" ] || abort 'Bundled HAL integrity check failed'
if [ "$SDK" = 37 ] && [ "$(getprop ro.infinity.build.version)" != \
   Project_Infinity-X-4.1-guacamoleb-02.11.2026 ]; then
  abort 'Android 17 support is scoped to the audited Infinity-X 4.1 build (2026-11-02)'
fi
# AIDL V1 alone does not guarantee private libbinder/libutils C++ ABI stability.
# SDK 37 is admitted only for the observed ROM HAL or an existing payload.
if [ "$SDK" = 37 ] && [ "$TARGET_HASH" != "$ANDROID17_STOCK_HASH" ] &&
   [ "$TARGET_HASH" != "$PAYLOAD_HASH" ]; then
  abort "Android 17 HAL has not been audited: $TARGET_HASH"
fi
# /data/adb is assigned the system linker namespace on this ROM. A vendor
# executable must be checked in a vendor test directory, which uses the same
# namespace as /vendor/bin. Do not change global linker config or LD_* variables.
LINKER_ROOT=/data/local/tests/vendor
mkdir -p "$LINKER_ROOT" || abort 'Could not create vendor linker test directory'
LINKER_CHECK=$(mktemp -d "$LINKER_ROOT/oneplus7-gamut.XXXXXX") ||
  abort 'Could not create private vendor linker staging directory'
LINKER_OK=false
if cp "$PAYLOAD" "$LINKER_CHECK/hal" && chmod 0755 "$LINKER_CHECK/hal" &&
   [ "$(sha256sum "$LINKER_CHECK/hal" | awk '{print $1}')" = "$PAYLOAD_HASH" ]; then
  if /system/bin/linker64 --list "$LINKER_CHECK/hal" > "$MODPATH/linker-check.txt" 2>&1; then
    LINKER_OK=true
  fi
fi
rm -f "$LINKER_CHECK/hal"
rmdir "$LINKER_CHECK"
if [ "$LINKER_OK" != true ]; then
  if [ -f "$MODPATH/linker-check.txt" ]; then
    while IFS= read -r LINE; do ui_print "$LINE"; done < "$MODPATH/linker-check.txt"
  fi
  abort 'HAL dependency resolution failed in vendor namespace'
fi
# No destructive upgrade: keep independent backups outside both module slots.
BACKUP_ROOT=/data/adb/oneplus7-gamut-backups
BACKUP="$BACKUP_ROOT/$(date -u '+%Y%m%dT%H%M%SZ')-$$"
(umask 077; mkdir -p "$BACKUP") || abort 'Could not create backup directory'
chmod 0700 "$BACKUP_ROOT" "$BACKUP"
cp -p "$BIN" "$BACKUP/visible-hal" || abort 'HAL backup failed'
if [ -f "$MODE_FILE" ]; then
  cp -p "$MODE_FILE" "$BACKUP/default_display_mode" || abort 'Mode backup failed'
fi
OLD=/data/adb/modules/oneplus7_extended_display_modes
if [ -d "$OLD" ]; then
  tar -cf "$BACKUP/previous-module.tar" -C "$OLD" . || abort 'Previous module backup failed'
fi
cat > "$INFO" <<INFOEOF
module_version=1.2.0
sdk=$SDK
release=$RELEASE
rom_display=$ROM_DISPLAY
infinity_version=$(getprop ro.infinity.version)
device=$DEVICE
model=$MODEL
original_visible_hal_sha256=$TARGET_HASH
replacement_hal_sha256=$PAYLOAD_HASH
backup=$BACKUP
android17_scope=audited-hal-only
INFOEOF
cp "$INFO" "$BACKUP/compatibility.info" || abort 'Backup metadata failed'
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$PAYLOAD" 0 2000 0755 u:object_r:hal_lineage_livedisplay_qti_exec:s0
for SCRIPT in post-fs-data.sh service.sh action.sh uninstall.sh disable.sh; do
  set_perm "$MODPATH/$SCRIPT" 0 0 0755
done
ui_print "- Android $RELEASE / SDK $SDK; HAL checks passed"
ui_print "- Backup: $BACKUP"
ui_print '- system/vendor overlay prepared; physical vendor is unchanged'
ui_print '- Runtime verified on Infinity-X 4.1; maintainer reports working after installation'
ui_print '- Read docs/ANDROID17-VALIDATION.md and docs/RECOVERY.md before reboot'
