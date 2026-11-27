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

# Cài thư viện JS trong tools/ (không làm hỏng sync nếu thiếu npm hoặc lỗi mạng).
if [ -f "$HERE/tools/package-lock.json" ] && command -v npm >/dev/null 2>&1; then
  (cd "$HERE/tools" && npm ci --no-audit --no-fund --silent) && echo "installed tools/ libraries" || echo "WARN: npm ci failed in tools/"
fi

# Kiểm tra: mọi skill (tự viết + trong lock) đã có SKILL.md trong DEST chưa. Chỉ báo cáo, không làm hỏng phiên.
python3 -I - "$HERE" "$DEST" <<'PY'
import json, os, sys
here, dest = sys.argv[1], sys.argv[2]
want = {d for d in os.listdir(f"{here}/skills") if os.path.isfile(f"{here}/skills/{d}/SKILL.md")} if os.path.isdir(f"{here}/skills") else set()
want |= set(json.load(open(f"{here}/skills-lock.json"))["skills"])
missing = sorted(n for n in want if not os.path.isfile(f"{dest}/{n}/SKILL.md"))
print(f"VERIFY skills: {len(want) - len(missing)}/{len(want)} installed in {dest}")
if missing:
    print("VERIFY MISSING:", ", ".join(missing))
tools = f"{here}/tools"
if os.path.isfile(f"{tools}/package.json"):
    deps = json.load(open(f"{tools}/package.json")).get("dependencies", {})
    bad = sorted(d for d in deps if not os.path.isdir(f"{tools}/node_modules/{d}"))
    print(f"VERIFY libs: {len(deps) - len(bad)}/{len(deps)} installed in tools/node_modules")
    if bad:
        print("VERIFY MISSING libs:", ", ".join(bad))
PY
