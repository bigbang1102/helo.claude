---
name: awaken-form
description: "แก้/ทำงานฟอร์ม (form) ในระบบ red ERP (wildfly2 / red-erp-wildfly) — ฟอร์มกรอกข้อมูล/บันทึกรายการ (ไม่ใช่ report). Playbook + casebook สะสมความรู้ต่อฟอร์ม. Trigger: /awaken-form, 'แก้ฟอร์ม', 'ฟอร์มเปิดไม่ได้', 'บันทึกฟอร์มไม่ได้', ชื่อ form code เช่น G-CPOSOB. ใช้เฉพาะงาน FORM — งาน report ใช้ /awaken-report."
installer: create-shortcut
created_at: 2026-07-14T14:27:03+07:00
---

# /awaken-form — Playbook ทำงานฟอร์ม red ERP

Skill สำหรับงาน **form เท่านั้น** ในระบบ red ERP (JSP form กรอก/บันทึก/แก้ไขรายการ — คู่กับ [[awaken-report]] ที่ดูแลฝั่ง report).
โครงคงที่อยู่ในไฟล์นี้ · ความรู้ต่อฟอร์ม (field/quirk/สถานะ) สะสมใน **`casebook.md`** (ข้างไฟล์นี้).

> ปรัชญาเดียวกับ awaken-report: ฟอร์มเป็นร้อยแต่ pattern ซ้ำ → เดินตาม checklist + เปิด casebook เช็กก่อน + จดสิ่งใหม่ทุกครั้ง
> **สถานะตอนนี้: เคสแรกลงแล้ว (E-PV-07, 2026-07-15)** — checklist/gotchas เริ่มผ่านการพิสูจน์จากงานจริงบ้างแล้ว ยังสะสมต่อเนื่อง

## Step 0: Init (เริ่มทุกครั้ง)
```bash
date "+🕐 %H:%M %Z (%A %d %B %Y)" && cat "$HOME/.claude/skills/awaken-form/casebook.md" 2>/dev/null | head -60
```
อ่าน casebook ก่อน — ถ้าฟอร์มที่จะทำ (หรือพี่น้องในโมดูลเดียวกัน) เคยทำแล้ว จะรู้ quirk ทันที

## สภาพแวดล้อม (จำไว้ — เหมือน awaken-report)
- **source repo**: `C:\git\wildfly2` (แก้โค้ดที่นี่)
- **deploy path (form)**: `C:\git\red-erp-wildfly\standalone\deployments\redjaka.ear\red.war\form\<module>\...` — **server รันจาก deploy ไม่ใช่ repo** → แก้แล้วต้อง copy ไป deploy เสมอ
- **red-erp-wildfly** = ตัว WildFly server distro (bin/domain/standalone) · **wildfly2** = source code เว็บแอป — คนละก้อน (ดู [[ตู่-oracle]])
- module folders ที่มีจริงใต้ `form/`: `apmedium, ar, asd, cap, form_include, gl, image, mm, pc, pos, posoutbounddelivery, pv, py, rc, rv, sd, tax`
- form code convention ตัวอย่างที่เจอ: `G-CPOSOB-x` (module `pos/changeposoutbounddelivery`)
- server เทสต์: acedemo.acecloud.co.th:52333 (เดียวกับฝั่ง report — ยืนยันซ้ำตอนทำจริง)

## Workflow — checklist ต่อฟอร์ม (โครงเริ่มต้น ยังไม่ผ่านเคสจริง — ปรับตามที่เจอ)
1. **หา form code + path จริงใน deploy** — ห้ามเดาจาก folder-name match อย่างเดียว (บทเรียนจาก awaken-report: folder คล้ายกันแต่คนละฟอร์ม) เปิดดู scriptlet/hardcode code ในไฟล์ก่อนแก้เสมอ
2. **เทียบกับ `.bak-broken-*`** ถ้ามี (เวอร์ชันที่เคยทำงานได้ — ต้นแบบ field/alias ที่ถูก)
3. **field ที่ submit ตรงกับฝั่งรับจริงไหม** (servlet/action/DAO) — ชื่อ param client กับ server ต้องตรงกัน
4. **required/validation** — เช็กทั้งฝั่ง client (JS) และฝั่ง server ว่าตรงกัน ไม่ใช่แค่ JS validate ผ่านแล้วจบ
5. **shared field/function ก่อนแก้ต้อง grep หาก่อนเสมอ** (field ในระบบนี้มักใช้ร่วมข้ามฟอร์ม/รายงานเป็นร้อยไฟล์ — บทเรียนจาก awaken-report เตือนไว้แรง ดู casebook นั้นประกอบ)
6. ฟอร์มนี้ยิง report/drilldown ต่อไหม (บางฟอร์มเปิดจากปุ่มในหน้า report) — ถ้าใช่ cross-check กับ [[awaken-report]] casebook

