#!/usr/bin/env python3
"""Patch the exact Infinity-X 2026-06-15 guacamoleb Oplus LiveDisplay HAL.

Builds the five-mode HAL from a compatible reference binary.
The output preserves stock mode 3 (Brilliant -> QDCM 4 / seed 0) and injects
mode 4 (Wide AMOLED Gamut -> QDCM 2 / seed 3).

The 100-byte AArch64 trampoline must be assembled from five_mode_trampoline.S
and linked at virtual address 0x9f00 before running this script.
"""

from __future__ import annotations

import argparse
import hashlib
import struct
from pathlib import Path

STOCK_SHA256 = "bcd4bebb44de0328c87b0b5bbbb10bb328edf8119fbe500e65aabd8937664b24"
V15_SHA256 = "bcdeebfad35daa9d6600a20ceac0679e2d262b9a7a10ccf24d9cef7aa82b8488"
OUTPUT_SHA256 = "277edf431056e91a8dbf69582b4dd788abe13958b9222deb21247254dcfeeb3f"


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("trampoline", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    image = bytearray(args.input.read_bytes())
    source_hash = sha256(image)
    if source_hash not in {STOCK_SHA256, V15_SHA256}:
        raise SystemExit(f"unsupported input SHA-256: {source_hash}")

    trampoline = args.trampoline.read_bytes()
    if len(trampoline) != 100:
        raise SystemExit(f"trampoline must be exactly 100 bytes, got {len(trampoline)}")

    # Restore stock Brilliant: mov w8, #4 at file/VA 0x8870.
    image[0x8870:0x8874] = bytes.fromhex("88008052")

    # Branch from the static map initializer to 0x9f00.
    image[0x88C8:0x88CC] = struct.pack("<I", 0x1400058E)

    # The exact binary has zero padding from 0x9f00 to 0xa000.
    cave = image[0x9F00:0x9F00 + len(trampoline)]
    if any(cave):
        raise SystemExit("expected executable padding at 0x9f00 is not empty")
    image[0x9F00:0x9F00 + len(trampoline)] = trampoline

    # Extend executable PT_LOAD entry #3 from [0x5000,0x9f00) to 0xa000.
    phoff = struct.unpack_from("<Q", image, 0x20)[0]
    phentsize = struct.unpack_from("<H", image, 0x36)[0]
    ph = phoff + 3 * phentsize
    if struct.unpack_from("<I", image, ph)[0] != 1:
        raise SystemExit("program header #3 is not PT_LOAD")
    if not (struct.unpack_from("<I", image, ph + 4)[0] & 1):
        raise SystemExit("program header #3 is not executable")
    struct.pack_into("<Q", image, ph + 32, 0x5000)
    struct.pack_into("<Q", image, ph + 40, 0x5000)

    result = bytes(image)
    result_hash = sha256(result)
    if result_hash != OUTPUT_SHA256:
        raise SystemExit(f"unexpected output SHA-256: {result_hash}")
    args.output.write_bytes(result)
    print(f"wrote {args.output} ({result_hash})")


if __name__ == "__main__":
    main()
