#!/usr/bin/env python3
"""Publish approved WorldVoice Library novels sequentially on main.

Use from a clean checkout of the original repository with a GitHub-authenticated
origin. PDFs are not regenerated: each is copied byte-for-byte, SHA-256 checked,
committed separately, and checked again on origin/main.

Accepts worldvoice_library_manifest.json (multilingual) or approved_versions.json.
"""
import argparse
import hashlib
import io
import json
import re
import subprocess
import zipfile
from pathlib import Path

REPO = "ahmedalqashar73-sys/worldvoice_v2"
LEVELS = {"A1", "A2", "B1", "B2", "C1", "C2"}
MAX_PDF = 49 * 1024 * 1024


def git(*args, binary=False):
    if binary:
        return subprocess.run(["git", *args], check=True,
                              capture_output=True).stdout
    return subprocess.run(["git", *args], check=True, capture_output=True,
                          text=True).stdout.strip()


def abort(message):
    raise SystemExit("STOP: " + message)


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def load_approved(archive):
    with zipfile.ZipFile(archive) as z:
        names = z.namelist()
        if len(names) != len(set(names)):
            abort("Duplicate ZIP entries")
        if any(n.startswith("/") or ".." in Path(n).parts or "\\" in n
               for n in names):
            abort("Unsafe ZIP path")
        manifest_name = next(
            (n for n in ("worldvoice_library_manifest.json",
                         "approved_versions.json") if n in names), None)
        if not manifest_name:
            abort("Missing approved library manifest")
        manifest = json.loads(z.read(manifest_name))
        if not isinstance(manifest, dict) or not isinstance(manifest.get("books"), list):
            abort("Invalid approved manifest")
        if manifest.get("repository", REPO) != REPO or manifest.get("branch", "main") != "main":
            abort("Wrong repository or branch")
        seen = set()
        selected = []
        for b in manifest["books"]:
            if not isinstance(b, dict):
                abort("Invalid book record")
            ident = b.get("id", "")
            lang = b.get("language", "en")
            level = b.get("level", "")
            asset = b.get("asset", "")
            expected = b.get("sha256", "")
            key = (lang, level, ident)
            if not re.fullmatch(r"[a-z0-9]+(?:[-_][a-z0-9]+)*", ident) or \
               not re.fullmatch(r"[a-z]{2,3}", lang) or level not in LEVELS:
                abort(f"Bad id, language or level: {key}")
            if key in seen:
                abort(f"Duplicate book: {key}")
            seen.add(key)
            if asset != f"assets/stories/{lang}/{level}/books/{ident}.pdf":
                abort(f"Incorrect asset path: {asset}")
            if not isinstance(expected, str) or not re.fullmatch(r"[a-f0-9]{64}", expected):
                abort(f"Missing SHA-256: {asset}")
            if not all(isinstance(b.get(f), str) and b[f].strip()
                       for f in ("title", "title_ar")):
                abort(f"Missing titles: {asset}")
            if type(b.get("chapter_count")) is not int or b["chapter_count"] < 5:
                abort(f"Invalid chapter count: {asset}")
            if asset not in names:
                abort(f"Missing PDF from ZIP: {asset}")
            info = z.getinfo(asset)
            if info.file_size > MAX_PDF or info.file_size < 1024:
                abort(f"PDF size invalid: {asset}")
            payload = z.read(asset)
            if not payload.startswith(b"%PDF-") or b"%%EOF" not in payload[-2048:]:
                abort(f"PDF header/trailer invalid: {asset}")
            if sha256(payload) != expected or b.get("bytes", len(payload)) != len(payload):
                abort(f"PDF SHA-256 or byte count mismatch: {asset}")
            try:
                from pypdf import PdfReader
                pages = len(PdfReader(io.BytesIO(payload), strict=True).pages)
                if "pages" in b and pages != b["pages"]:
                    abort(f"Page count mismatch: {asset} ({pages})")
            except ImportError:
                print("NOTE: install pypdf to verify page counts")
            selected.append((b, payload))
        if not selected:
            abort("No books in manifest")
        return selected


