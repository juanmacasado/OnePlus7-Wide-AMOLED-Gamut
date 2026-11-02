#!/system/bin/sh
# SPDX-FileCopyrightText: 2026 juanmacasado
# SPDX-License-Identifier: GPL-3.0-or-later
MODDIR=${0%/*}
# shellcheck source=module/common.sh
. "$MODDIR/common.sh"
LOG="$MODDIR/display-modes.log"
log_msg() {
  if [ -f "$LOG" ] && [ "$(wc -c < "$LOG")" -gt 131072 ]; then
    tail -c 65536 "$LOG" > "$LOG.tmp" && mv -f "$LOG.tmp" "$LOG"
  fi
  echo "[$(date '+%F %T')] $*" >> "$LOG"
}
WAIT=0
while [ "$WAIT" -lt 240 ]; do
  [ -e "$MODDIR/disable" ] && exit 0
  if [ "$(getprop sys.boot_completed)" = 1 ] && [ -r "$MODE_FILE" ] &&
     [ -r "$SEED_NODE" ] && service_ready; then break; fi
  sleep 2
  WAIT=$((WAIT + 2))
done
[ "$WAIT" -lt 240 ] || { log_msg 'HAL/boot timeout; no profile writes'; exit 1; }
HASH=$(sha256sum "$BIN" | awk '{print $1}')
[ "$HASH" = "$PAYLOAD_HASH" ] || { log_msg 'Replacement not mounted; no profile writes'; exit 1; }
# Bounded boot repair. An absent vendor dump field is unknown, never a match.
TRY=0
while [ "$TRY" -lt 3 ]; do
  MODE=$(read_one_line "$MODE_FILE")
  DESIRED_SEED=$(expected_seed "$MODE") || { log_msg "Invalid persisted mode: $MODE"; exit 1; }
  DESIRED_QDCM=$(expected_qdcm "$MODE")
  RESULT=$(call_mode "$MODE" 0)
  sleep 2
  SEED=$(read_one_line "$SEED_NODE")
  QDCM=$(read_qdcm)
  log_msg "boot mode=$MODE seed=$SEED/$DESIRED_SEED qdcm=${QDCM:-unknown}/$DESIRED_QDCM result=$RESULT"
  mode_succeeded "$RESULT" || { log_msg 'Binder failure; stopping'; exit 1; }
  [ "$SEED" = "$DESIRED_SEED" ] && [ "$QDCM" = "$DESIRED_QDCM" ] && break
  TRY=$((TRY + 1))
done
[ "$TRY" -lt 3 ] || { log_msg 'Profile verification failed; stopping'; exit 1; }
log_msg 'Profile monitor started'
FAILURES=0
while [ ! -e "$MODDIR/disable" ] && [ ! -e "$MODDIR/remove" ]; do
  MODE=$(read_one_line "$MODE_FILE")
  DESIRED_SEED=$(expected_seed "$MODE") || { log_msg 'Invalid mode; stopping'; exit 1; }
  SEED=$(read_one_line "$SEED_NODE")
  if [ "$SEED" != "$DESIRED_SEED" ]; then
    service_ready || { log_msg 'HAL disappeared; stopping'; exit 1; }
    RESULT=$(call_mode "$MODE" 0)
    sleep 1
    VERIFIED=$(read_one_line "$SEED_NODE")
    log_msg "repair mode=$MODE seed=$SEED->$VERIFIED expected=$DESIRED_SEED result=$RESULT"
    if mode_succeeded "$RESULT" && [ "$VERIFIED" = "$DESIRED_SEED" ]; then
      FAILURES=0
    else
      FAILURES=$((FAILURES + 1))
      [ "$FAILURES" -lt 3 ] || { log_msg 'Repeated repair failure; stopping'; exit 1; }
    fi
  fi
  sleep 5
done
# A normal disable while Android is running leaves a stock-compatible ID.
RESULT=$(call_mode 1 1)
log_msg "disable/remove: Natural requested; result=$RESULT"
