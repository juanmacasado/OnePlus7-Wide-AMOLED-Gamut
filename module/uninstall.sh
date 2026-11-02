#!/system/bin/sh
# SPDX-FileCopyrightText: 2026 juanmacasado
# SPDX-License-Identifier: GPL-3.0-or-later
MODDIR=${0%/*}
# shellcheck source=module/common.sh
. "$MODDIR/common.sh"
# Never leave ID 4 for the stock four-mode HAL. Keep the file's inode/context.
RESULT=$(call_mode 1 1)
if ! mode_succeeded "$RESULT" || [ "$(read_one_line "$MODE_FILE")" != 1 ]; then
  printf 1 > "$MODE_FILE" 2>/dev/null
fi
# No raw sysfs writes or partition changes. Backups intentionally remain.
