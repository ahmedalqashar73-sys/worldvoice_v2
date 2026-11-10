#!/usr/bin/env python3
"""Publish a single approved A2 PDF from staged base64 chunks on main."""
import base64
import hashlib
import io
import json
import re
import shutil
import subprocess
from pathlib import Path

ROOT = Path("assets/stories/en/A2/books")
STAGE = ROOT / ".approved_upload"
INDEX = Path("assets/stories/index.json")
APPROVED = {
    "the_grand_hotel_of_rio": ("The Grand Hotel of Rio", "فندق ريو الكبير", 7, 61, 5579008, "bda795d4d6462514270cfed78b4fd4c436858ca1fe2ea02250941577ae2297cb"),
    "beyond_the_frozen_pass": ("Beyond the Frozen Pass", "ما وراء الممر المتجمد", 9, 60, 9128878, "8a7afc3843d3e6781de1fa4d4a362447e1829aa5b0d20d6d5a9396d78a0066d9"),
    "the_newspaper_in_alexandria": ("The Newspaper in Alexandria", "الجريدة في الإسكندرية", 9, 55, 3779970, "6e5a612a42285e4682a66776c1ef15af393b655b30400ffa3181f3cf583f39e8"),
    "the_last_radio_message": ("The Last Radio Message", "الرسالة الإذاعية الأخيرة", 9, 49, 6027519, "afef6ff52fa1d0e769f54949e60022c248ffd61947143c95aff0c601c5843bc0"),
}

def run(*args, binary=False):
    return subprocess.check_output(args) if binary else subprocess.check_output(args, text=True).strip()

def main():
    if run("git", "branch", "--show-current") != "main":
        raise RuntimeError("Publishing requires original main branch")
    if run("git", "status", "--porcelain"):
        raise RuntimeError("Checkout must be clean")
    dirs = sorted(p for p in STAGE.iterdir() if p.is_dir())
    if len(dirs) != 1 or len(list(STAGE.iterdir())) != 1:
        raise RuntimeError("Expected exactly one staged approved novel")
    folder = dirs[0]
    metadata = json.loads((folder / "approved.json").read_text())
    ident = metadata["id"]
    if ident != folder.name or ident not in APPROVED:
        raise RuntimeError("Unknown or incorrectly staged A2 book")
    title, title_ar, chapters, pages, size, expected = APPROVED[ident]
    count = metadata["parts"]
    if type(count) is not int or not 1 <= count <= 100:
        raise RuntimeError("Invalid chunk count")
    expected_files = {"approved.json"} | {f"{i:03d}.b64" for i in range(count)}
    if {p.name for p in folder.iterdir()} != expected_files:
        raise RuntimeError("Incorrect staged files")
    encoded = "".join("".join((folder / f"{i:03d}.b64").read_text().split()) for i in range(count))
    payload = base64.b64decode(encoded, validate=True)
    if len(payload) != size or hashlib.sha256(payload).hexdigest() != expected:
        raise RuntimeError("PDF differs from user-approved original")
    if not payload.startswith(b"%PDF-") or b"%%EOF" not in payload[-2048:]:
        raise RuntimeError("Invalid PDF signature or trailer")
    from pypdf import PdfReader
    if len(PdfReader(io.BytesIO(payload), strict=True).pages) != pages:
        raise RuntimeError("Approved PDF page count mismatch")
    pubspec = Path("pubspec.yaml").read_text()
    if "    - assets/stories/en/A2/books/" not in pubspec:
        raise RuntimeError("Flutter A2 books not registered")
    target = ROOT / (ident + ".pdf")
    if target.exists() and hashlib.sha256(target.read_bytes()).hexdigest() != expected:
        raise RuntimeError("Refusing to overwrite a different PDF")
    catalog = json.loads(INDEX.read_text())
    entry = {"id": ident, "language": "en", "level": "A2", "title": title,
             "title_ar": title_ar, "format": "novel", "chapter_count": chapters,
             "asset": str(target)}
    old = [b for b in catalog["stories"] if b.get("id") == ident and b.get("level") == "A2" and b.get("language") == "en"]
    if old and old != [entry]:
        raise RuntimeError("Conflicting existing index entry")
    if not target.exists():
        target.write_bytes(payload)
    if not old:
        catalog["stories"].append(entry)
        INDEX.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n")
    shutil.rmtree(folder)
    STAGE.rmdir()
    subprocess.run(["git", "config", "user.name", "github-actions[bot]"], check=True)
    subprocess.run(["git", "config", "user.email", "41898282+github-actions[bot]@users.noreply.github.com"], check=True)
    subprocess.run(["git", "add", "-A", "--", str(ROOT), str(INDEX)], check=True)
    changed = run("git", "diff", "--cached", "--name-only").splitlines()
    allowed = {str(target), str(INDEX)}
    if any(p not in allowed and not p.startswith(str(ROOT / ".approved_upload") + "/") for p in changed):
        raise RuntimeError("Unexpected staged changes: " + repr(changed))
    subprocess.run(["git", "commit", "-m", "Publish approved WorldVoice A2 PDF: " + title], check=True)
    subprocess.run(["git", "push", "origin", "HEAD:main"], check=True)
    subprocess.run(["git", "fetch", "origin", "main"], check=True)
    remote = run("git", "show", f"origin/main:{target}", binary=True)
    if hashlib.sha256(remote).hexdigest() != expected:
        raise RuntimeError("Remote PDF checksum mismatch")
    print(f"Verified on main: {target} ({len(payload)} bytes)")

if __name__ == "__main__":
    main()
