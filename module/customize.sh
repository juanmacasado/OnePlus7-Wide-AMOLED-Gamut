#!/system/bin/sh
# SPDX-FileCopyrightText: 2026 juanmacasado
# SPDX-License-Identifier: GPL-3.0-or-later
# Sourced by the root manager after extraction; Android must be running.
# shellcheck source=module/common.sh
. "$MODPATH/common.sh"
# shellcheck source=module/compatibility.sh
. "$MODPATH/compatibility.sh"
PAYLOAD="$MODPATH/system/vendor/bin/hw/vendor.lineage.livedisplay-service.oplus"
INFO="$MODPATH/compatibility.info"
ui_print 'OnePlus 7 Wide AMOLED Gamut 1.3.0-rc1'
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
[ -r "$SEED_NODE" ] || abort 'Oplus seed interface missing'
[ -e /dev/oplus_display ] || abort 'Oplus panel interface missing'
service_ready || abort 'LineageOS IDisplayModes is not accessible'
for NEEDLE in vendor.lineage.livedisplay-V1-ndk.so IDisplayModes /dev/oplus_display \
  "$MODE_FILE" DisplayModesService Natural Cinematic Brilliant \
  IAntiFlicker IPictureAdjustment ISunlightEnhancement; do
  grep -Fqa "$NEEDLE" "$BIN" || abort "Unexpected HAL; missing signature: $NEEDLE"
done
TARGET_HASH=$(sha256sum "$BIN" | awk '{print $1}')
ACTUAL_PAYLOAD_HASH=$(sha256sum "$PAYLOAD" | awk '{print $1}')
[ "$ACTUAL_PAYLOAD_HASH" = "$PAYLOAD_HASH" ] || abort 'Bundled HAL integrity check failed'
# Brand-neutral checks replace the old Infinity-X build/hash allowlist.
# The payload still has a fixed integrity hash; no unknown ROM is byte-patched.
timeout 10 pm list features 2>/dev/null | grep -Fqx 'feature:org.lineageos.livedisplay' ||
  abort 'The ROM does not advertise LineageOS LiveDisplay'
SERVICE_LIST=$(timeout 10 service list 2>/dev/null) || abort 'Could not enumerate services'
printf '%s\n' "$SERVICE_LIST" | standard_interface_set ||
  abort 'Unexpected LiveDisplay interface set; expected exactly DisplayModes/AntiFlicker/PictureAdjustment/SunlightEnhancement'
for INTERFACE in IDisplayModes IAntiFlicker IPictureAdjustment ISunlightEnhancement; do
  INSTANCE="vendor.lineage.livedisplay.$INTERFACE/default"
  interface_ready "$INSTANCE" || abort "Required service missing: $INSTANCE"
  [ "$(interface_version "$INSTANCE")" = 1 ] || abort "Unsupported AIDL version: $INSTANCE"
  [ "$(interface_hash "$INSTANCE")" = "$AIDL_V1_HASH" ] || abort "Unsupported AIDL contract: $INSTANCE"
done
ALLOW_FIVE=false
[ "$TARGET_HASH" != "$PAYLOAD_HASH" ] || ALLOW_FIVE=true
MODE_REPLY=$(timeout 10 service call "$SERVICE" 1 2>/dev/null) || abort 'Could not query display profiles'
MODE_COUNT=$(printf '%s\n' "$MODE_REPLY" | parse_parcel modes "$ALLOW_FIVE") ||
  abort 'Expected standard Vivid/Natural/Cinematic/Brilliant profiles; unfamiliar map rejected'
CURRENT_SEED=$(read_one_line "$SEED_NODE")
case "$CURRENT_SEED" in 0|1|3) ;; *) abort "Unexpected panel seed state: $CURRENT_SEED" ;; esac
timeout 15 dumpsys SurfaceFlinger 2>/dev/null | panel_contract ||
  abort 'Required Qualcomm QDCM modes (0,1,2,4) not found in panel diagnostics'
# Validate the test path namespace rather than accidentally testing system libs.
grep -Eq '^dir[.]vendor[[:space:]]*=[[:space:]]*/data/local/tests/vendor/?[[:space:]]*$' \
  /linkerconfig/ld.config.txt || abort 'Vendor linker test namespace is unavailable'
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
  if LD_LIBRARY_PATH='' LD_PRELOAD='' timeout 15 /system/bin/linker64 --list "$LINKER_CHECK/hal" > "$MODPATH/linker-check.txt" 2>&1; then
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
module_version=1.3.0-rc1
sdk=$SDK
release=$RELEASE
rom_display=$ROM_DISPLAY
infinity_version=$(getprop ro.infinity.version)
device=$DEVICE
model=$MODEL
original_visible_hal_sha256=$TARGET_HASH
replacement_hal_sha256=$PAYLOAD_HASH
backup=$BACKUP
compatibility=oplus-aidl-v1-runtime-contract
aidl_version=1
aidl_hash=$AIDL_V1_HASH
mode_count=$MODE_COUNT
qdcm_modes=0:zhal_native,1:SRGB,2:advance_native,4:advance_p3
lineage_version=$(getprop ro.lineage.version)
crdroid_version=$(getprop ro.crdroid.version)
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
ui_print '- ROM-independent contract checks passed; no ROM build/hash lock'
ui_print '- Physical validation: Infinity-X 4.1; other matching ROMs need device reports'
ui_print '- Read docs/PORTABLE-COMPATIBILITY.md and docs/RECOVERY.md before reboot'
