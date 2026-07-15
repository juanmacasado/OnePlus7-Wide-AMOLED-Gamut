#!/system/bin/sh
# SPDX-FileCopyrightText: 2026 juanmacasado
# SPDX-License-Identifier: Apache-2.0
MODDIR=${0%/*}
BIN="$MODDIR/vendor/bin/hw/vendor.lineage.livedisplay-service.oplus"
LOG="$MODDIR/display-modes.log"

chmod 0755 "$BIN" 2>/dev/null
chown 0:2000 "$BIN" 2>/dev/null
chcon u:object_r:hal_lineage_livedisplay_qti_exec:s0 "$BIN" 2>/dev/null

{
  echo "[$(date '+%F %T')] post-fs-data"
  ls -lZ "$BIN" 2>/dev/null
  sha256sum "$BIN" 2>/dev/null
} >> "$LOG"
