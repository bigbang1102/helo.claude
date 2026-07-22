---
name: awaken-excelgen
description: "งาน Excel gen ของ red ERP — เรียง field ในไฟล์ .xls ตาม layout spec แล้ว gen เป็น document type/workflow ผ่าน redTools. Playbook + casebook สะสมความรู้ต่อเอกสาร. Trigger: /awaken-excelgen, 'excel gen', 'แปลง excel', 'เรียงฟิลด์', 'gen เอกสารใหม่', ชื่อไฟล์ใบงานเช่น T-AD-ContactActivity / T-PC-PO. ใช้เฉพาะงาน EXCEL GEN — งาน form ใช้ /awaken-form, งาน report ใช้ /awaken-report."
installer: create-shortcut
created_at: 2026-07-21T15:40:00+07:00
---

# /awaken-excelgen — Playbook งาน Excel gen red ERP

Skill สำหรับงาน **Excel gen เท่านั้น** — เรียง field ในไฟล์ใบงาน `.xls` ตาม layout spec แล้ว gen ออกมาเป็น document type + workflow + JSP ของ red ERP
(คู่กับ [[awaken-form]] ฝั่งฟอร์ม และ [[awaken-report]] ฝั่งรายงาน)

โครงคงที่อยู่ในไฟล์นี้ · ความรู้ต่อเอกสาร (BDNAME/quirk/สถานะ) สะสมใน **`casebook.md`** (ข้างไฟล์นี้)

> **สถานะ: ผ่านงานจริง 4 เอกสาร (CAC, CJ, CA, Lead) — 2026-07-21..22** ทุกข้อในเช็คลิสต์ล้วนมาจากที่เคยพลาดจริง

---

## ✅✅ PRE-FLIGHT CHECKLIST — ทบทวนทุกข้อก่อน gen (ทุกข้อคือเคยพลาดจริง ห้ามซ้ำ)

**อ่านให้ครบก่อนลงมือทุกครั้ง** — ทุกบรรทัดคือบั๊กจริงจากเซสชัน 2026-07-21..22

### A. โครงไฟล์ / การเรียง field
- [ ] **`advance_usecase` เป็นสูตร ห้ามเขียนทับ** — เรียงที่ `standard_usecase` + ย้าย constrain/other/formula + adv c23/c30 เท่านั้น
- [ ] **offset ไม่เท่ากันทุกไฟล์** — อ่าน `.Formula` (ไม่ใช่ `.Text`) ของ adv แถวแรกหา offset จริง (CAC adv=std+36 · Formintent/Formloan adv=std+22, constrain=std−1, formula=std−2) · `convert2.ps1` มี offset guard throw ถ้าไม่ตรง
- [ ] **สูตร `#field-subtab#` (adv c31) มักมีไม่ครบทุกแถว** — เพิ่ม field แล้วต้องเติม `=standard_usecase!H<r−offset>` เอง + `ClearContents` แถวที่เกิน (ไม่งั้นโชว์ `0`)
- [ ] **default-field ครบ 7 ตัว** (TXDATE,REFDOCNO,REFDOCDATE,TXNO,STATUS,TXTYPE,REMARK) — ตัวที่ตกจะโผล่แท็บ "เอกสาร" เกิน (ปกติ TXTYPE แปะ field สุดท้ายของข้อมูลอ้างอิง)
- [ ] **`#new-line#`** — บรรทัด spec ที่ field แรกไม่ใช่ตัวเริ่ม subtab ต้องมาร์คเอง (ตระกูล Formintent/Formloan: `exists_txno` = `true`)

### B. ค่าที่ต้องเป็น "value" ไม่ใช่ "สูตร" (redTools อ่านสูตรไม่เห็น)
- [ ] **`#is-config-field#`** ใช้ `.Value2=$true` ให้ `.Formula` อ่านได้ `TRUE` (**ไม่ใช่ `=TRUE`**) — ไม่งั้น info_icon ลง DB ว่าง ปุ่ม ⓘ ไม่ขึ้น
- [ ] **`constrain D` / `other B`** ก็ใช้ `.Value2=$true` เช่นกัน
- [ ] text ที่ต้องคงเป็น string (`true` เล็ก, `:SUFFIX:`) → ตั้ง `NumberFormat='@'` ก่อนเขียน

