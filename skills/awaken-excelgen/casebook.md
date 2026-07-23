# Casebook — Excel gen (red ERP)

> สะสมความรู้ต่อเอกสาร · แปลงเสร็จทุกครั้งให้ append 1 แถวลงตาราง "เอกสารที่ทำแล้ว" + จด quirk ที่เจอ
> อ่านไฟล์นี้ก่อนเริ่มงานทุกครั้ง (Step 0 ของ [[awaken-excelgen]])

---

## เอกสารที่ทำแล้ว

| เอกสาร | module | BDNAME | items | สถานะ | quirk เด่น |
|---|---|---|---|---|---|
| `T-AD-Lead` | lead.lead | `LD` | Materialitem, Tradeitem, Activitystatusitem | ✅ ต้นแบบ (ทีมทำไว้ก่อน) | ใช้เป็นไฟล์อ้างอิงหลัก — โครงสร้าง new-style ครบทุก sheet |
| `T-AD-ContactActivity` | contactactivity | `CAC` | AttachItem (ตัวเดียว) | ✅ 2026-07-21 gen+deploy · 2026-07-22 เพิ่ม readonly+Form | readonly=flow_refdoctype,flow_refdocno,parent_refdoctype,parent_refdocno |
| `T-Formintent` (ใบเจตจำนง) | formintent.formintent | `CJ` | attachItem (ตัวเดียว) | 🟡 2026-07-21 แปลงเสร็จ รอ gen | **offset ไม่เหมือนไฟล์อื่น** · สูตร c31 มีถึงแถว 39 ต้องเติมเอง (ดูด้านล่าง) |

| `T-Formloan` (ใบขอใช้บริการนิติกรรมและสินเชื่อ) | formloan.formloan | `CA` | attachItem (ตัวเดียว) | 🟡 2026-07-21 แปลงเสร็จ รอ gen | **spec เหมือน Formintent 100%** — ใช้ `convert2.ps1` รันรอบเดียวจบ |
| `T-POS-POSDayend2` | posdayend.posdayend | `PDE` | 11 items | 🟡 2026-07-22 แปลงเสร็จ รอ gen | ใช้ NPOI โดยไม่เปิด Excel COM · 54 master fields (เพิ่ม businessentity) · adv=std+36, constrain=std−1, formula=std−2 · set_display 4 บล็อก |
| `T-AC-InputTax` (รายงานภาษีซื้อ) | inputtax.inputtax | `ITX` | InputtaxItem (คงลำดับเดิม) | 🟡 2026-07-23 แปลงเสร็จ รอ gen | Header 22 field · เพิ่ม businessentity · advance=std+23 และ constrain/formula/other=std · readonly ผ่าน displayattributeconf |

**ยังไม่ได้แปลง**: เหลืออีก ~95 ไฟล์ใน `Transaction\` (ทำแล้ว 10 จาก 105)

---

## 🚧 WORK-ORDER: T-POS-POSOutbounddelivery (POS OB) — BDNAME `POSOB` (2026-07-22 เริ่มวิเคราะห์)

**เอกสารใหญ่มาก (~10× ตระกูลเดิม)** · standard_usecase 944 แถว · advance 1173 แถว · module `posoutbounddelivery`

### offset (verified จาก .Formula)
`adv = std+36` · `constrain = std−1` · `formula = std−2` · `other = std+0`
⚠️ **`#field-subtab#` (adv c31) = `standard_usecase!M<r>` — col M (13) ไม่ใช่ col H!** (ต่างจากตระกูล Formintent) · master field-header ที่ adv R43, field แรก R44=std8

### 8 item blocks (adv row / #datakey-name#)
MaterialItem(153) · PromotionItem(231) · InvoiceItem(288) · SerialNumberItem(348) · PaymentItem(707) · ReturnPaymentItem(767) · ExpenseItem(946) · AttachItem(1006)

### target master 8 แท็บ (จาก spec sheet "POS OB")
1.ข้อมูลหลัก(ประเภทรายการ/การมอบหมาย/รายละเอียดเอกสาร) · 3.ข้อมูลคู่ค้า(ข้อมูลคู่ค้า/ตามใบกำกับภาษี) · 5.มูลค่า(ตามสกุลเงิน/ค่าใช้จ่าย) · 7.ข้อมูลผู้ใช้ · ***8.รายการส่งเสริมการขาย(3 subtab) · ***9.รายละเอียดPOS · ***10.ราคาทอง · ***12.ข้อมูลภายใน(ข้อมูลอ้างอิง/ข้อมูลอื่น)
default: txdate/refdocno/refdocdate/txno/status→document_category · REMARK→รายละเอียดเอกสาร · txtype→ข้อมูลอื่น

