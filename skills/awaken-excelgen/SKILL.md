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

> **สถานะ: เคสแรกลงแล้ว (T-AD-ContactActivity, 2026-07-21)** — playbook ผ่านงานจริง 1 รอบเต็ม ตั้งแต่อ่าน spec จนขึ้นระบบ

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
| `wfdisplayitemsubtab` | ในแต่ละแท็บโชว์คอลัมน์อะไร · 1 แถว = 1 คอลัมน์ (`ITEM_SUBTABNAME`=หัวคอลัมน์ไทย, `SHOW_FIELDLIST`=field code, ORDERNO 100/200/…) |
| `wfdisplay_displayattributeconf` | field readonly |
| `wfdisplay_displayoptionconf` | tab/subtab ที่มี `***` (extend-master/extend-item) |

แต่ละบล็อคมี `#config-name#` / `#table-name#` / `#delete-bdname-list#` นำหน้า
⚠️ `#delete-bdname-list#` = **ลบแถวของ BDNAME นั้นทิ้งก่อน insert ทุกครั้งที่ gen** — ระวังลบของเดิมที่ยังต้องใช้

**ชื่อ item สะกดต่างกันแต่ละตาราง (ระวังสับสน)**:
`wfdisplay_displaytabconf`→`DeleteItem<X>` · `wfdisplayitemsubtab`→`DeleteItemFrom<X>` · `wfdisplayitemmode`→`DeleteItemForm<X>`

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
- **Boolean assign เข้า `.Value2` ไม่ได้** → ใช้ `.Formula='=TRUE'`
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
