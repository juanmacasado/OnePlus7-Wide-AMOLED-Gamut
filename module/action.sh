#!/system/bin/sh
# SPDX-FileCopyrightText: 2026 juanmacasado
# SPDX-License-Identifier: GPL-3.0-or-later
MODDIR=${0%/*}
# shellcheck source=module/common.sh
. "$MODDIR/common.sh"
MODE=$(read_one_line "$MODE_FILE")
SEED=$(read_one_line "$SEED_NODE")
QDCM=$(read_qdcm)
echo "OnePlus 7 Wide AMOLED Gamut — diagnostics (read only)"
echo "ROM: $(getprop ro.build.display.id)"
echo "Android: $(getprop ro.build.version.release) / SDK $(getprop ro.build.version.sdk)"
echo "Device: $(getprop ro.product.device) / $(getprop ro.product.model)"
echo "Persisted mode: ${MODE:-unknown}"
echo "Seed: ${SEED:-unknown} (expected $(expected_seed "$MODE"))"
echo "Panel QDCM: ${QDCM:-unknown} (expected $(expected_qdcm "$MODE"))"
echo "Visible HAL: $(sha256sum "$BIN")"
echo "Service: $(service check "$SERVICE" 2>&1)"
service call "$SERVICE" 2
[ ! -f "$MODDIR/compatibility.info" ] || cat "$MODDIR/compatibility.info"
exit 0