## ⚠️ Gotchas
- **deploy≠repo กระทบฟอร์มด้วยเหมือน report** — ยืนยันจริงจากเคส E-PV-07: source ตัวจริงอยู่ `C:\git\wildfly2\form\<module>\...` (มี `.jasper` ต้นฉบับ) แต่ถ้าแก้/สร้างไฟล์ที่ deploy path (`red-erp-wildfly\...\form\...`) ตรงๆ โดยไม่ sync กลับ source repo — **งานจะหายถ้า deploy path โดน reset จาก source ใหม่วันหลัง** ต้อง sync ทั้ง 2 ทางเสมอ (ไม่ใช่แค่ source→deploy ทางเดียวตามที่เขียนไว้เดิม)
- **ฟอร์มบางกลุ่มกำลัง migrate สถาปัตยกรรม JasperReports** (ไม่ใช่แค่เปลี่ยน table→view) — เช่น จาก "1 subreport file = 1 หน้า" (เก่า) ไปเป็น query เดียวรวม + self-pagination ในตัว (`<break>`+`pageFooter`/`lastPageFooter`, ใหม่) ก่อน clone ไฟล์ในกลุ่มที่กำลัง migrate ต้องอ่านกลไก pagination ภายในของไฟล์ต้นทางให้ครบก่อนเสมอ อย่าพอร์ต pattern เก่ามาโดยไม่ตรวจ (ดูรายละเอียดเคส E-PV-07 ใน casebook)
- **ไม่มี DB access ตรง แต่ project มี JDBC driver jar (`mysql-connector-j-*.jar`) อยู่ใน `modules/`** — ถ้ามี Java/JRE ในเครื่องด้วย เขียน read-only query runner เองได้ (อ่าน credential จาก `standalone.xml` runtime, whitelist เฉพาะ SELECT/SHOW/DESC/EXPLAIN) ไม่ต้องรอ user รัน query ทุกรอบ — ดูตัวอย่างใน retro 2026-07-15
- **field ที่ query คำนวณมาไม่ได้แปลว่าถูกใช้แสดงผลเสมอ** — ก่อนตัดสินว่า query diff (เก่า vs ใหม่) กระทบฟอร์มจริง ต้องเช็คว่า field นั้นถูกอ้างอิงใน `printWhenExpression`/`textFieldExpression` ของ layout จริงไหม และเช็คกับข้อมูลจริงว่า scenario ที่ต่างกันเคยเกิดขึ้นไหม (อย่าเชื่อ diff query ผิวเผินอย่างเดียว)

## Per-form — ถามก่อนเริ่ม (ถ้า casebook ยังไม่มี)
- form code + path จริงใน deploy (`form/<module>/...`)
- มี `.bak-broken` ให้เทียบไหม
- error จริงคืออะไร (screenshot / console stack / server log กรองแล้ว)
- ฟอร์มนี้ผูกกับ report/drilldown ตัวไหนไหม

## Step สุดท้าย: บันทึกลง casebook (สำคัญ — นี่คือหัวใจ)
ทำฟอร์มเสร็จ **append 1 แถวลง `casebook.md`** เสมอ: form, module, field ที่แก้/quirk, สถานะ
เจอ pattern ระดับโมดูล → จดใน section "Module patterns" ของ casebook

## หมายเหตุ
- Skill นี้ **เฉพาะงาน form** — งาน report ใช้ [[awaken-report]]
- ห้าม commit/push/restart server เอง (กฎ global) · ไม่แก้ DB จริงถ้าไม่ได้สั่ง
- deploy path เดียวกับ report: `red-erp-wildfly` = server distro, `wildfly2` = source
