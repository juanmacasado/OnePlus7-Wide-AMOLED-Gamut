#!/system/bin/sh
# SPDX-FileCopyrightText: 2026 juanmacasado
# SPDX-License-Identifier: GPL-3.0-or-later
MODDIR=${0%/*}
BIN="$MODDIR/system/vendor/bin/hw/vendor.lineage.livedisplay-service.oplus"
# No waiting, service restarts, partition writes or SELinux policy changes here.
{
  echo "[$(date '+%F %T')] post-fs-data"
  ls -lZ "$BIN"
  sha256sum "$BIN"
} >> "$MODDIR/display-modes.log" 2>&1
