#!/system/bin/sh

PAYLOAD_HASH="277edf431056e91a8dbf69582b4dd788abe13958b9222deb21247254dcfeeb3f"
TARGET="/vendor/bin/hw/vendor.lineage.livedisplay-service.oplus"
PAYLOAD="$MODPATH/vendor/bin/hw/vendor.lineage.livedisplay-service.oplus"
SERVICE="vendor.lineage.livedisplay.IDisplayModes/default"
MODE_FILE="/data/vendor/display/default_display_mode"
SEED_NODE="/sys/kernel/oplus_display/seed"
INFO="$MODPATH/compatibility.info"

ui_print "*********************************************"
ui_print " OnePlus 7 Wide AMOLED Gamut 1.1.0"
ui_print " Portable LineageOS edition"
ui_print "*********************************************"
ui_print "Author: juanmacasado"
ui_print "Adds a fifth native mode directly to LiveDisplay"
ui_print "No companion APK is installed"

DEVICE="$(getprop ro.product.device)"
VENDOR_DEVICE="$(getprop ro.product.vendor.device)"
PRODUCT_DEVICE="$(getprop ro.product.product.device)"
BUILD_PRODUCT="$(getprop ro.build.product)"
PRODUCT_NAME="$(getprop ro.product.name)"
MODEL="$(getprop ro.product.model)"
SDK="$(getprop ro.build.version.sdk)"
RELEASE="$(getprop ro.build.version.release)"
FINGERPRINT="$(getprop ro.build.fingerprint)"
ROM_DISPLAY="$(getprop ro.build.display.id)"
DEVICE_INFO="$DEVICE $VENDOR_DEVICE $PRODUCT_DEVICE $BUILD_PRODUCT $PRODUCT_NAME $MODEL"
DEVICE_INFO_LC="$(printf '%s' "$DEVICE_INFO" | tr '[:upper:]' '[:lower:]')"

case "$DEVICE_INFO_LC" in
  *guacamoleb*|*oneplus7*|*gm190*) ;;
  *)
    ui_print "Detected identity: $DEVICE / $VENDOR_DEVICE / $PRODUCT_DEVICE"
    ui_print "Build/product/model: $BUILD_PRODUCT / $PRODUCT_NAME / $MODEL"
    abort "Unsupported device. This module is only for the OnePlus 7."
    ;;
esac

# The distributed HAL is built for the current AIDL-based LiveDisplay stack.
# This prebuilt targets Android 16 / SDK 36. Portability here means across
# compatible LineageOS-derived ROM builds, not across Android generations.
case "$SDK" in
  36) ;;
  *) abort "Unsupported Android SDK $SDK. This portable release targets Android 16." ;;
esac

[ -f "$TARGET" ] || abort "Oplus LiveDisplay HAL not found: $TARGET"
[ -f "$PAYLOAD" ] || abort "Bundled five-mode HAL is missing"
[ -e "$SEED_NODE" ] || abort "Oplus seed node not found. OxygenOS 12 display firmware/kernel support is required."
[ -e /dev/oplus_display ] || abort "/dev/oplus_display is missing. The required Oplus panel interface is unavailable."

if ! service check "$SERVICE" 2>/dev/null | grep -q found; then
  abort "The LineageOS IDisplayModes service is not available on this ROM."
fi

# Semantic compatibility gate.
# restriction: ROMs may compile the same upstream HAL to different bytes.
# We accept only the standard Oplus AIDL LiveDisplay family with the original
# four profile names and required stable dependencies/interfaces.
for NEEDLE in \
  "vendor.lineage.livedisplay-V1-ndk.so" \
  "IDisplayModes" \
  "/dev/oplus_display" \
  "/data/vendor/display/default_display_mode" \
  "DisplayModesService" "Natural" "Cinematic" "Brilliant"; do
  if ! grep -Fqa "$NEEDLE" "$TARGET" 2>/dev/null; then
    ui_print "Missing expected HAL signature: $NEEDLE"
    abort "This ROM does not use the compatible standard Oplus LiveDisplay HAL."
  fi
done

# The replacement preserves the complete OnePlus 7 service feature set.
# Matching these interfaces avoids replacing a substantially different HAL.
for NEEDLE in \
  "IAntiFlicker" \
  "IPictureAdjustment" \
  "ISunlightEnhancement"; do
  if ! grep -Fqa "$NEEDLE" "$TARGET" 2>/dev/null; then
    ui_print "Missing expected companion interface: $NEEDLE"
    abort "The ROM's LiveDisplay service feature set differs from the supported OnePlus 7 stack."
  fi
done

TARGET_HASH="$(sha256sum "$TARGET" 2>/dev/null | awk '{print $1}')"
ACTUAL_PAYLOAD_HASH="$(sha256sum "$PAYLOAD" 2>/dev/null | awk '{print $1}')"
[ "$ACTUAL_PAYLOAD_HASH" = "$PAYLOAD_HASH" ] || abort "Bundled HAL failed integrity verification"

ui_print "- Device: $MODEL ($DEVICE)"
ui_print "- Android: $RELEASE / SDK $SDK"
ui_print "- Standard Oplus AIDL LiveDisplay detected"
ui_print "- Current HAL SHA-256: $TARGET_HASH"
ui_print "- Binary hash is informational, not a ROM lock"

cat > "$INFO" <<INFOEOF
module=OnePlus 7 Wide AMOLED Gamut 1.1.0
installation_mode=portable-semantic-compatibility
rom_display=$ROM_DISPLAY
fingerprint=$FINGERPRINT
sdk=$SDK
release=$RELEASE
device=$DEVICE
vendor_device=$VENDOR_DEVICE
model=$MODEL
original_visible_hal_sha256=$TARGET_HASH
replacement_hal_sha256=$PAYLOAD_HASH
service=$SERVICE
INFOEOF

rm -rf "$MODPATH/system" "$MODPATH/system_ext" "$MODPATH/payload" "$MODPATH/tools"
rm -f "$MODPATH/sepolicy.rule"

set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$PAYLOAD" 0 2000 0755 u:object_r:hal_lineage_livedisplay_qti_exec:s0
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755

ui_print "- Portable compatibility checks passed"
ui_print "- Five-mode HAL verified: $PAYLOAD_HASH"
ui_print "- Select all five profiles directly in LiveDisplay"
ui_print "- Reboot required"
