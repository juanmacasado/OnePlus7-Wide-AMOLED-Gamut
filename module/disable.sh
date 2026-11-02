#!/system/bin/sh
# SPDX-FileCopyrightText: 2026 juanmacasado
# SPDX-License-Identifier: GPL-3.0-or-later
# Run as root before rebooting to the stock HAL; never unmount a live binary.
MODDIR=${0%/*}
# shellcheck source=module/common.sh
. "$MODDIR/common.sh"
RESULT=$(call_mode 1 1)
mode_succeeded "$RESULT" || { echo "Could not select Natural: $RESULT"; exit 1; }
[ "$(read_one_line "$MODE_FILE")" = 1 ] || { echo 'Natural was not persisted'; exit 1; }
touch "$MODDIR/disable" || exit 1
echo 'Natural persisted; module disabled for next boot. Reboot when ready.'
