"""Verify castle artwork for Flutter builds without third-party Python packages.

Default mode accepts the existing SVG fallback while reporting missing WebP art.
Use --require-webp before publishing the premium castle edition.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
CASTLES = ROOT / "assets" / "castles"

def check() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--require-webp", action="store_true")
    args = parser.parse_args()

    errors: list[str] = []
    missing_webp: list[str] = []
    for i in range(1, 11):
        lo = (i - 1) * 5 + 1
        hi = i * 5
        name = f"castle_{i:02d}_lv{lo:02d}-{hi:02d}.webp"
        webp = CASTLES / name
        svg = CASTLES / f"castle_tier_{i:02d}.svg"
        if not svg.exists() or "<svg" not in svg.read_text(encoding="utf-8"):
            errors.append(f"missing SVG fallback: {svg.name}")
        if not webp.exists():
            missing_webp.append(name)
            continue
        raw = webp.read_bytes()
        if (len(raw) < 1024 or raw[:4] != b"RIFF" or
                raw[8:12] != b"WEBP" or
                int.from_bytes(raw[4:8], "little") + 8 != len(raw)):
            errors.append(f"invalid/truncated WebP: {name}")
    for err in errors:
        print("ERROR:", err, file=sys.stderr)
    if missing_webp:
        print(f"Premium WebP missing ({len(missing_webp)}/10):",
              ", ".join(missing_webp))
        if args.require_webp:
            errors.append("premium castle bundle incomplete")
        else:
            print("INFO: Existing bundled SVGs will be used instead.")
    else:
        print("OK: 10 premium WebP castle assets verified.")
    return 1 if errors else 0

if __name__ == "__main__":
    raise SystemExit(check())
