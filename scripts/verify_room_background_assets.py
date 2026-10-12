#!/usr/bin/env python3
"""Prevent distributing paid room backgrounds whose image assets are missing."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parent.parent
FOLDER = ROOT / "assets" / "backgrounds"
MANIFEST = FOLDER / "premium_backgrounds_manifest.json"


def main() -> int:
    catalog = json.loads(MANIFEST.read_text(encoding="utf-8"))
    items = catalog["assets"]
    if len(items) != 8 or catalog.get("defaultBackground") != "softGreenFlow":
        raise RuntimeError("Expected eight paid backgrounds and free green default")
    expected = {f"wv_premium_{n:02d}.webp" for n in range(1, 9)}
    provided = {item["file"] for item in items}
    if provided != expected:
        raise RuntimeError(f"Unexpected premium image list: {provided}")

    failures = []
    for item in items:
        source = FOLDER / item["file"]
        if not source.is_file():
            failures.append(f"Missing: {source.relative_to(ROOT)}")
            continue
        data = source.read_bytes()
        digest = hashlib.sha256(data).hexdigest()
        if digest != item["sha256"]:
            failures.append(f"Image changed or corrupt: {item['file']}")
        if len(data) < 30_000 or data[:4] != b"RIFF" or data[8:12] != b"WEBP":
            failures.append(f"Not a valid sizeable WebP: {item['file']}")
        if item.get("priceCoins", 0) <= 0:
            failures.append(f"Premium background cannot be free: {item['file']}")

    if failures:
        print("Room backgrounds have NOT been installed in this repository:")
        for issue in failures:
            print(" -", issue)
        print("Extract WorldVoice_8_Backgrounds_Install.zip and run the")
        print("included PowerShell installer with -Publish on your laptop.")
        return 1

    print("All eight premium room background images are present and verified.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
