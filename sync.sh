#!/bin/bash
# Cài skill vào ~/.claude/skills: (1) skill tự viết trong ./skills, (2) skill bên thứ ba ghi trong skills-lock.json.
# Dùng: bash sync.sh   (đặt DEST=... để đổi nơi cài)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DEST="${DEST:-$HOME/.claude/skills}"
mkdir -p "$DEST"

for d in "$HERE"/skills/*/; do
  [ -f "$d/SKILL.md" ] || continue
  rm -rf "${DEST:?}/$(basename "$d")"; cp -r "$d" "$DEST/$(basename "$d")"
done

python3 -I - "$HERE/skills-lock.json" "$DEST" <<'PY'
import json, os, shutil, subprocess, sys, tempfile
lock, dest = sys.argv[1], sys.argv[2]
for name, s in json.load(open(lock))["skills"].items():
    if s.get("sourceType") != "github":
        continue
    tmp = tempfile.mkdtemp()
    try:
        subprocess.run(["git", "clone", "-q", "--depth", "1", f"https://github.com/{s['source']}", tmp], check=True)
        if s.get("commit"):
            subprocess.run(["git", "-C", tmp, "fetch", "-q", "--depth", "1", "origin", s["commit"]], check=False)
            subprocess.run(["git", "-C", tmp, "checkout", "-q", s["commit"]], check=False)
        src = os.path.dirname(os.path.join(tmp, s["skillPath"]))
        out = os.path.join(dest, name)
        shutil.rmtree(out, ignore_errors=True)
        shutil.copytree(src, out, ignore=shutil.ignore_patterns(".git"))
        print("synced", name)
    except Exception as e:
        print("FAILED", name, e)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
PY
