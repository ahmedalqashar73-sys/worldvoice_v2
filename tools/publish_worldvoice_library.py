#!/usr/bin/env python3
"""Publish approved PDF books sequentially to WorldVoice's main branch.

Archive manifest: worldvoice_library_manifest.json or approved_versions.json.
The manifest has books[] with id, title, title_ar, language, level,
chapter_count, asset, bytes, and sha256. Use --publish to write to GitHub.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
import zipfile
from pathlib import Path

REPOSITORY = 'ahmedalqashar73-sys/worldvoice_v2'
MANIFEST_NAMES = ('worldvoice_library_manifest.json', 'approved_versions.json')
PDF_PATH = re.compile(r'^assets/stories/([a-z]{2,3})/(A1|A2|B1|B2|C1|C2)/books/([a-z0-9]+(?:_[a-z0-9]+)*)\.pdf$')
ROOT_PATH = Path('assets/stories/index.json')
PUBSPEC = Path('pubspec.yaml')


class PublicationError(Exception):
    pass


def git(root: Path, *args: str) -> str:
    process = subprocess.run(['git', *args], cwd=root, text=True,
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if process.returncode:
        raise PublicationError('git ' + ' '.join(args) + ': ' + process.stderr.strip())
    return process.stdout.strip()


def blob_sha(data: bytes) -> str:
    return hashlib.sha1(f'blob {len(data)}\0'.encode('ascii') + data).hexdigest()


def read_archive(archive: Path) -> list[dict]:
    if not archive.is_file():
        raise PublicationError(f'Archive not found: {archive}')
    if archive.stat().st_size > 350_000_000:
        raise PublicationError('Archive exceeds 350 MB; split into smaller batches')
    with zipfile.ZipFile(archive) as bundle:
        names = bundle.namelist()
        if len(names) != len(set(names)):
            raise PublicationError('Duplicate ZIP members are not allowed')
        manifest_name = next((n for n in MANIFEST_NAMES if n in names), None)
        if not manifest_name:
            raise PublicationError('ZIP needs worldvoice_library_manifest.json or approved_versions.json')
        raw = json.loads(bundle.read(manifest_name))
        if not isinstance(raw, dict) or not isinstance(raw.get('books'), list):
            raise PublicationError('Manifest must contain a books array')
        if raw.get('repository', REPOSITORY) != REPOSITORY or raw.get('branch', 'main') != 'main':
            raise PublicationError('Manifest does not target the original main repository')
        if not 1 <= len(raw['books']) <= 100:
            raise PublicationError('Expected 1 to 100 approved books per archive')
        entries = []
        used = set()
        for book in raw['books']:
            if not isinstance(book, dict):
                raise PublicationError('Book manifest entry must be an object')
            path = book.get('asset')
            match = PDF_PATH.fullmatch(path or '')
            if not match:
                raise PublicationError(f'Invalid book path: {path!r}')
            language, level, book_id = match.groups()
            if (book.get('id', book_id) != book_id or
                book.get('language', 'en') != language or
                book.get('level', level) != level):
                raise PublicationError(f'Book metadata disagrees with path: {path}')
            if path in used:
                raise PublicationError(f'Duplicate book: {path}')
            used.add(path)
            if path not in names:
                raise PublicationError(f'PDF missing from ZIP: {path}')
            data = bundle.read(path)
            if len(data) < 100_000 or not data.startswith(b'%PDF-') or b'%%EOF' not in data[-2048:]:
                raise PublicationError(f'Invalid or incomplete PDF: {path}')
            digest = hashlib.sha256(data).hexdigest()
            if digest != book.get('sha256') or len(data) != book.get('bytes'):
                raise PublicationError(f'Approved SHA256/size mismatch: {path}')
            title = book.get('title')
            title_ar = book.get('title_ar')
            chapter_count = book.get('chapter_count')
            if not isinstance(title, str) or not title.strip() or not isinstance(title_ar, str) or not title_ar.strip():
                raise PublicationError(f'Missing book title/Arabic title: {path}')
            if not isinstance(chapter_count, int) or chapter_count < 5:
                raise PublicationError(f'Invalid chapter count (minimum 5): {path}')
            entries.append(dict(id=book_id, title=title, title_ar=title_ar,
                                language=language, level=level, chapter_count=chapter_count,
                                asset=path, data=data, sha256=digest, blob=blob_sha(data)))
        return entries


def ensure_repo(root: Path) -> None:
    if git(root, 'rev-parse', '--show-toplevel') != str(root):
        raise PublicationError('Run only from the original Git repository root')
    if git(root, 'branch', '--show-current') != 'main':
        raise PublicationError('Only main is permitted; refusing any other branch')
    remote = git(root, 'remote', 'get-url', 'origin')
    if not remote.rstrip('/').removesuffix('.git').endswith(REPOSITORY):
        raise PublicationError(f'Unexpected origin remote: {remote}')
    if git(root, 'status', '--porcelain'):
        raise PublicationError('Working tree is not clean; refusing to risk existing work')
    git(root, 'fetch', 'origin', 'main')
    if git(root, 'rev-parse', 'HEAD') != git(root, 'rev-parse', 'origin/main'):
        raise PublicationError('main differs from origin/main; reconcile before publishing')


def commit_and_push(root: Path, paths: list[str], message: str) -> str:
    git(root, 'add', '--', *paths)
    changed = git(root, 'diff', '--cached', '--name-only').splitlines()
    if sorted(changed) != sorted(paths):
        raise PublicationError(f'Unexpected staged files: {changed!r}')
    git(root, 'commit', '-m', message)
    sha = git(root, 'rev-parse', 'HEAD')
    git(root, 'push', 'origin', 'main')
    git(root, 'fetch', 'origin', 'main')
    if git(root, 'rev-parse', 'origin/main') != sha:
        raise PublicationError('Remote main moved during verification')
    return sha


def upload_pdfs(root: Path, books: list[dict]) -> None:
    for index, book in enumerate(books, start=1):
        relative = book['asset']
        target = root / relative
        if target.exists():
            if blob_sha(target.read_bytes()) != book['blob']:
                raise PublicationError(f'Existing path differs from approved PDF: {relative}')
            remote_blob = git(root, 'rev-parse', f'origin/main:{relative}')
            if remote_blob != book['blob']:
                raise PublicationError(f'Existing remote blob differs: {relative}')
            print(f'[{index}/{len(books)}] Already approved: {relative}', flush=True)
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(book['data'])
        commit = commit_and_push(root, [relative], f'Publish approved WorldVoice Library PDF: {book["title"]}')
        remote_blob = git(root, 'rev-parse', f'origin/main:{relative}')
        if remote_blob != book['blob']:
            raise PublicationError(f'Remote SHA mismatch after upload: {relative}')
        print(f'[{index}/{len(books)}] Uploaded and verified: {relative} ({commit})', flush=True)


def register_catalog(root: Path, books: list[dict]) -> None:
    path = root / ROOT_PATH
    raw = json.loads(path.read_text(encoding='utf-8'))
    if not isinstance(raw.get('stories'), list):
        raise PublicationError('Invalid WorldVoice story index')
    rows = raw['stories']
    changed = False
    for book in books:
        matches = [x for x in rows if (x.get('id'), x.get('language'), x.get('level')) ==
                   (book['id'], book['language'], book['level'])]
        entry = {key: book[key] for key in ('id', 'language', 'level', 'title', 'title_ar', 'asset', 'chapter_count')}
        entry['format'] = 'novel'
        if matches:
            current = matches[0]
            if len(matches) > 1 or current.get('format') != 'novel' or current.get('asset') != book['asset']:
                raise PublicationError(f'Conflicting catalog record: {book["id"]}')
            continue
        position = next((i for i, x in enumerate(rows)
                         if x.get('language') == book['language'] and x.get('level') == book['level']), len(rows))
        rows.insert(position, entry)
        changed = True

    pubspec = root / PUBSPEC
    src = pubspec.read_text(encoding='utf-8')
    additional_dirs = sorted({str(Path(b['asset']).parent).replace('\\', '/') + '/' for b in books})
    for directory in additional_dirs:
        if f'    - {directory}' not in src:
            marker = '  assets:\n'
            if src.count(marker) != 1:
                raise PublicationError('Unexpected pubspec flutter assets structure')
            src = src.replace(marker, marker + f'    - {directory}\n', 1)
    changed_paths = []
    if changed:
        path.write_text(json.dumps(raw, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        changed_paths.append(str(ROOT_PATH))
    if src != pubspec.read_text(encoding='utf-8'):
        pubspec.write_text(src, encoding='utf-8')
        changed_paths.append(str(PUBSPEC))
    if changed_paths:
        commit = commit_and_push(root, changed_paths, 'Register approved WorldVoice Library PDF novels')
        print(f'Catalog and Flutter assets registered: {commit}', flush=True)
    else:
        print('Catalog and Flutter assets already registered', flush=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--archive', required=True, type=Path,
                        help='Approved ZIP bundle with manifest and PDF assets')
    parser.add_argument('--publish', action='store_true',
                        help='Commit and push verified files directly to main (default: validate only)')
    args = parser.parse_args()
    books = read_archive(args.archive)
    print(f'Validated {len(books)} approved PDFs: ' + ', '.join(x['id'] for x in books), flush=True)
    if not args.publish:
        return 0
    root = Path.cwd().resolve()
    ensure_repo(root)
    upload_pdfs(root, books)
    register_catalog(root, books)
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (PublicationError, ValueError, OSError, KeyError, zipfile.BadZipFile) as exc:
        print(f'STOP: {exc}', file=sys.stderr)
        sys.exit(1)
