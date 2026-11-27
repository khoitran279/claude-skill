# claude-skills

Nguồn duy nhất cho skill dùng ở mọi môi trường Claude Code.

- `skills/<tên>/SKILL.md`: skill tự viết.
- `skills-lock.json`: skill bên thứ ba, cài lại từ nguồn gốc (không sao chép).
- `sync.sh`: cài tất cả vào `~/.claude/skills`.

Thêm vào setup script của môi trường:

```bash
git clone -q --depth 1 https://github.com/khoitran279/claude-skill /opt/claude-skill && bash /opt/claude-skill/sync.sh
```
