#!/system/bin/sh
SERVICE="vendor.lineage.livedisplay.IDisplayModes/default"
MODE_FILE="/data/vendor/display/default_display_mode"
SEED_NODE="/sys/kernel/oplus_display/seed"
BIN="/vendor/bin/hw/vendor.lineage.livedisplay-service.oplus"
MODDIR=${0%/*}

MODE="$(cat "$MODE_FILE" 2>/dev/null | tr -d '\r\n[:space:]')"
SEED="$(cat "$SEED_NODE" 2>/dev/null | tr -d '\r\n[:space:]')"
HASH="$(sha256sum "$BIN" 2>/dev/null | awk '{print $1}')"
QDCM="$(dumpsys SurfaceFlinger 2>/dev/null | sed -n 's/.*Current Color Mode:[[:space:]]*//p' | tail -n 1 | tr -d '\r\n[:space:]')"

case "$MODE" in
  0) NAME="Vivid"; EXPECTED_SEED=0; EXPECTED_QDCM="zhal_native" ;;
  1) NAME="Natural"; EXPECTED_SEED=1; EXPECTED_QDCM="SRGB" ;;
  2) NAME="Cinematic / P3"; EXPECTED_SEED=1; EXPECTED_QDCM="zhal_native" ;;
  3) NAME="Brilliant"; EXPECTED_SEED=0; EXPECTED_QDCM="advance_p3" ;;
  4) NAME="Wide AMOLED Gamut"; EXPECTED_SEED=3; EXPECTED_QDCM="advance_native" ;;
  *) NAME="Unknown"; EXPECTED_SEED="?"; EXPECTED_QDCM="?" ;;
esac

echo "OnePlus 7 Wide AMOLED Gamut (LineageOS portable)"
echo "ROM: $(getprop ro.build.display.id)"
echo "Device: $(getprop ro.product.device) / $(getprop ro.product.model)"
echo "Android: $(getprop ro.build.version.release) (SDK $(getprop ro.build.version.sdk))"
echo "Mode: ${MODE:-unavailable} (${NAME})"
echo "Seed: ${SEED:-unavailable} (expected ${EXPECTED_SEED})"
echo "QDCM: ${QDCM:-unavailable} (expected ${EXPECTED_QDCM})"
echo "Mounted HAL SHA-256: ${HASH:-unavailable}"
echo "Service: $(service check "$SERVICE" 2>&1)"
[ -f "$MODDIR/compatibility.info" ] && { echo; echo "Installation record:"; cat "$MODDIR/compatibility.info"; }

if [ -n "$MODE" ] && [ "$MODE" -ge 0 ] 2>/dev/null && [ "$MODE" -le 4 ] 2>/dev/null; then
  echo "Reapplying the persisted profile..."
  service call "$SERVICE" 4 i32 "$MODE" i32 0
fi
