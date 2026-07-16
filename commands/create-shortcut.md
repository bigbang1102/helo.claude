---
description: v26.5.16 G-CMD | Create local skills as shortcuts — makes real /commands in .claude/skills/. Use when user says "create shortcut", "create skill", "make a command for", "add shortcut", or wants a quick custom /slash-command. Also lists and deletes local skills. ALSO triggers on "Unknown skill", "skill not found", or any unrecognized /slash-command — auto-creates it on the fly.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Task
  - WebFetch
---

# /create-shortcut

Execute the `create-shortcut` skill with args: `$ARGUMENTS`

**If you have a Skill tool available**: Use it directly with `skill: "create-shortcut"` instead of reading the file manually.

**Otherwise**: Read the skill file at `C:\Users\Dev\.claude\skills/create-shortcut/SKILL.md` and follow ALL instructions in it.

---
*arra-oracle-skills-cli v26.5.16*
