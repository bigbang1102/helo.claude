# Casebook — Excel gen (red ERP)

> สะสมความรู้ต่อเอกสาร · แปลงเสร็จทุกครั้งให้ append 1 แถวลงตาราง "เอกสารที่ทำแล้ว" + จด quirk ที่เจอ
> อ่านไฟล์นี้ก่อนเริ่มงานทุกครั้ง (Step 0 ของ [[awaken-excelgen]])

---

## เอกสารที่ทำแล้ว

| เอกสาร | module | BDNAME | items | สถานะ | quirk เด่น |
|---|---|---|---|---|---|
| `T-AD-Lead` | lead.lead | `LD` | Materialitem, Tradeitem, Activitystatusitem | ✅ ต้นแบบ (ทีมทำไว้ก่อน) | ใช้เป็นไฟล์อ้างอิงหลัก — โครงสร้าง new-style ครบทุก sheet |
| `T-AD-ContactActivity` | contactactivity | `CAC` | AttachItem (ตัวเดียว) | ✅ 2026-07-21 gen+deploy+แปลงภาษาครบ | item เดียวเป็น AttachItem → เจอบั๊ก `no-footer-tab` ของ UI (ดูด้านล่าง) |

**ยังไม่ได้แปลง**: เหลืออีก ~97 ไฟล์ใน `Transaction\` (ทำแล้ว 8 จาก 105)
ที่มีใน `new_Transaction\` แล้ว (ทีมอื่นทำ): `T-AD-Lead`, `T-MM-SerialnumberUpdate`, `T-PC-PO`, `T-PC-PR-OG-1`, `T-SD-Quotation_fixed_1_fixed`, `T-SD-Saleorder-test1`, `T-SUN-Form`

---

## BDNAME ที่รู้แล้ว

**ไม่มีสูตรตายตัว — ปนกันทั้งย่อและเต็ม ต้องถามหรือดูจากช่อง "ประเภทเอกสาร" ในจอ**

| เอกสาร | BDNAME |
|---|---|
| Lead | `LD` |
| ContactActivity | `CAC` |
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
