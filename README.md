# claude-skills

Nguồn duy nhất cho skill dùng ở mọi môi trường Claude Code.

- `skills/<tên>/SKILL.md`: skill tự viết.
- `skills-lock.json`: skill bên thứ ba, cài lại từ nguồn gốc (không sao chép).
- `sync.sh`: cài tất cả vào `~/.claude/skills`.

Thêm vào setup script của môi trường:

```bash
git clone -q --depth 1 https://github.com/khoitran279/calude-skill /opt/calude-skill && bash /opt/calude-skill/sync.sh
```
