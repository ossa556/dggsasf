#!/usr/bin/env bash
set -euo pipefail

# Repository-local, checksum-verified tools. No sudo or global PATH changes.
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
if [[ "$(uname -sm)" != "Linux x86_64" ]]; then
  echo 'This cloud installer supports Linux x86_64. See docs/STUDIO_MIGRATION.ar-MA.md for Windows/macOS.' >&2
  exit 1
fi
command -v curl >/dev/null
command -v python3 >/dev/null
command -v sha256sum >/dev/null

rojo_version='7.7.1'
rojo_digest='00feb4fa0829a1dd72b49df2639da519a352bfe13cadcd83969e2ba2bb5693c4'
rojo_dir="$repo_root/.tools/rojo/$rojo_version"
rojo_archive="$rojo_dir/rojo-linux-x86_64.zip"
mkdir -p "$rojo_dir"
if [[ ! -f "$rojo_archive" ]]; then
  rojo_download="$(mktemp "$rojo_dir/download-XXXXXX.zip")"
  trap 'rm -f -- "$rojo_download"' EXIT
  curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' \
    --retry 2 --connect-timeout 20 --max-time 180 \
    "https://github.com/rojo-rbx/rojo/releases/download/v$rojo_version/rojo-$rojo_version-linux-x86_64.zip" \
    --output "$rojo_download"
  printf '%s  %s\n' "$rojo_digest" "$rojo_download" | sha256sum --check --status
  mv -- "$rojo_download" "$rojo_archive"
  trap - EXIT
fi
printf '%s  %s\n' "$rojo_digest" "$rojo_archive" | sha256sum --check
# Read only the known executable, avoiding archive path extraction.
python3 - "$rojo_archive" "$rojo_dir/rojo" <<'PY'
from pathlib import Path
import os
import sys
import tempfile
from zipfile import ZipFile
with ZipFile(sys.argv[1]) as archive:
    binary = archive.read('rojo')
target = Path(sys.argv[2])
with tempfile.NamedTemporaryFile(dir=target.parent, prefix='.rojo-', delete=False) as handle:
    staged = Path(handle.name)
    handle.write(binary)
try:
    staged.chmod(0o755)
    os.replace(staged, target)
finally:
    staged.unlink(missing_ok=True)
PY
"$rojo_dir/rojo" --version

luau_version='0.743'
luau_digest='99d45afb4afaee00ba631c526c8e8c76c67b60f6f119953ce6409be6d6953663'
luau_dir="$repo_root/.tools/luau/$luau_version"
luau_archive="$luau_dir/luau-ubuntu.zip"
mkdir -p "$luau_dir"
if [[ ! -f "$luau_archive" ]]; then
  luau_download="$(mktemp "$luau_dir/download-XXXXXX.zip")"
  trap 'rm -f -- "$luau_download"' EXIT
  curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' \
    --retry 2 --connect-timeout 20 --max-time 180 \
    "https://github.com/luau-lang/luau/releases/download/$luau_version/luau-ubuntu.zip" \
    --output "$luau_download"
  printf '%s  %s\n' "$luau_digest" "$luau_download" | sha256sum --check --status
  mv -- "$luau_download" "$luau_archive"
  trap - EXIT
fi
printf '%s  %s\n' "$luau_digest" "$luau_archive" | sha256sum --check
python3 - "$luau_archive" "$luau_dir" <<'PY'
from pathlib import Path
import os
import sys
import tempfile
from zipfile import ZipFile
with ZipFile(sys.argv[1]) as archive:
    for name in ('luau', 'luau-compile', 'luau-analyze'):
        target = Path(sys.argv[2]) / name
        with tempfile.NamedTemporaryFile(dir=target.parent, prefix='.luau-', delete=False) as handle:
            staged = Path(handle.name)
            handle.write(archive.read(name))
        try:
            staged.chmod(0o755)
            os.replace(staged, target)
        finally:
            staged.unlink(missing_ok=True)
PY
python3 tools/check_project.py
python3 -m unittest discover -s tests -v
