#!/system/bin/sh
# SPDX-FileCopyrightText: 2026 juanmacasado
# SPDX-License-Identifier: GPL-3.0-or-later
# Shared constants are consumed by the scripts sourcing this file.
# shellcheck disable=SC2034
SERVICE=vendor.lineage.livedisplay.IDisplayModes/default
MODE_FILE=/data/vendor/display/default_display_mode
SEED_NODE=/sys/kernel/oplus_display/seed
BIN=/vendor/bin/hw/vendor.lineage.livedisplay-service.oplus
PAYLOAD_HASH=277edf431056e91a8dbf69582b4dd788abe13958b9222deb21247254dcfeeb3f

read_one_line() { tr -d '\r\n[:space:]' 2>/dev/null < "$1"; }
service_ready() { service check "$SERVICE" 2>/dev/null | grep -q ': found$'; }
expected_seed() {
  case "$1" in 0|3) echo 0 ;; 1|2) echo 1 ;; 4) echo 3 ;; *) return 1 ;; esac
}
expected_qdcm() {
  case "$1" in
    0|2) echo zhal_native ;; 1) echo SRGB ;;
    3) echo advance_p3 ;; 4) echo advance_native ;; *) return 1 ;;
  esac
}
read_qdcm() {
  # Match the Qualcomm HWC panel state, not SF's separate "Current color mode".
  dumpsys SurfaceFlinger 2>/dev/null |
    sed -n 's/^[[:space:]]*Current Color Mode:[[:space:]]*//p' |
    head -n 1 | tr -d '\r\n[:space:]'
}
call_mode() { service call "$SERVICE" 4 i32 "$1" i32 "$2" 2>&1; }
mode_succeeded() { printf '%s\n' "$1" | grep -Eq "Parcel\([[:space:]]*00000000[[:space:]]"; }