def assert_checkout():
    if git("branch", "--show-current") != "main":
        abort("Only main is permitted")
    remote = git("remote", "get-url", "origin")
    if not (remote.endswith("/" + REPO + ".git") or
            remote.endswith("/" + REPO) or
            remote.endswith(":" + REPO + ".git")):
        abort(f"Unexpected remote: {remote}")
    if git("status", "--porcelain"):
        abort("Uncommitted files exist")
    git("fetch", "origin", "main")
    if git("rev-parse", "HEAD") != git("rev-parse", "origin/main"):
        abort("Local and remote main differ")


def entry_for(b):
    return {"id": b["id"], "language": b.get("language", "en"),
            "level": b["level"], "title": b["title"],
            "title_ar": b["title_ar"], "format": "novel",
            "chapter_count": b["chapter_count"], "asset": b["asset"]}


def apply_metadata(b, index_file, pubspec):
    index = json.loads(index_file.read_text(encoding="utf-8"))
    if not isinstance(index.get("stories"), list):
        abort("Invalid app story index")
    entry = entry_for(b)
    for old in index["stories"]:
        if (old.get("language"), old.get("level"), old.get("id")) == (
                entry["language"], entry["level"], entry["id"]):
            if any(old.get(k) != v for k, v in entry.items()):
                abort(f"Conflicting indexed book: {entry['id']}")
            break
    else:
        index["stories"].append(entry)
        index_file.write_text(
            json.dumps(index, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8")
    asset_line = f"    - assets/stories/{entry['language']}/{entry['level']}/books/\n"
    pub = pubspec.read_text(encoding="utf-8")
    if asset_line not in pub:
        root_line = f"    - assets/stories/{entry['language']}/{entry['level']}/\n"
        anchor = root_line if root_line in pub else "    - assets/stories/index.json\n"
        if anchor not in pub:
            abort("Flutter assets anchor missing")
        pubspec.write_text(pub.replace(anchor, anchor + asset_line, 1),
                           encoding="utf-8")


def publish(archive, dry_run=False):
    assert_checkout()
    top = Path(git("rev-parse", "--show-toplevel"))
    selected = load_approved(archive)
    idx = top / "assets/stories/index.json"
    pubspec = top / "pubspec.yaml"
    existing = json.loads(idx.read_text(encoding="utf-8"))["stories"]
    # Preflight ALL collisions before any commit or push.
    for b, data in selected:
        target = top / b["asset"]
        if target.exists() and target.read_bytes() != data:
            abort(f"Would overwrite different PDF: {b['asset']}")
        for old in existing:
            if (old.get("language"), old.get("level"), old.get("id")) == (
                    b.get("language", "en"), b["level"], b["id"]):
                if any(old.get(k) != v for k, v in entry_for(b).items()):
                    abort(f"Conflicting index: {b['id']}")
    if dry_run:
        for b, _ in selected:
            print("VALID:", b["asset"])
        return
    for i, (b, data) in enumerate(selected, start=1):
        target = top / b["asset"]
        target.parent.mkdir(parents=True, exist_ok=True)
        if not target.exists():
            target.write_bytes(data)
        apply_metadata(b, idx, pubspec)
        git("add", "--", b["asset"], "assets/stories/index.json", "pubspec.yaml")
        pending = subprocess.run(["git", "diff", "--cached", "--quiet"]).returncode
        if pending == 0:
            print(f"[{i}/{len(selected)}] Already published: {b['asset']}")
            continue
        if pending != 1:
            abort("Git diff failed")
        git("commit", "-m", f"Publish approved WorldVoice Library novel: {b['title']}")
        git("push", "origin", "HEAD:main")  # Fast-forward only, NEVER force.
        git("fetch", "origin", "main")
        if git("rev-parse", "HEAD") != git("rev-parse", "origin/main"):
            abort(f"Remote main changed: {b['asset']}")
        remote_bytes = git("show", "origin/main:" + b["asset"], binary=True)
        if sha256(remote_bytes) != b["sha256"]:
            abort(f"Published PDF checksum mismatch: {b['asset']}")
        print(f"[{i}/{len(selected)}] PUBLISHED and verified: {b['asset']}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    publish(args.archive, args.dry_run)


if __name__ == "__main__":
    main()
