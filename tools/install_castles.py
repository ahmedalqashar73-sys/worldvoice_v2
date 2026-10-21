#!/usr/bin/env python3
"""Install the 10 WorldVoice castle WebP files from the supplied ZIP.
Usage: python tools/install_castles.py "C:\\Users\\YOU\\Downloads\\worldvoice_castles_10_webp.zip"
Does not touch Firestore, backend, coins, or other assets.
"""
from pathlib import Path
from zipfile import ZipFile
import argparse
import json

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "assets" / "castles"
EXPECTED = [
    f"castle_{i:02d}_lv{(i - 1) * 5 + 1:02d}-{i * 5:02d}.webp"
    for i in range(1, 11)
]


def install(zip_path: Path) -> None:
    if not zip_path.is_file():
        raise SystemExit(f"ZIP not found: {zip_path}")
    with ZipFile(zip_path) as archive:
        if archive.testzip() is not None:
            raise SystemExit("ZIP integrity check failed.")
        names = set(archive.namelist())
        for name in EXPECTED:
            source = f"assets/castles/{name}"
            if source not in names:
                raise SystemExit(f"Missing castle asset: {source}")
            data = archive.read(source)
            if len(data) < 1024 or data[:4] != b"RIFF" or data[8:12] != b"WEBP":
                raise SystemExit(f"Invalid WebP asset: {name}")
        DEST.mkdir(parents=True, exist_ok=True)
        for name in EXPECTED:
            (DEST / name).write_bytes(archive.read(f"assets/castles/{name}"))
        if "assets/castles/manifest.json" in names:
            manifest = json.loads(archive.read("assets/castles/manifest.json"))
            if len(manifest.get("tiers", [])) != 10:
                raise SystemExit("Invalid castle manifest.")
            (DEST / "manifest.json").write_text(
                json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
    print(f"Installed {len(EXPECTED)} WebP castles into {DEST}")
    print("Next: flutter pub get && flutter analyze && flutter run")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("zip", type=Path, help="Downloaded worldvoice_castles_10_webp.zip")
    install(parser.parse_args().zip)
