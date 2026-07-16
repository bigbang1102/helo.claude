# Global Oracle Config

## Central Oracle Hub

**ORACLE_ROOT**: `~/oracle`

เมื่อใช้ /rrr, /recap, หรือ skill ใดๆ ที่เขียนลง ψ/ — ให้ใช้ `~/oracle` เป็น Oracle root เสมอ ไม่ว่าจะ cd อยู่ที่ไหน

```
PSI=~/oracle/ψ
```

## Incubate โปรเจคใหม่

เมื่อเพิ่มโปรเจคใหม่เข้า Oracle ให้สร้างโครงสร้างนี้อัตโนมัติ:

```bash
# 1. สร้างโครงสร้าง
mkdir -p ~/oracle/ψ/incubate/OWNER/REPO/{retrospectives,learnings}

# 2. Symlink ไปต้นทาง
ln -s /path/to/project ~/oracle/ψ/incubate/OWNER/REPO/origin

# 3. สร้าง hub file (REPO.md)
# 4. เพิ่มใน .origins manifest
# 5. อัปเดตตาราง Projects ใน global config ทุก agent
```

## Retrospectives & Learnings — แยกรายโปรเจค

**สำคัญ:** retro และ learnings ต้องเก็บแยกตามโปรเจคใน `ψ/incubate/` ไม่ใช่ `ψ/memory/`

```
# เมื่อทำงานกับโปรเจคใด → เขียน retro/learnings ใน incubate ของโปรเจคนั้น
ψ/incubate/OWNER/REPO/retrospectives/YYYY-MM/DD/HH.MM_slug.md
ψ/incubate/OWNER/REPO/learnings/YYYY-MM-DD_slug.md

# ψ/memory/ เก็บเฉพาะเรื่องข้ามโปรเจค หรือเรื่องของ Oracle กลาง
ψ/memory/retrospectives/   ← retro ของ Oracle setup, toolchain
ψ/memory/learnings/        ← บทเรียนข้ามโปรเจค
```

## Oracle Roster

| Oracle | Team | Tool | Project | Hub |
|--------|------|------|---------|-----|
| ตู่ | - | Claude Code | red-erp-wildfly, wildfly2, new-template | `~/oracle/ψ/` (flat, ไม่ใช้ incubate) |

## Projects

| Project | Path | Incubate Path |
|---------|------|---------------|
| red-erp-wildfly | C:/git/red-erp-wildfly | ψ/memory/resonance/ (ตู่ Oracle, flat ใน ~/oracle/ψ/ ไม่แยก incubate) — WildFly server distro (bin/domain/standalone) |
| wildfly2 | C:/git/wildfly2 | ψ/memory/resonance/ (ตู่ Oracle, flat ใน ~/oracle/ψ/ ไม่แยก incubate) — source code เว็บแอป ERP/POS (JSP) |
| new-template (red.war) | C:/git/new-template/wildfly-30.0.0.Final/standalone/deployments/redjaka.ear/red.war | ψ/memory/resonance/ (ตู่ Oracle, flat ใน ~/oracle/ψ/ ไม่แยก incubate) — exploded WAR ใน redjaka.ear บน WildFly 30 template ใหม่ (GitLab: erp-wildfly/red.war) |

## Preferences

- Language: Thai
- Timezone: GMT+7 (Bangkok)
- Style: กระชับ ตรงประเด็น ทำเลยไม่ต้องถามยาว

## Rules — เด็ดขาด ใช้ทุกโปรเจค ทุกครั้ง

1. **ห้าม start/restart dev server หรือ long-running server แบบ background เอง** (`npm run dev`, `next dev`, `nest start`, `node dist/...`, ฯลฯ) — แม้ดูเหมือน user สั่ง restart ก็ตาม ให้ user รันเอง / แนะนำคำสั่งให้ (one-off script ที่จบในตัว เช่น seed/backfill รัน foreground ได้)
2. **ห้าม `git commit` / `git push` ถ้าไม่ได้รับคำสั่งตรงๆ** — แก้โค้ดได้ตามสั่ง แต่หยุดก่อน commit/push เสมอ บอกว่าพร้อมแล้วรอคำสั่ง user ตรวจ diff เอง
3. **commit/PR message ห้ามแนบ Claude trailer** — ไม่มี `Co-Authored-By: Claude ...` และ `🤖 Generated with Claude Code`
4. **ห้ามสร้าง/แก้ข้อมูลจริงใน DB ถ้าไม่ได้สั่ง** (test data, seed) — ถ้าจำเป็นต้องถามก่อน
# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.

@RTK.md