### ตัวช่วย (ผู้ใช้ชี้ให้)
`new_Transaction\T-FI-AR-newtab_prae.xls` = เอกสารใหญ่ new-style เสร็จแล้ว (adv 2084, ~18 item, set_display 215 แถว BDNAME AR1-AR7) = **แม่แบบ item + set_display**
`new_Transaction\T-FI-PurchaseTaxInvoice - Copy.xls` = ตัวช่วยที่ 2

### สถานะ 2026-07-22: **master reorder + set_display เสร็จ + verify สะอาด (#REF!=0)**
- spec จริง = `ERP_POS_OB_ChangeOB_FieldLayout_v1.xlsx` (sheet "Header OB" + "Item — <X>") · ตัวแรก (เรียงฟิลด์_V2) หยาบ/มั่ว ทิ้ง
- master 89 field เรียง 8 แท็บ/15 subtab (offset adv=std+36, con=std−1, frm=std−2, **subtab=col M(13)**) · default: currency→TXTYPE/TXNO/TXDATE/TXSTATUS · depstatus→REMARK · dayend_status→REFDOCNO/REFDOCDATE
- **มี merged cell ในคอลัมน์ noise (std 8-18) — ClearContents ตาย** → อย่า clear คอลัมน์ที่ adv ไม่อ้าง (adv ใช้แค่ A-G,M)
- **เจอสูตร adv c20 พังเดิมในเทมเพลต** 1 จุด (`formula!#REF!`) → ซ่อมชี้ `formula!$J<r−38>`
- set_display 4 บล็อค (133 cell) BDNAME POSOB · 8 item DeleteItemForm + Reference→Code · readonly 10 field · optionconf ***11/***12
- mechanic: snapshot(std A-G,M + con D/J + oth B/C + frm J + adv c30 desc keyed by fieldname) → clear → เขียนตาม target order · adv auto-update จาก std
- **item subtab (col M) ตั้งครบ 130 field ทั้ง 8 item** (parse posob_items.txt เป็น data, ASCII code only — Thai literal ในโค้ดทำ parser พัง!) · **ตั้ง col M แต่ไม่ reorder field → subtab อาจ fragment** (เช่น storagelocation ของ MaterialItem โผล่หลัง รายละเอียดสินค้า) → รอ gen พิสูจน์ว่า renderer group by subtab ไหม (ถ้า fragment ค่อย reorder item block)
- **#REF! = 0 ทั้ง advance 1173 แถว** · sheets ครบ 9 · caption source ตรง spec แล้ว (document_category="ประเภทงานเอกสาร") ไม่ต้องแก้
- ⛔ **2 spec ขัดกัน!** `เรียงฟิลด์_V2_grid_POS_v1` (spec 1, Google Sheet) vs `ERP_POS_OB_ChangeOB_FieldLayout_v1` (spec 2) เรียง master ต่างกันมาก → **user ยืนยันใช้ spec 1** (businessentity ขึ้นก่อน)
  - spec 1 master: businessentity(#1) → movementtype → document_category[+TXDATE/REFDOCNO/REFDOCDATE/TXNO/STATUS] · REMARK→status_stock · TXTYPE→external_refdocdate · 8 แท็บ (ข้อมูลผู้ใช้=tab7 ไม่ ***) · 4 *** tab (ส่งเสริม/รายละเอียดPOS/ราคาทอง/ภายใน)
  - **5 NEW field** ที่ต้อง add (spec1 มี, source ไม่มี): businessentity(Ref), init_type(Select:String/`NO,N\|YES,Y`), points_this_bill(int), rebate_list(Ref/rebate), businesspartner_signature(Upload — เดา, ไม่มีตัวอย่างยืนยัน) · type ดูจากตัวอย่าง AR/PurchaseTaxInvoice
  - mechanic redo: snapshot master จาก **source ต้นฉบับ** (ได้ field ครบ) + เพิ่ม NEW จาก newfields.tsv → เขียนลงไฟล์ปัจจุบัน (item col M ไม่หาย เพราะ reorder แตะแค่ std 8-115) · item (grid+col M) ใช้ spec 2 detailed เหมือนเดิม
  - set_display blocks 1/2 (item) = spec 2 · blocks 3/4 (readonly+optionconf) = spec 1 (readonly มี init_type · optionconf 4 tab)
- **สถานะ: GEN-READY (spec 1)** — 92 field · #REF!=0 · verify PASS · ไฟล์: `new_Transaction\T-POS-POSOutbounddelivery.xls`
- ⚠️ หลัง gen: เช็ค `businessdocumentextend\posoutbounddelivery\*.xml` บน 172 read-only + admin Show (root cause Formloan) · ทาง A = gen แล้วดู item-form fragment ไหม

---

## 🧩 ตระกูล "ฟอร์มเปล่า + AttachItem" — ใช้สคริปต์เดียวได้

`T-Formintent` · `T-Formloan` (และน่าจะมีอีก) — **ไฟล์ต้นฉบับขนาดเท่ากันเป๊ะ 284,160 bytes = แม่แบบเดียวกัน**

| เหมือนกันทุกอย่าง | ค่า |
|---|---|
| master fields เดิม | 10 ตัว (cus_code … role_owner) |
| offset | adv=std+22 · constrain=std−1 · formula=std−2 · other=std+0 |
| c31 มีสูตรถึงแถว | 39 (ต้องเติม 40–42) |
| item | `attachItem` → attachfile, description |
| spec ปลายทาง | 13 field, 2 tab (ข้อมูลหลัก + ***ข้อมูลภายใน), 3 subtab |

**เจอไฟล์ 284,160 bytes ใน `Transaction\` = ใช้สูตรเดียวกันได้เลย** แต่ **ยังต้องรัน offset guard เสมอ** (ดู `convert2.ps1` — throw ถ้า `adv c7/c8/c20` ไม่ตรง)

`convert2.ps1 -Target <path> [-Bdname XX]` ทำครบในรอบเดียว: reset+เขียน std · constrain/other · adv literals · เติม c31 เท่าจำนวน field จริง · สร้าง set_display + Sheet1 · print post-check

### ⚠️ `#new-line#` — ตระกูลนี้ต้องใส่ที่ `exists_txno` (บั๊กจริง 2026-07-21)
spec ข้อมูลอ้างอิง: **บรรทัด1 = flow_refdoctype, flow_refdocno (2 field)** · **บรรทัด2 = exists_txno, parent_role_owner, role_owner (3 field)**
ระบบ auto-wrap ที่ ~4 field/บรรทัด → ถ้าไม่ใส่ `#new-line#` จะได้ 4+2 (flow/flow/exists/parent บรรทัดเดียว, role+txType บรรทัดถัดไป) **ไม่ตรง spec**
→ ต้องใส่ **`#new-line# = true`** (adv col 22, เป็น **literal** ไม่ใช่สูตร · ค่า `true` ตัวเล็ก · DB คอลัมน์ `add_newline`) ที่ **`exists_txno`**
บังคับให้ขึ้นบรรทัด 2 = `exists_txno | parent_role_owner | role_owner | [ประเภทเอกสาร]` ตรง spec
**ใส่ใน `adv.tsv` (`40 22 true`) แล้ว** → convert2 รอบหน้าได้เลย · Formintent+Formloan แก้ย้อนหลังแล้ว
**การอ่าน spec**: บรรทัด spec ที่ field แรกไม่ใช่ตัวเริ่ม subtab และ auto-wrap จะไม่ break ตรงนั้น → ต้องมาร์ค `#new-line#` เอง

### ⛔⛔ ROOT CAUSE จริง "field หน้าข้อมูลภายในไม่แสดง" (Formloan 2026-07-22) — 3 เรื่อง
เคส Formloan: จอแสดง ข้อมูลอ้างอิง แค่ 4 (flow/flow/exists/txType) role_owner+parent_role_owner หาย
ผมสืบผิดทาง — ไล่ DB 137 + ไฟล์ 233 (ครบหมด) แล้วสรุปผิดว่า "deploy เก่า" **แต่ user เจอเองว่าต้นเหตุคือ 3 เรื่องนี้**:

**1. config การแสดง field อยู่ที่เครื่อง gen (172) และไฟล์ read-only**
จออ่าน field-display จาก `businessdocumentextend\<module>\<Doc>.xml` บน **192.168.24.172**
(`D:\red\jboss3\server\product\deploy\red.ear\conf\red\workflow\businessdocumentextend\formloan\Formloan.xml`)
ไฟล์ **read-only** → gen ทับไม่ได้ → ค้างของเก่า → **จอไม่เปลี่ยนแม้ DB 137 + ไฟล์ 233 ถูกครบ** (ผมไล่ผิดเครื่องทั้งเซสชัน)
แก้: เอา read-only ออก (2 ที่บน 172) + ตั้ง field เป็น **Show** ที่ admin `http://192.168.24.172:8080/admin/control/` → จัดการ Business Document → **Bussiness Document Management** → เลือกเอกสาร → ตั้ง Not Use/Hide/**Show**

**2. `wfdisplayitemsubtab` ITEM_TABNAME ต้อง `DeleteItemForm<X>` (Form ไม่ใช่ From)**
sd.tsv เดิมเขียน `DeleteItemFromAttachItem` (From) ผิด → user แก้ DB From→Form หมดแล้ว · **sd.tsv แก้แล้ว**

**3. set_display ต้องมีบล็อค `wfdisplay_displayattributeconf`** — field หน้าข้อมูลภายในตั้ง readonly ทุกตัว
`<BDNAME> | master | readonly | flow_refdoctype,flow_refdocno,exists_txno,parent_role_owner,role_owner`
**sd.tsv เพิ่มบล็อคนี้แล้ว** (user เพิ่มใน T-Formloan.xls เองแล้ว — อย่าไปทับ)

**บทเรียน: field หน้าข้อมูลภายในไม่แสดง → เช็คไฟล์ businessdocumentextend บนเครื่อง gen (172) + read-only + admin Show ก่อน** อย่าเสียเวลาไล่ DB/ไฟล์ปลายทาง
ที่มีใน `new_Transaction\` แล้ว (ทีมอื่นทำ): `T-AD-Lead`, `T-MM-SerialnumberUpdate`, `T-PC-PO`, `T-PC-PR-OG-1`, `T-SD-Quotation_fixed_1_fixed`, `T-SD-Saleorder-test1`, `T-SUN-Form`

---

## BDNAME ที่รู้แล้ว

**ไม่มีสูตรตายตัว — ปนกันทั้งย่อและเต็ม ต้องถามหรือดูจากช่อง "ประเภทเอกสาร" ในจอ**

| เอกสาร | BDNAME |
|---|---|
| Lead | `LD` |
| ContactActivity | `CAC` |
| Formintent (ใบเจตจำนง) | `CJ` |
| Formloan (ใบขอใช้บริการนิติกรรมและสินเชื่อ) | `CA` |
| PO | `PO` |
| PR / PRI | `PR` / `PRI` |
| Quotation | `quotation` |
| GRAssets (grassets) | `ASP` |
| SerialnumberUpdate | (เว้นว่างใน set_display) |

จากตาราง `wfdisplayitemdisplaytab` ยังเห็น: `AP1-7`, `AR1-7`, `DE`, `GI`, `GL`, `GLTX`, `OB`, `OB5`, `PV`, `RV`, `SO`, `employee`

---

## เคส: T-AD-ContactActivity (2026-07-21)

### สิ่งที่แปลง
- **จัด tab ใหม่**: ข้อมูลทั่วไป/ข้อมูลการสื่อสาร/รายละเอียดการติดต่อ → **ข้อมูลหลัก + ข้อมูลผู้ใช้ + ข้อมูลภายใน**
- **subtab**: ประเภทรายการ · ข้อมูลการสื่อสาร · รายละเอียดการติดต่อ · ข้อมูลผู้ใช้ · ข้อมูลอ้างอิง
- **เพิ่ม field ใหม่** `businessentity` (นิติบุคคล) บนสุด — ไม่มีในไฟล์เดิม
- **`#default-field#`**: `document_category` ← TXDATE,TXNO,STATUS,REFDOCNO,REFDOCDATE · `next_step` ← REMARK · `parent_refdocno` ← TXTYPE
- **`#is-config-field#` = TRUE**: `businessentity`, `movementtype` (ตามที่ user สั่ง)
- **Item AttachItem** เรียงใหม่: attachfiletype → attachfilegroup → attachfile → description
- รวม 47 field (เดิม 46 + businessentity)

### ผลตรวจ (compare old vs new ทีละ field)
```
OLD fields=50   NEW fields=51
fields หาย: (ไม่มี)   ·   fields เพิ่ม: businessentity
marker ต่าง: (ไม่มี) — require/svc/report/class/module-ref/calculate/description ตามไปครบ
```

### quirk ที่เจอ
1. **spec ไม่มีบล็อค "ข้อมูลอื่น"** → ลืมวาง `TXTYPE` → หลัง gen มี **แท็บ "เอกสาร" เกินมา 1 แท็บ**
   แก้โดยใส่ `:SUFFIX:TXTYPE` ที่ `parent_refdocno` (เลียนแบบ Lead)
2. **สูตร `#field-subtab#` (adv c31) มีถึงแถว 89 เท่านั้น** — พอเพิ่ม field เป็น 47 ตัวจนใช้แถว 90 ต้องเติม `=standard_usecase!H54` เอง
3. **แท็บ item ไม่แสดง** — ไม่ใช่ความผิดของงานแปลง (ดูหัวข้อถัดไป)

---

## เคส: T-Formintent (2026-07-21)

### ⛔ บทเรียนใหญ่ที่สุด — **offset ของแต่ละไฟล์ไม่เหมือนกัน ห้ามใช้ค่าจากเคสก่อน**

| ไฟล์ | master std rows | adv | constrain | formula | other | item std |
|---|---|---|---|---|---|---|
| `T-AD-ContactActivity` | 8–53 | std+36 | std+0 | std+0 | std+0 | 96–99 |
| `T-Formintent` | 8–67 | **std+22** | **std−1** | **std−2** | std+0 | 71–72 |

**วิธีหา offset ที่ถูกต้อง**: อ่าน `.Formula` (ไม่ใช่ `.Text`) ของ advance แถวแรกแล้วดูว่ามันชี้ไปแถวไหน
`c7 = IF(constrain!$D7=…)` · `c20 = IF(formula!$J6=…)` · `c8 = IF(other!B8=…)` → ได้ offset ครบทุกแผ่นในบรรทัดเดียว

### สิ่งที่แปลง
- 10 field เดิม → **13 field** (เพิ่ม `businessentity` `movementtype` `document_category` ก็อป definition จาก CAC ครบทุกแผ่น)
- tab: ข้อมูลเอกสาร/ข้อมูลอ้างอิง → **ข้อมูลหลัก (General) + ***ข้อมูลภายใน (Internal)**
- subtab: ประเภทรายการ · รายละเอียดเอกสาร · ข้อมูลอ้างอิง
- `#default-field#`: `document_category` ← TXDATE,TXNO,STATUS,REFDOCNO,REFDOCDATE · `description` ← REMARK · `role_owner` ← **TXTYPE**
- `#is-config-field#` TRUE: `businessentity`, `movementtype`
- item `attachItem` (attachfile → description) **ลำดับตรง spec อยู่แล้ว ไม่ต้องแก้**
- สร้าง `set_display` (BDNAME=`CJ`) + `Sheet1`

### quirk
1. **สูตร `#field-subtab#` (adv c31) มีถึงแถว 39 เท่านั้น** (ไฟล์เดิมมี 10 field) — เพิ่มเป็น 13 field ต้องเติม `=standard_usecase!H<r−22>` ให้แถว 40–42 เอง
   **ตรวจเจอเพราะ verify หลังแปลง** — คอลัมน์อื่น (c1–c21, c30) มีสูตรครบถึงแถว 89 มีแต่ c31 ที่ขาด → อย่าเชื่อว่าสูตรทุกคอลัมน์ยาวเท่ากัน
2. เติมสูตร c31 ยาวเกินจำนวน field จริง → แถวว่างโชว์ `0` ต้อง `ClearContents` แถวที่ไม่ได้ใช้
3. **⛔ `#is-config-field#` ไม่ลง DB เพราะเขียนเป็นสูตร** — ผมเขียน `.Formula='=TRUE'` ตามที่ skill เคยระบุผิด → `info_icon` ใน `wfdisplay_displaymasterconf` **ว่างหมด** ปุ่ม ⓘ ไม่ขึ้น
   เทียบ CAC: `info_icon=[true]` ครบ 3 ตัวแรก · formintent: `[]` ทั้งหมด
   **ต้องใช้ `.Value2 = $true`** ให้ `.Formula` อ่านได้เป็น `TRUE` (ไม่มี `=`) เหมือนต้นแบบ Lead/CAC → แก้ SKILL.md แล้ว
4. **caption ผิดเพราะก็อปจากเคสก่อนแทนที่จะอ่าน spec** — `document_category` ใน CAC = "ประเภทงานเอกสาร" แต่ spec Formintent เขียน **"ประเภทรายการย่อย"**
   caption **ไม่ได้อยู่ใน DB** อยู่ใน `webinterface.xml` (`fieldcaption=`) และมี **2 ไฟล์** (ตัวหลัก + `quick\`)
   → เวลาก็อป definition field จากเอกสารอื่น ให้ก็อปแค่ `ชนิดข้อมูล/ref/marker` ส่วน **caption ต้องอ่านจาก spec เสมอ**
5. **BDNAME หาจาก DB ไม่ได้** — `wfdisplay_displaymasterconf` มี module `formintent` แล้ว (เคย gen) แต่ `wfdisplayitemdisplaytab` ไม่มีแถวเลย → ต้องถาม user (คำตอบ: `CJ`)
   วิธีเช็คว่า BDNAME ชนของคนอื่นไหม: `SELECT DISTINCT bdname FROM wfdisplayitemdisplaytab` ก่อนใส่ `#delete-bdname-list#`

---

## 🐛 บั๊ก UI: แท็บ item ไม่แสดง (`no-footer-tab`)

**อาการ**: header เปลี่ยนถูกทุกอย่าง แต่พื้นที่แท็บ item ด้านล่างว่างเปล่า

**ต้นเหตุ** — `red.war\WEB-INF\jsp\util\display\header_master.jsp:4139-4146`
```js
var earlyFtList = d.getElementById('allFooterTabList');
if (earlyFtList && earlyFtList.querySelectorAll('td[onclick*="setSwapActiveTab"]').length === 0) {
  d.body.classList.add('no-footer-tab');
  var ftDivs = d.querySelectorAll('[id$="_footerTabDiv"]');
  for (var fi = 0; fi < ftDivs.length; fi++) ftDivs[fi].style.display = 'none';
}
```
`allFooterTabList` ถูกเรนเดอร์ว่างจาก `maincontroller.jsp:1643` แล้วให้ JS เติมปุ่มแท็บทีหลัง —
ถ้าไม่มีปุ่มถูกเติมเลย โค้ดนี้จะสรุปว่า "หน้านี้ไม่มีแท็บล่าง" แล้วซ่อน `_footerTabDiv` ทั้งหมด
→ nitobi grid ข้างในถูกสร้างสำเร็จ (`initGrid Success`) แต่วัดขนาดตอนถูกซ่อนได้ `width:0 height:0` ค้าง

**อีกจุดที่ใส่ class เดียวกัน**: `header_master.jsp` ~5475 (ใน `updateTabActive`) — ต้องแก้ทั้งคู่

**patch ที่เสนอ** (user นำไปแก้แล้วได้ผล): เพิ่มเงื่อนไขว่าถ้ามี grid ของ item อยู่จริงอย่าใส่ `no-footer-tab`
```js
var ftGrids = d.querySelectorAll('[id$="_footerTabDiv"] div[id^="gridDeleteItemForm"]');
if (ftBtnCount === 0 && ftGrids.length === 0) { /* ซ่อนตามเดิม */ }
else if (ftBtnCount === 0 && ftGrids.length > 0) { /* เปิดโชว์ item area เลย */ }
```

**พิสูจน์ได้ด้วย console** (ปลดซ่อนสดๆ แล้วตารางโผล่ครบ):
```js
f.d.body.classList.remove('no-footer-tab');
ftDiv.style.cssText += ';display:block !important;visibility:visible !important;height:auto !important;';
grid.style.width = '1228px';  // nitobi จำขนาดตอนซ่อนไว้ ต้อง set เอง
```

**ตารางที่ตรวจแล้วไม่ใช่สาเหตุ — อย่าไล่ซ้ำ**
`wfdisplayitemdisplaytab` (LD/ASP ไม่มีแถวแต่แสดงได้ · ใส่แถว CAC แล้วก็ยังไม่ขึ้น) · `wfdisplayitemsubtab` (0 แถวทั้ง DB) · `wfdisplayitemmode` (20 แถวทั้ง DB, LD/ASP ไม่มี) · `wfdisplay_displaytabconf` (register ครบแล้ว) · `displayoptionconf` / `displayattributeconf` (0 แถว)

---

## Module patterns

### แท็บมาตรฐาน new-style (จาก Lead + ContactActivity)
```
1. ข้อมูลหลัก      (General / Communicate / Contact / Target_Data …)
7. ข้อมูลผู้ใช้     (User info)   ← user_owner, role_owner, createby, createtime, user_destination, role_destination
***12. ข้อมูลภายใน (internal)     ← flow_refdoctype, flow_refdocno, parent_refdoctype, parent_refdocno
                                     subtab = ข้อมูลอ้างอิง · `***` = extend-master
