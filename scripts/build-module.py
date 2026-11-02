#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 juanmacasado
# SPDX-License-Identifier: GPL-3.0-or-later
"""Deterministic, uncompressed ZIP: no timestamp, umask or zlib dependency."""
import argparse
import hashlib
import os
import stat
import time
import zipfile
from pathlib import Path


def main():
    root = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out-dir", type=Path, default=root / "out")
    args = parser.parse_args()
    props = dict(line.split("=", 1) for line in
                 (root / "module/module.prop").read_text().splitlines() if "=" in line)
    epoch = int(os.environ.get("SOURCE_DATE_EPOCH", "315532800"))
    if not 315532800 <= epoch <= 4354819198:
        raise SystemExit("SOURCE_DATE_EPOCH must fit the ZIP date range (1980-2107)")
    stamp = time.gmtime(epoch)[:6]
    files = {p.relative_to(root / "module").as_posix(): p
             for p in (root / "module").rglob("*") if p.is_file()}
    for p in (root / "prebuilt/vendor").rglob("*"):
        if p.is_file():
            files["system/" + p.relative_to(root / "prebuilt").as_posix()] = p
    for name in ("LICENSE", "NOTICE", "README.md", "SOURCE.md", "CHANGELOG.md", "LICENSING.md"):
        files[name] = root / name
    for p in (root / "LICENSES").glob("*.txt"):
        files[p.relative_to(root).as_posix()] = p
    for p in (root / "docs").rglob("*"):
        if p.is_file():
            files[p.relative_to(root).as_posix()] = p
    args.out_dir.mkdir(parents=True, exist_ok=True)
    output = args.out_dir / f"OnePlus7-Wide-AMOLED-Gamut-LineageOS-v{props['version']}.zip"
    temporary = output.with_suffix(".zip.tmp")
    try:
        with zipfile.ZipFile(temporary, "w", compression=zipfile.ZIP_STORED) as archive:
            for name, path in sorted(files.items()):
                if path.is_symlink():
                    raise SystemExit(f"Refusing symlink: {path}")
                info = zipfile.ZipInfo(name, stamp)
                info.create_system = 3
                mode = 0o755 if name.endswith(".sh") or "/bin/" in name else 0o644
                info.external_attr = (stat.S_IFREG | mode) << 16
                archive.writestr(info, path.read_bytes())
        temporary.replace(output)
    finally:
        temporary.unlink(missing_ok=True)
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    output.with_suffix(".zip.sha256").write_text(f"{digest}  {output.name}\n")
    print(f"{digest}  {output}")


if __name__ == "__main__":
    main()
