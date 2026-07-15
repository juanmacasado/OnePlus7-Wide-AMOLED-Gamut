#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 juanmacasado
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE_PROP="$ROOT/module/module.prop"
OUT_DIR="$ROOT/out"

if ! command -v zip >/dev/null 2>&1; then
echo "Error: the 'zip' command is required." >&2
exit 1
fi

if [[ ! -f "$MODULE_PROP" ]]; then
echo "Error: module/module.prop was not found." >&2
exit 1
fi

VERSION="$(awk -F= '$1 == "version" { print $2 }' "$MODULE_PROP")"

if [[ -z "$VERSION" ]]; then
echo "Error: could not read the module version." >&2
exit 1
fi

NAME="OnePlus7-Wide-AMOLED-Gamut-LineageOS-v${VERSION}.zip"
OUTPUT="$OUT_DIR/$NAME"
STAGE="$(mktemp -d)"

cleanup() {
rm -rf "$STAGE"
}
trap cleanup EXIT

mkdir -p "$OUT_DIR"

cp -a "$ROOT/module/." "$STAGE/"
cp -a "$ROOT/prebuilt/vendor" "$STAGE/vendor"

cp "$ROOT/LICENSE" "$STAGE/"
cp "$ROOT/NOTICE" "$STAGE/"
cp "$ROOT/README.md" "$STAGE/"
cp "$ROOT/SOURCE.md" "$STAGE/"
cp "$ROOT/CHANGELOG.md" "$STAGE/"

rm -f "$OUTPUT" "$OUTPUT.sha256"

(
cd "$STAGE"
zip -qr9 "$OUTPUT" . -x "*.DS_Store" -x "__MACOSX/*"
)

(
    cd "$OUT_DIR"
    sha256sum "$NAME" > "$NAME.sha256"
)

echo "Built:"
echo "  $OUTPUT"
echo "  $OUTPUT.sha256"