```

### field ชุดมาตรฐานที่ย้ายเข้า tab เฉพาะเสมอ
- **ข้อมูลผู้ใช้**: `user_owner, role_owner, createby, createtime, user_destination, role_destination`
- **ข้อมูลภายใน / ข้อมูลอ้างอิง**: `flow_refdoctype, flow_refdocno, parent_refdoctype, parent_refdocno`
- **ประเภทรายการ (subtab แรกของข้อมูลหลัก)**: `businessentity, movementtype, document_category`

### default-field 7 ตัว — ที่วางบ่อย
| default-field | มักแปะกับ |
|---|---|
| TXDATE, TXNO, STATUS, REFDOCNO, REFDOCDATE | `document_category` |
| REMARK | field สุดท้ายของ subtab รายละเอียด (Lead=`employee` · CAC=`next_step`) |
| TXTYPE | `parent_refdocno` (ตัวสุดท้ายของข้อมูลอ้างอิง) |

### AttachItem
- ระบบมีโค้ดจัดการแยก: `EBAGrid.jsp` (`btn_add_attach`, `saveUploadAttachItem`), `ebaUpdateUpload.jsp` (insert เข้า `<req><req>attachitem` ตรงๆ)
- แท็บ `Attachment` ที่ panel ขวาเป็น**ตัวอัปโหลดไฟล์ทั่วไป** ไม่ได้แสดง 4 field ของ AttachItem → ใช้แทนกันไม่ได้
- เอกสารที่ระบุ AttachItem ใน `wfdisplayitemdisplaytab` แล้วแสดงได้: `PR`, `PRI`, `DE`, `GI`, `GL`, `AR1-7`, `OB`, `RV`, `SO`

---

## เอกสารที่ใช้เทียบได้ (reference)

| เอกสาร | ใช้ดูอะไร |
|---|---|
| `T-AD-Lead` | โครงสร้าง new-style ครบทุก sheet · set_display 4 บล็อค · Sheet1 21 คอลัมน์ |
| `grassets` (ASP) | เอกสารที่มี item หลายตัวรวม AttachItem · master 7 page |
| `PR` / `PRI` | ตัวอย่าง `wfdisplayitemdisplaytab` ที่ระบุ AttachItem แล้วแสดงได้ |

---

## เคส: T-POS-POSDayend2 (POS DayEnd, 2026-07-22)

- BDNAME: `PDE` · module: `posdayend.posdayend`
- layout: sheet `Dayend` ใน `เรียงฟิลด์_V2_grid_POS_v1 .xlsx`
- master: 53 field เดิม → 54 field (เพิ่ม `businessentity`) · default-field ครบ 7 ตัว
- offset verified: advance=standard+36 · constrain=standard−1 · formula=standard−2 · other=standard · field-subtab ใช้ standard col M
- items เดิม 11 ชุด ไม่เรียงใหม่ · สร้าง `set_display` ครบ 4 บล็อกและ `Sheet1` 21 คอลัมน์
- วิธีเขียน: NPOI 2.4.1 อ่าน/เขียน BIFF `.xls` โดยตรง ไม่เปิด Excel COM จึงทำคู่ขนานกับงาน POS OB ได้
- verify: สูตร 19,628 เซลล์คงเดิม · `#REF!` baseline 74 สูตรไม่เพิ่ม · marker ราย field ตรงต้นฉบับ · NPOI และ xlrd เปิดไฟล์ผลลัพธ์ได้
- correction 2026-07-22: การต่อ `DeleteItemForm` + item name ใน PowerShell ต้องครอบวงเล็บ มิฉะนั้นถูกแยกเป็น 2 คอลัมน์และ gen ทิ้งทั้งบล็อก `set_display`; item block ต้องใช้ metadata slot จริง (AttachItem อยู่ slot 15 มี `none` คั่น) ห้ามใช้ลำดับที่บีบแล้ว
- correction 2026-07-22: ต้นฉบับมี external link หลงที่ `other!A155` ไป `[T-PC-PR.xls]standard_usecase!A151`; แก้ตามลำดับข้างเคียงเป็น local `standard_usecase!A156` แล้ว external links เหลือ 0
- correction 2026-07-22: หลัง reorder ต้อง recalc cached formula ของ master ทั้งช่วง standard rows 8–102 รวมแถวสำรอง ไม่ใช่เฉพาะ 54 field ที่ใช้งาน มิฉะนั้น redTools อ่าน cached field เก่าใน advance rows 98+ แล้วแจ้ง Field Duplicate
- correction 2026-07-23 (ระบบใหม่): static readonly ให้ใช้ `wfdisplay_displayattributeconf` เป็นหลัก ไม่ใช่ `wfinputvalidationitem`; Excel กำหนดแถวเดียวกันจาก sheet `set_display`
- รูปแบบที่ยืนยันกับ CJ และ UI จริง: `BDNAME=CJ`, `ITEM_NAME=master`, `ATTRIBUTE_TYPE=readonly`, `FIELDLIST=flow_refdoctype,flow_refdocno,exists_txno,parent_role_owner,role_owner`
- การแก้ DB ใน `wfdisplay_displayattributeconf` มีผลโดยไม่ต้อง Generate Excel ใหม่ แต่ต้องแก้ `set_display` ในไฟล์ให้ตรงด้วย มิฉะนั้น Generate ครั้งถัดไปอาจเขียนทับ
- ข้อมูลเดิมเรื่อง PDE validation ID `20627` เก็บเป็นหลักฐาน legacy/fallback เท่านั้น ไม่ใช้เป็นคำแนะนำหลักสำหรับ static readonly ของระบบใหม่
- `STATUS` มาจาก `document_category` ผ่าน `:SUFFIX:STATUS` เป็น system/default field ต้องตรวจแยกจาก master `FIELDLIST`
- สถานะ: แปลงและ Generate แล้ว; แนวทาง readonly ถูกปรับตามระบบใหม่และผล UI ที่ user ยืนยัน

