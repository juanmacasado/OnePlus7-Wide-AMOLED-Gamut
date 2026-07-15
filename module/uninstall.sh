#!/system/bin/sh
# SPDX-FileCopyrightText: 2026 juanmacasado
# SPDX-License-Identifier: Apache-2.0
# Leave a stock-compatible profile before the five-mode HAL is removed.
SERVICE="vendor.lineage.livedisplay.IDisplayModes/default"
service call "$SERVICE" 4 i32 1 i32 1 >/dev/null 2>&1
sleep 1
printf 1 > /data/vendor/display/default_display_mode 2>/dev/null
[ -e /sys/kernel/oplus_display/seed ] && printf 1 > /sys/kernel/oplus_display/seed 2>/dev/null