### C. caption / ชื่อ (อ่านจาก spec เท่านั้น)
- [ ] **caption ต้องอ่านจาก spec ของเอกสารนั้น** — ห้ามก็อปจากเอกสารอื่น (เคยก็อป "ประเภทงานเอกสาร" ทับ "ประเภทรายการย่อย") · caption อยู่ใน `webinterface.xml` (`fieldcaption=`) 2 ไฟล์ (หลัก + `quick\`) ไม่ใช่ DB

### D. set_display — 4 บล็อค เช็คให้ครบ
- [ ] **BDNAME** ถาม user (เดาไม่ได้) + เช็คไม่ชน: `SELECT DISTINCT bdname FROM wfdisplayitemdisplaytab`
- [ ] **`wfdisplayitemsubtab` ITEM_TABNAME = `DeleteItemForm<X>`** (Form **ไม่ใช่** From!)
- [ ] **`SHOW_FIELDLIST`: field ที่เป็น Reference เติม `Code` ตัวใหญ่** (เช่น `attachfiletype`→`attachfiletypeCode`) — เช็คชนิดข้อมูลใน standard_usecase col C
- [ ] **`wfdisplay_displayattributeconf` ต้องมี** — field หน้าข้อมูลภายในตั้ง `readonly` ทุกตัว · **FIELDLIST ต่างตามตระกูล** เช็ค DB: `SELECT fieldname FROM wfdisplay_displaymasterconf WHERE requestname='<doc>' AND field_subtab='ข้อมูลอ้างอิง'` (ข้อมูลผู้ใช้ = คนละแท็บ ไม่นับ)

### E. ⛔ ต้นเหตุที่ field ไม่แสดง (ก่อนไล่ debug ยาว — เช็คนี้ก่อน!)
- [ ] config การแสดง field อยู่ที่ **เครื่อง gen 172**: `businessdocumentextend\<module>\<Doc>.xml` — ถ้า **read-only** gen ทับไม่ได้ → เอา read-only ออก + ตั้ง field เป็น **Show** ที่ `http://192.168.24.172:8080/admin/control/` → Business Document Management
- [ ] **อย่าไล่ debug จาก DB/ไฟล์ปลายทาง (233) ก่อน** — จอไม่ได้อ่านจากตรงนั้นเป็นหลัก (เคยเสียเวลาทั้งเซสชันไล่ผิดเครื่อง)

### F. verify ก่อนบอกว่าเสร็จ
- [ ] เทียบ marker ทีละ field เทียบต้นฉบับ (ไม่มี field หาย/marker เพี้ยน)
- [ ] **behavior บน target จริงยังไม่เห็นด้วยตา → บอกระดับความมั่นใจ อย่าฟันธง** (ดู [[feedback-verify-uncertainty-before-asserting]])

---

## Step 0: Init (เริ่มทุกครั้ง)
```bash
date "+🕐 %H:%M %Z (%A %d %B %Y)" && cat "$HOME/.claude/skills/awaken-excelgen/casebook.md" 2>/dev/null | head -80
```
อ่าน casebook ก่อน — ถ้าเอกสารที่จะทำ (หรือพี่น้องในโมดูลเดียวกัน) เคยทำแล้ว จะรู้ quirk ทันที

---

## สภาพแวดล้อม

| อะไร | ที่ไหน |
|---|---|
| repo ไฟล์ใบงาน | `C:\git\red-erp-excel-gen\erp-excel-gen\` |
| ต้นฉบับ (ยังไม่แปลง) | `Transaction\*.xls` — **ห้ามแก้ทับ** |
| ปลายทาง (แปลงแล้ว) | `new_Transaction\*.xls` |
| วางไฟล์ก่อน gen (238) | `D:\red\it\project\dev-usecase\jbuider\src\resource\ERP\<โฟลเดอร์ตัวเอง>` |
| redTools gen | `http://192.168.24.238:8880/redtools/generate/redTools.jsp` (admin/91011) |
| **admin Business Document (คุมการแสดง field)** | `http://192.168.24.172:8080/admin/control/` → จัดการ Business Document → Bussiness Document Management |
| **config การแสดง field (ต้นเหตุ field ไม่ขึ้น)** | เครื่อง **172**: `D:\red\jboss3\server\product\deploy\red.ear\conf\red\workflow\businessdocumentextend\<module>\<Doc>.xml` — **ระวัง read-only** |
| เครื่องปลายทาง UAT | `\\192.168.24.233\redr2_uat\wildfly-30.0.0.Final\standalone\` ← **เข้าได้ตรงๆ จาก UNC ไม่ต้องขอ credential** |
| DB ที่แอปใช้ | `192.168.24.137` / `red2` (ดู `java:/REDDS` ใน `standalone.xml` ของ 233) |
| DB ฝั่ง gen server | `192.168.24.238` / `red` — **คนละตัวกับที่แอปอ่าน** |
| แอปทดสอบ | `acedemo.acecloud.co.th:52333` |

**DB access**: ระบบใช้ MySQL · credential อยู่ใน `standalone.xml` (`root/mkitw2dG` ใช้ได้กับ .47 และ .137 — **ใช้กับ 238 ไม่ได้**) · 238 เป็น MySQL เก่า ต้องใช้ connector `mysql-connector-java-5.1.49_231016.jar` (ตัว 8.4/9.4 ขึ้น `CLIENT_PLUGIN_AUTH is required`) · query ได้ด้วย `java --class-path <jar> Q.java`

---

## ⛔ กฎข้อแรก — โครงสร้างไฟล์ที่ต้องรู้ก่อนแตะอะไร

**`advance_usecase` เป็นสูตรเกือบทั้งแผ่น ห้ามเขียนทับ** (เคยพลาดมาแล้ว → สูตรพังเป็น `#REF!` ต้อง restore)

```
advance แถว R  ←  standard_usecase แถว R−36     (master)
advance แถว 137 ←  standard_usecase แถว 96       (item)

c1  #tabname-L1#     = std!D          c7  #require#    = constrain!D
c2  #tabname-L2#     = std!G          c8  #svc#        = other!B
c3  #fieldname#      = std!A          c9  #report#     = other!C
c4  #dataname-L1#    = std!B          c20 #calculate#  = formula!J
c5  #dataname-L2#    = std!F          c21 #constrain#  = constrain!J
c6,c13,c14,c15,c17   derive จาก std!C/E
c31 #field-subtab#   = std!H
```

**literal มีแค่ 2 คอลัมน์**: `c30 #field-description#` และ `c23 #default-field#` — สองตัวนี้ผูกกับตำแหน่งแถว ต้องย้ายตามเวลาเรียง field

**→ วิธีเรียง field ที่ถูก = เรียงที่ `standard_usecase` + ย้ายค่าใน `constrain`/`other`/`formula` + ย้าย `adv c30`/`c23` แล้ว advance อัปเดตเอง**

โครงแถว: `standard_usecase` master rows 8–53 · spare `none` rows 54+ · item header 94–95 · item fields 96–99
`constrain`/`other`/`formula` แถวตรงกับ `standard` 1:1 (col A เป็นสูตรดึงชื่อ field) · ค่า TRUE เก็บเป็นสูตร `=TRUE`

---

## กฎอ่าน layout spec (`ERP_<Doc>_Header_vN.xlsx`)

| ที่เห็นใน spec | หมายถึง |
|---|---|
| หัวข้อชิดซ้าย **มีเลข** (`1. ข้อมูลหลัก`, `7. ข้อมูลผู้ใช้`, `12. ข้อมูลภายใน`) | **tab** (`#tabname-L1#`) + ลำดับมาตรฐาน |
| หัวข้อชิดซ้าย **ไม่มีเลข** (ประเภทรายการ, รายละเอียดเอกสาร) | **subtab** (`#field-subtab#`) |
| cell `ชื่อไทย\n(fieldcode)` | field จริง |
| cell **ไม่มีวงเล็บ code** | **default-field** |
| แต่ละบรรทัด ~4 field | แถวการแสดงผล → `#new-line#` |
| **`***`** นำหน้า tab (`***12. ข้อมูลภายใน`) | เพิ่มใน `set_display` → `wfdisplay_displayoptionconf` แบบ `extend-master` |
| บล็อค `ข้อมูลอื่น` ท้าย spec | default-field ที่ยังไม่ถูกวางในหน้าจอหลัก |

**`:SUFFIX:`** = default-field ที่วางต่อท้าย field จริงในภาพ → ใส่ในคอลัมน์ `#default-field#` ของ **field จริงตัวก่อนหน้า**
ตัวอย่าง: `document_category` → `:SUFFIX:TXDATE,:SUFFIX:TXNO,:SUFFIX:STATUS,:SUFFIX:REFDOCNO,:SUFFIX:REFDOCDATE`

### ⚠️ default-field ต้องครบ 7 ตัวเสมอ
`TXDATE, REFDOCNO, REFDOCDATE, TXNO, STATUS, TXTYPE, REMARK`
ตัวที่ไม่ถูก `:SUFFIX:` แปะกับ field ไหนเลย **จะตกไปอยู่แท็บ "เอกสาร" ที่ระบบสร้างเอง** → มีแท็บเกินจาก spec
(เคสจริง: spec ContactActivity ไม่มีบล็อค "ข้อมูลอื่น" เลยไม่ได้วาง `TXTYPE` → โผล่แท็บเกิน)

---

## Workflow — checklist ต่อเอกสาร

1. **ขอของให้ครบก่อนเริ่ม**: ชื่อไฟล์ · layout spec (`ERP_*_Header_vN.xlsx`) · **BDNAME** · field ไหนต้องมีปุ่ม ⓘ
2. **อ่าน spec** ตามกฎด้านบน → เขียนลำดับ field เป้าหมายลงไฟล์ (1 บรรทัด = `fieldname|tabL1|tabL2|subtab|defaultfield`)
3. **ตรวจ default-field ครบ 7 ตัว** ก่อนลงมือ
4. **copy ต้นฉบับ → `new_Transaction\`** (คนละคำสั่งกับตอนเปิดไฟล์ ดู gotcha)
5. **เรียงที่ `standard_usecase`** + ย้าย `constrain!D/J`, `other!B/C`, `formula!J`, `adv c30/c23`
6. **verify ก่อนส่ง**: เทียบ marker ทีละ field ระหว่างต้นฉบับกับตัวใหม่ — ต้องไม่มี field หาย และ marker ต้องตามไปครบ
7. **สร้าง sheet เสริม**: `set_display` (ถ้ามี `***` หรือมี item) · `Sheet1` (แผ่นทด 21 คอลัมน์ master อย่างเดียว)
8. **ส่ง gen** → ย้ายไฟล์ 238→233 (`documenttype`, `businessdocument`, `lib`, `red.war/WEB-INF/jsp`) → **redeploy/restart** → แปลงภาษา
9. **บันทึกลง casebook**

---

## ผลลัพธ์หลัง gen ไปไหนบ้าง

**1) DB โดยตรง** (เห็นผลทันที ไม่ต้อง deploy) — `wfdisplay_displaymasterconf`
key = `requestname` (ชื่อ module) + `orderno` (ทีละ 100 เริ่ม 0)
คอลัมน์ ↔ marker: `defaultfield_list`=#default-field# · `add_newline` · `display_field` · `extend_tab` · `icon` · `info_icon`=#is-config-field# · `info_desc`=#field-description# · `field_subtab`
**field ประเภท Reference จะถูกเติม `Code`** ใน DB (`businessentityCode`, `assign_toCode`)

**⚠️ caption ของ field ไม่ได้อยู่ใน DB** — `wfdisplay_displaymasterconf` มีแค่ `fieldname` / `info_desc` / `field_subtab`
ชื่อไทยที่โชว์บนจอเก็บใน `webinterface.xml` → `<pattern name="xxxCode" fieldcaption="ชื่อไทย" fieldcaption_L2="อังกฤษ" …>`
**มี 2 ไฟล์ต้องแก้คู่กันเสมอ**: `<module>-webinterface.xml` และ `quick\<module>-webinterface.xml`

**2) ไฟล์ที่ต้องก็อปเอง** — `documenttype/`, `businessdocument/`, `lib/*.jar`, **`red.war/WEB-INF/jsp/<module>/<module>/<module>/<module>-webinterface.xml`**
`webinterface.xml` คือไฟล์ที่คุม layout จริง: แท็บ = `<page name="ไทย" name_L2="อังกฤษ">` · item form = `<form name="DeleteItemForm<Item>">`

> **อาการคลาสสิก: header เปลี่ยนแต่ item ไม่มา** = gen เขียน DB สำเร็จ แต่ jsp ยังไม่ได้ก็อป/ยังไม่ redeploy
> **WildFly cache `webinterface.xml` ตอน deploy** — ก็อปไฟล์เฉยๆ ไม่มีผล ต้อง redeploy (เช็ค `WFLYSRV0010: Deployed "redjaka.ear"` ใน `server.log` เทียบกับ `LastWriteTime` ของ jsp)

**⚠️ อย่าเช็คจาก clone ในเครื่อง** — สำเนา dev อาจเก่ากว่าของจริงหลายวันแต่ path หน้าตาเหมือนกันทุกอย่าง **ให้ดูไฟล์บน 233 เสมอ**

---

## sheet `set_display` — 4 บล็อค

| บล็อค | ทำอะไร |
|---|---|
| `wfdisplayitemdisplaytab` | แท็บ item ด้านล่างจอมีอะไรบ้าง · รูปแบบ `ItemName\|ชื่อไทย` คั่น `,` |
| `wfdisplayitemsubtab` | ในแต่ละแท็บโชว์คอลัมน์อะไร · 1 แถว = 1 คอลัมน์ (`ITEM_TABNAME`=**`DeleteItemForm<X>`**, `ITEM_SUBTABNAME`=หัวคอลัมน์ไทย, `SHOW_FIELDLIST`=field, ORDERNO 100/200/…) · **field ที่เป็น Reference ต้องเติม `Code` (ตัวใหญ่) ต่อท้าย** เช่น `attachfiletype`→`attachfiletypeCode` (ดูชนิดข้อมูลใน standard_usecase col C · ยืนยัน DB: STX/ACD/ASP/ASD/GLTX ใช้ `attachfiletypeCode` หมด) |
| `wfdisplay_displayattributeconf` | **field readonly — ต้องใส่ field หน้าข้อมูลภายในทุกตัว** (ITEM_NAME=`master`, ATTRIBUTE_TYPE=`readonly`, FIELDLIST=รายชื่อ field internal) |
| `wfdisplay_displayoptionconf` | tab/subtab ที่มี `***` (extend-master/extend-item) |

แต่ละบล็อคมี `#config-name#` / `#table-name#` / `#delete-bdname-list#` นำหน้า
⚠️ `#delete-bdname-list#` = **ลบแถวของ BDNAME นั้นทิ้งก่อน insert ทุกครั้งที่ gen** — ระวังลบของเดิมที่ยังต้องใช้

**ชื่อ item — ⚠️ ใช้ `DeleteItemForm<X>` (Form ไม่ใช่ From!)**:
`wfdisplay_displaytabconf`→`DeleteItem<X>` · **`wfdisplayitemsubtab`→`DeleteItemForm<X>`** · `wfdisplayitemmode`→`DeleteItemForm<X>`
(เคยเขียน `DeleteItemFrom` (From) ผิด → item subtab ไม่แสดง · user แก้ DB From→Form หมดแล้ว 2026-07-22 · **ห้ามพลาดอีก**)

### ⚠️ set_display ต้องมีบล็อค `wfdisplay_displayattributeconf` ด้วย (จำเป็น)
field ทุกตัวที่อยู่หน้า **ข้อมูลภายใน** ต้องตั้ง `readonly`:
```
#delete-bdname-list#  <BDNAME>
BDNAME  ITEM_NAME  ATTRIBUTE_TYPE  FIELDLIST
<BDNAME>  master  readonly  flow_refdoctype,flow_refdocno,exists_txno,parent_role_owner,role_owner
```
ถ้าไม่ตั้ง → field หน้าข้อมูลภายในจะไม่แสดง/แสดงผิด (เคสจริง Formloan 2026-07-22)
**⚠️ FIELDLIST ไม่ตายตัว — ต่างตามตระกูลเอกสาร** เช็คทุกครั้ง: `SELECT fieldname FROM wfdisplay_displaymasterconf WHERE requestname='<doc>' AND field_subtab='ข้อมูลอ้างอิง'`
- Lead / ContactActivity: `flow_refdoctype,flow_refdocno,parent_refdoctype,parent_refdocno`
- Formintent / Formloan: `flow_refdoctype,flow_refdocno,exists_txno,parent_role_owner,role_owner`
(sd.tsv hardcode ชุด Formintent ไว้ — เอกสารตระกูลอื่นต้องแก้ FIELDLIST เอง) · **ข้อมูลผู้ใช้ เป็นคนละแท็บ ไม่นับ**

### ⛔⛔ ต้นเหตุจริงที่ field ไม่แสดง — config อยู่ที่เครื่อง gen (172) ไม่ใช่ปลายทาง!
**การแสดง field ของ business document คุมจากไฟล์** `businessdocumentextend\<module>\<Doc>.xml` **บนเครื่อง gen (192.168.24.172)**:
`D:\red\jboss3\server\product\deploy\red.ear\conf\red\workflow\businessdocumentextend\<module>\<Doc>.xml`
- ถ้าไฟล์นี้ **read-only** → gen เขียนทับไม่ได้ (เงียบๆ) → field config ค้างของเก่า → **จอไม่เปลี่ยนแม้ DB/webinterface.xml ปลายทางถูกครบ**
- ต้อง **เอา read-only ออก** (ทั้ง 2 ที่บนเครื่อง 172) + ตั้ง field เป็น **Show** ผ่าน admin: **`http://192.168.24.172:8080/admin/control/`** → จัดการ Business Document → **Bussiness Document Management** → เลือกเอกสาร → ช่อง field ตั้ง Not Use / Hide / **Show**
- **บทเรียน: field หายในจอ → เช็คไฟล์ businessdocumentextend บนเครื่อง gen (172) + สิทธิ์ read-only ก่อน** อย่าเสียเวลาไล่ DB/ไฟล์ปลายทาง (233) เพราะจอไม่ได้อ่านจากตรงนั้นเป็นหลัก

**BDNAME ไม่มีสูตรตายตัว** — Lead=`LD` · ContactActivity=`CAC` · PO=`PO` · PR=`PR` · Quotation=`quotation` → **ต้องถามหรือดูจากจอ (ช่องประเภทเอกสาร)**

---

## ⚠️ Gotchas — PowerShell / Excel COM บนเครื่องนี้

เจอครบทุกข้อในเซสชันเดียว เสียเวลารวมหลายชั่วโมง:

- **Python ใช้ไม่ได้** (Store stub) → อ่าน `.xls` ด้วย **Excel COM** เท่านั้น
- **export CSV ต้องใช้ format code `62` (UTF-8)** — code 6 = ANSI ทำภาษาไทยเป็น `????`
- **ข้อความไทยใน `{ }` block ของ command ยาว → PowerShell parser ค้างรอ input ทั้งสคริปต์ไม่รันเลย (ไม่มี output ใดๆ)**
  → เขียนเป็นไฟล์ `.ps1` แบบ **ASCII ล้วน** แล้วอ่านภาษาไทยจากไฟล์ข้อมูลแทน
- **`Copy-Item` ไฟล์ใหญ่ แล้ว `Workbooks.Open` ในสคริปต์เดียวกัน → ค้าง** ต้องแยกคนละคำสั่ง
- **assign array 2 มิติ `object[,]` เข้า `Range.Value2` → Excel ค้าง/OutOfMemory** ใช้เขียนทีละเซลล์หรือทีละแถว (1-D) แทน
- **PowerShell ตัวแปรไม่แยกพิมพ์เล็ก-ใหญ่** — `$n` ทับ `$N` เคยทำให้ loop ไม่รันแต่ `ClearContents` ไปแล้ว = ไฟล์พัง
- `$xl.Calculation=-4135` (manual) ตั้งได้**หลัง** Open เท่านั้น · `CutCopyMode` ตั้งไม่ได้ผ่าน interop · `$wb.CheckCompatibility=$false` ก่อน Save `.xls`
- **⛔ Boolean: ห้ามใช้ `.Formula='=TRUE'`** — จะได้ **สูตร** ไม่ใช่ค่า และ **redTools อ่านไม่เห็น** → `info_icon` ลง DB เป็นค่าว่าง ปุ่ม ⓘ ไม่ขึ้น (เคสจริง T-Formintent 2026-07-21)
  ต้นแบบ Lead/CAC เก็บเป็น **ค่า Boolean** (`.Formula` อ่านได้ `TRUE` ไม่มี `=`) → ใช้ **`.Value2 = $true`** (PowerShell boolean assign เข้า Value2 ได้ปกติ)
  ตรวจหลังเขียนเสมอ: `.Formula` ต้องเป็น `TRUE` ไม่ใช่ `=TRUE`
- **Excel ค้างจาก timeout จะล็อกไฟล์** ทำให้คำสั่งถัดไปค้างตามเป็นลูกโซ่ → `Stop-Process EXCEL -Force` ก่อนเสมอ
- **`Range.Copy` คัดลอกสูตรแบบ relative** → ย้ายแถวแล้วกลายเป็น `#REF!` (Value2 อ่านได้ `-2146826265`)
- **Excel แปลงข้อความ `true`/`TRUE` เป็น Boolean อัตโนมัติ** — ถ้าต้องการ text ต้องตั้ง `NumberFormat='@'` ก่อนเขียน
  (ต้นแบบ: `advance c29 #is-config-field#` = **Boolean TRUE** · `Sheet1 col9 #require#` = **String `"true"` ตัวเล็ก**)
- **network share ไป 233 ช้ามาก** — recursive grep timeout ให้ copy ไฟล์มาวิเคราะห์ในเครื่องแทน

---

## 🔍 Debug — item tab ไม่แสดง

ไล่ตามลำดับนี้ (เคสจริงใช้เวลานานเพราะไล่ผิดทาง):

1. **เทียบกับเอกสารอื่นที่ทำงานได้ก่อนอื่นใด** — "เอกสารที่มี item แบบเดียวกันแสดงยังไง" คำถามนี้ประหยัดที่สุด
2. เช็ค `webinterface.xml` บน **233** ว่ามี `<page name="...">` ของ item ไหม (+ ดู `LastWriteTime`)
3. เปิด DevTools → console หา `nitobi.initGrid ... Success: DeleteItemForm<X>` = grid สร้างสำเร็จ
4. ถ้า grid สร้างแล้วแต่ไม่เห็น → สแกน DOM ทุก frame หา element แล้วไล่ ancestor หาตัวที่ `display:none`/`visibility:hidden`

**ต้นเหตุที่เคยเจอ (2026-07-21)**: `header_master.jsp:4139-4146`
```js
var earlyFtList = d.getElementById('allFooterTabList');
if (earlyFtList && earlyFtList.querySelectorAll('td[onclick*="setSwapActiveTab"]').length === 0) {
  d.body.classList.add('no-footer-tab');
  // + display:none ทุก [id$="_footerTabDiv"]
}
```
ถ้าไม่มีปุ่มแท็บใน `allFooterTabList` เลย → ซ่อนพื้นที่แท็บ item ทั้งหมด → nitobi grid วัดขนาดตอนถูกซ่อนได้ `0×0` ค้าง
(อีกจุดที่ใส่ class เดียวกัน: `header_master.jsp` ~5475)

**ตาราง config ที่ตรวจแล้ว "ไม่ใช่สาเหตุ" — อย่าไล่ซ้ำ**: `wfdisplayitemdisplaytab` (ไม่มีแถวก็แสดงได้) · `wfdisplayitemsubtab` (0 แถวทั้ง DB) · `wfdisplayitemmode` (20 แถวทั้ง DB) · `wfdisplay_displaytabconf` · `displayoptionconf` · `displayattributeconf`

---

## Per-doc — ถามก่อนเริ่ม (ถ้า casebook ยังไม่มี)
- ชื่อไฟล์ใบงาน + layout spec (`ERP_*_Header_vN.xlsx`) ทั้งฝั่ง Header และ Item
- **BDNAME** (เดาไม่ได้)
- field ไหนต้องมีปุ่ม ⓘ (`#is-config-field#`)
- มี field ใหม่ที่ยังไม่มีในไฟล์เดิมไหม (เช่น `businessentity`)
- readonly field มีไหม (`wfdisplay_displayattributeconf`)

## Step สุดท้าย: บันทึกลง casebook (สำคัญ — นี่คือหัวใจ)
แปลงเสร็จ **append 1 แถวลง `casebook.md`** เสมอ: เอกสาร, module, BDNAME, item, quirk, สถานะ
เจอ pattern ระดับโมดูล → จดใน section "Module patterns"

## หมายเหตุ
- Skill นี้ **เฉพาะงาน Excel gen** — form ใช้ [[awaken-form]] · report ใช้ [[awaken-report]]
- ห้าม commit/push/restart server เอง (กฎ global) · ไม่แก้ DB จริงถ้าไม่ได้สั่ง
- **ต้นฉบับใน `Transaction\` ห้ามแก้ทับ** — แปลงลง `new_Transaction\` เสมอ
- ก่อนฟันธงสาเหตุใดๆ ให้ยืนยันกับ target จริง (233/137) ไม่ใช่ clone ในเครื่อง — ดู [[2026-07-21_reread-own-evidence-before-asserting]]