## correction: T-Formintent / CJ static readonly (2026-07-23)

- ระบบใหม่อ่าน readonly หลักจาก `wfdisplay_displayattributeconf`
- แถวที่ถูกต้อง: `CJ | master | readonly | flow_refdoctype,flow_refdocno,exists_txno,parent_role_owner,role_owner`
- ไม่ต้องสร้าง `wfinputvalidation`/`wfinputvalidationitem` สำหรับ readonly แบบคงที่ชุดนี้
- ถ้าเคยใส่ซ้ำใน `wfinputvalidationitem` ต้องระวังสองแหล่งคุมพร้อมกัน; การเอา field ออกจาก attribute table อย่างเดียวอาจยังไม่ทำให้กลับมา editable

## เคส: T-AC-InputTax / ITX (รายงานภาษีซื้อ, 2026-07-23)

- source: `Transaction\T-AC-InputTax.xls` · output: `new_Transaction\T-AC-InputTax.xls`
- layout: `InputTax.xlsx` sheet `InputTax`; user กำหนดให้เรียงเฉพาะ Header และคง Item ด้านล่างตามต้นฉบับ
- Header เดิม 21 field → 22 field โดยเพิ่ม `businessentity`; ลำดับ: ประเภทรายการ 3 → รายการภาษีซื้อ 8 → ข้อมูลผู้ใช้ 6 → ข้อมูลภายใน 5
- default-field ครบ 7: `document_category` รับ TXDATE/TXNO/STATUS/REFDOCNO/REFDOCDATE · `prohibit_vat` รับ REMARK · `parent_refdocno` รับ TXTYPE
- new-line ตามแบบ 4 คอลัมน์: `vat_amount`, `user_destination`, `parent_refdoctype`
- offset เฉพาะไฟล์นี้: advance master row = standard row +23; constrain/formula/other ใช้ row เดียวกับ standard
- Item `InputtaxItem` ตั้งแต่ source standard row 36 เป็นต้นไปคงค่า สูตร และ style เดิมทุกเซลล์; `vendor` เป็น Reference จึงใช้ `vendorCode` ใน SHOW_FIELDLIST
- `set_display` 4 บล็อก, BDNAME `ITX`; static readonly ระบบใหม่: `init_type,flow_refdoctype,flow_refdocno,parent_refdoctype,parent_refdocno`
- verify: master 22 · default 7 · Item areas identical · formulas 1,275 · `#REF!` 0 · external links 0 · NPOI และ xlrd เปิดไฟล์ได้
- correction 2026-07-23: ITX `advance_usecase` c31 อ่าน `standard_usecase!H<row>` ไม่ใช่ col M; เขียน subtab ผิดคอลัมน์ทำให้ `wfdisplay_displaymasterconf.field_subtab` สลับกลุ่ม แต่การแก้ H แก้เฉพาะ Header และยังไม่ทำให้ Item แสดง
- root cause ของ Item ไม่แสดง: สูตร source ที่ advance row 22/23 เขียนผิดเป็น `LOWER(standard_usecase!B34<>"none")` และ `LOWER(standard_usecase!B51<>"none")` ซึ่งเอา Boolean ไป LOWER ทำให้ cached marker/table ว่าง; redTools จึงไม่สร้าง `<form name="DeleteItemFormInputtaxItem">`
- สูตรที่ถูกต้องต้องเป็น `LOWER(standard_usecase!B34)<>"none"`; slot 1 ต้องได้ cache `#dependent-table#` และ `INPUTTAXINPUTTAXITEM_TABLE` ส่วน slot 2 (`none`) ต้องว่าง
- หลักฐาน UAT ก่อนแก้: `wfdisplayitemdisplaytab`/`wfdisplayitemsubtab` มี config, เอกสารมี item จริง 5 แถว แต่ XML หลัง Gen เวลา 11:13 มีเพียง script อ้าง `DeleteItemFormInputtaxItem` และไม่มี form/pattern ของ item; server log เวลา 11:15 พบ `sharedweb is null`
- verifier ต้องตรวจทั้งค่า standard col H และสูตร adv c31 ว่าอ้าง H ของ field เดียวกัน ห้ามตรวจคอลัมน์ที่ตัว converter เขียนเองเพียงจุดเดียว
- verifier ต้องตรวจ dependent-table marker + table name cache ด้วย; การเทียบ Item cells ว่าเหมือน source อย่างเดียวไม่พอ เพราะ source อาจมีสูตรผิดอยู่แล้ว
- correction 2026-07-23 (Header layout): `#new-line#=true` ตัดหลัง field ไม่ใช่บังคับให้ field นั้นเริ่มแถวใหม่; ค่าเดิมที่ `vat_amount`, `user_destination`, `parent_refdoctype` ทำให้หน้าแตกเป็น 1+4 และ 1+1
- แบบ ITX ใช้ natural wrap 4 คอลัมน์ทั้งหมด จึงล้าง forced newline ของ Header ทั้ง 22 field
- system/default fields ของ subtab ประเภทรายการต้องเรียง `TXDATE,REFDOCNO,REFDOCDATE,TXNO,STATUS` เพื่อให้แถวแรกเป็น businessentity/movementtype/document_category/วันที่เอกสาร และแถวสองเป็นเลขอ้างอิง/วันที่อ้างอิง/เลขที่เอกสาร/สถานะ
- การแก้ Header รอบนี้ patch บนไฟล์ล่าสุดที่ Item แสดงได้ ห้าม rebuild จาก source เก่า เพราะจะทับ metadata Item ที่แก้แล้ว
