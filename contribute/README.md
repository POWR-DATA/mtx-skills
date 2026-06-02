# Contributing to Matrix Skills

This folder contains everything you need to contribute new skills or improve existing ones.

## Quick setup

Run the install script **once** from the repo root to set up the `/mtx` command:

**macOS/Linux:**
```bash
./contribute/install.sh
```

**Windows (PowerShell):**
```powershell
.\contribute\install.ps1
```

After this, `/mtx capture` is available in any Claude Code session on your machine.

> **Claude Code only.** `/mtx` runs in Claude Code (Anthropic's CLI or VS Code extension), not in GitHub Copilot CLI, Cursor, or other agents — even when they use a Claude model. See [CONTRIBUTING.md](CONTRIBUTING.md#quick-start) for the workaround when you need to capture from another harness.

---

## What's here

| Item | Purpose |
|---|---|
| `CONTRIBUTING.md` | Full contributor workflow and guidelines |
| `commands/mtx.md` | The `/mtx` Claude Code command |
| `templates/skill-template/` | Skill file structure and format template |
| `install.sh` / `install.ps1` | Setup script for the `/mtx` command |

---

## Next steps

1. See [CONTRIBUTING.md](CONTRIBUTING.md) for the full workflow
2. Check [templates/skill-template/](templates/skill-template/) for the skill structure
3. Ready to capture? Run `/mtx capture` in any project
4. Ready to contribute? Create a PR with your new or updated skills

---

## Docs

For more detailed information, see:
- [Contributing Skills Guide](../docs/contributors/contributing-skills.md) — `/mtx` command workflows
- [Skill Authoring Guide](../docs/contributors/skill-authoring-guide.md) — writing great skills
