#!/system/bin/sh
# OnePlus 7 Wide AMOLED Gamut - portable LineageOS edition
# 0 Vivid              -> QDCM zhal_native    / seed 0
# 1 Natural            -> QDCM SRGB           / seed 1
# 2 Cinematic / P3     -> QDCM zhal_native    / seed 1
# 3 Brilliant          -> QDCM advance_p3     / seed 0
# 4 Wide AMOLED Gamut  -> QDCM advance_native / seed 3

MODDIR=${0%/*}
LOG="$MODDIR/display-modes.log"
SERVICE="vendor.lineage.livedisplay.IDisplayModes/default"
MODE_FILE="/data/vendor/display/default_display_mode"
SEED_NODE="/sys/kernel/oplus_display/seed"

log_msg() {
  echo "[$(date '+%F %T')] $*" >> "$LOG"
}

read_one_line() {
  cat "$1" 2>/dev/null | tr -d '\r\n[:space:]'
}

expected_seed() {
  case "$1" in
    0) echo 0 ;;
    1) echo 1 ;;
    2) echo 1 ;;
    3) echo 0 ;;
    4) echo 3 ;;
    *) echo "" ;;
  esac
}

expected_qdcm() {
  case "$1" in
    0) echo zhal_native ;;
    1) echo SRGB ;;
    2) echo zhal_native ;;
    3) echo advance_p3 ;;
    4) echo advance_native ;;
    *) echo "" ;;
  esac
}

read_qdcm() {
  dumpsys SurfaceFlinger 2>/dev/null |
    sed -n 's/.*Current Color Mode:[[:space:]]*//p' |
    tail -n 1 |
    tr -d '\r\n[:space:]'
}

call_mode() {
  service call "$SERVICE" 4 i32 "$1" i32 "$2" 2>&1
}

# Keep the diagnostic log bounded.
if [ -f "$LOG" ]; then
  SIZE="$(wc -c < "$LOG" 2>/dev/null)"
  [ -n "$SIZE" ] || SIZE=0
  if [ "$SIZE" -gt 131072 ]; then
    tail -c 65536 "$LOG" > "$LOG.tmp" 2>/dev/null
    mv -f "$LOG.tmp" "$LOG" 2>/dev/null
  fi
fi

WAIT=0
while true; do
  if [ -e "$SEED_NODE" ] && [ -r "$MODE_FILE" ] && \
     service check "$SERVICE" 2>/dev/null | grep -q found; then
    break
  fi
  sleep 1
  WAIT=$((WAIT + 1))
  [ "$WAIT" -eq 180 ] && log_msg "still waiting for HAL, mode file or seed node"
done

# Wait until Android is fully operational.
BOOT_WAIT=0
while [ "$(getprop sys.boot_completed 2>/dev/null)" != "1" ]; do
  sleep 1
  BOOT_WAIT=$((BOOT_WAIT + 1))
  [ "$BOOT_WAIT" -ge 240 ] && break
done
sleep 3

# Reapply the persisted profile after boot. The display stack can initialize
# with the correct seed but the wrong QDCM mode, so both values are verified.
BOOT_TRY=1
while [ "$BOOT_TRY" -le 12 ]; do
  MODE="$(read_one_line "$MODE_FILE")"
  DESIRED_SEED="$(expected_seed "$MODE")"
  DESIRED_QDCM="$(expected_qdcm "$MODE")"
  [ -n "$DESIRED_SEED" ] || break

  RESULT="$(call_mode "$MODE" 0)"
  sleep 2
  CURRENT_SEED="$(read_one_line "$SEED_NODE")"
  CURRENT_QDCM="$(read_qdcm)"
  log_msg "boot reapply try=$BOOT_TRY mode=$MODE seed=$CURRENT_SEED/$DESIRED_SEED qdcm=$CURRENT_QDCM/$DESIRED_QDCM result=$RESULT"

  if [ "$CURRENT_SEED" = "$DESIRED_SEED" ] && [ "$CURRENT_QDCM" = "$DESIRED_QDCM" ]; then
    break
  fi

  BOOT_TRY=$((BOOT_TRY + 1))
  sleep 2
done

log_msg "five-mode monitor started"
LAST_MODE=""
LAST_SEED=""

while true; do
  MODE="$(read_one_line "$MODE_FILE")"
  DESIRED="$(expected_seed "$MODE")"
  [ -n "$DESIRED" ] || { sleep 2; continue; }

  CURRENT="$(read_one_line "$SEED_NODE")"
  if [ "$CURRENT" != "$DESIRED" ]; then
    RESULT="$(call_mode "$MODE" 0)"
    sleep 1
    VERIFIED="$(read_one_line "$SEED_NODE")"
    log_msg "mode=$MODE seed $CURRENT -> $VERIFIED desired=$DESIRED result=$RESULT"
  elif [ "$MODE" != "$LAST_MODE" ] || [ "$CURRENT" != "$LAST_SEED" ]; then
    log_msg "mode=$MODE seed=$CURRENT correct"
  fi

  LAST_MODE="$MODE"
  LAST_SEED="$CURRENT"
  sleep 2
done
