---
name: awaken-report
description: "แก้/เปิดใช้งานรายงาน (report) ในระบบ red ERP (wildfly2 / red-erp-wildfly) — เปิดไม่ได้, drilldown, print, chip filter, jasper. Playbook + casebook สะสมความรู้ต่อรายงาน. Trigger: /awaken-report, 'แก้รายงาน', 'รายงานเปิดไม่ได้', 'drilldown', 'ทำ report ...', ชื่อ report code เช่น AC-B11-0 PC-A01-0 SD-A01-0 MM-B01-0 AR-A01-0 AP-A01-0. ใช้เฉพาะงาน REPORT — งาน form ใช้ /awaken-form."
installer: create-shortcut
created_at: 2026-07-12T16:54:23+07:00
created_session: a4528efe
---

# /aweken-report — Playbook แก้รายงาน red ERP

Skill สำหรับงาน **report เท่านั้น** ในระบบ red ERP (JSP + JasperReports + acedrilldown.war).
โครงคงที่อยู่ในไฟล์นี้ · ความรู้ต่อรายงาน (alias/quirk/สถานะ) สะสมใน **`casebook.md`** (ข้างไฟล์นี้).

> ปรัชญา: รายงานเป็นร้อยแต่ pattern ซ้ำ ~90% → เดินตาม checklist + เปิด casebook เช็กก่อน + จดสิ่งใหม่ทุกครั้ง

## Step 0: Init (เริ่มทุกครั้ง)
```bash
date "+🕐 %H:%M %Z (%A %d %B %Y)" && cat "$HOME/.Codex/skills/awaken-report/casebook.md" 2>/dev/null | head -60
```
อ่าน casebook ก่อน — ถ้ารายงานที่จะทำ (หรือพี่น้องในโมดูลเดียวกัน) เคยทำแล้ว จะรู้ alias/quirk ทันที ไม่ต้องลอกหัวหอมใหม่

## สภาพแวดล้อม (จำไว้)
- **source repo**: `C:\git\wildfly2` (แก้โค้ดที่นี่)
- **deploy path**: `C:\git\red-erp-wildfly\...\redjaka.ear\red.war\` หรือ `E:\redr2_uat\...\red.war\` — **server รันจาก deploy ไม่ใช่ repo** → แก้แล้วต้อง copy ไป deploy เสมอ
- server เทสต์: acedemo.acecloud.co.th:52333
- drilldown = webapp แยก `acedrilldown.war` (DB pool แยก) endpoint ใหม่ `drilldown_new.jsp` (เก่า `drilldown.jsp`)
- config drilldown อยู่ใน **DB**: `wfdrilldownreport` (level1/2/3, drilldowntype, HeaderCaption, KeyValues) + `wfdownloadexcel` (EXPRESSION=SQL, PARAMETERFIELDNAME=param required) — **นอก version control**

## Workflow — checklist ต่อรายงาน
เจอรายงานเปิดไม่ได้/แก้รายงาน ทำตามนี้ (เทียบกับ `.bak-broken-*` ของไฟล์นั้นเสมอ — มันคือเวอร์ชันที่เคยทำงานได้):

1. **filePath ชี้ jasper จริงไหม** — `String filePath = ".../XXX"` ต้องตรงกับ `.jasper` ที่มีจริง (มักเป็น `<report-code>` ไม่ใช่ชื่อ generic เช่น report_wht/output_tax_listing) → เช็ก `report-function-new.jsp` ใช้ `<filePath>.jasper` เป็น reportFileName
2. **reportName mojibake ไหม** — ไทยเพี้ยน (`รา§าน`, `㺹ำ`) → เอาค่าถูกจาก `.bak-broken`
3. **alias ตรง query ไหม** — `externalSQLWhere()` ต้องใช้ alias เดียวกับที่ jasper query FROM (itx/otx/wf/wht/a/sum/wght...) → **ดูจาก `.bak-broken`** อย่าเดา (ผิด alias = "Unknown column X.y")
4. **section filter หายไหม** — ถ้า include `section-document-type.jsp` (หายทั้ง repo+deploy!) กล่อง filter จะว่างเปล่า → แทนด้วย **flat `reference-data-no-adv`** ห่อ `rp-sec` (ดู casebook แม่แบบ)
5. **drilldown**:
   - เช็ก DB `wfdrilldownreport WHERE level1 LIKE '<code>%'` มี config ไหม
   - **มี** → `drilldownReport()` submit ไป `drilldown_new.jsp`, `reportsqlCode` = ดู `wfdrilldownreport.level1` (บางตัวมี `_drilldown` บางตัวไม่มี — ห้ามเดา)
   - **ไม่มี** (print-only) → `drilldownReport()` fallback `viewReport('view')` (ปุ่ม "เรียกดู" hardcode เรียก `drilldownReport()` เสมอ ทุกรายงานต้องมี ไม่งั้น "drilldownReport is not defined")
6. **required params** — `wfdownloadexcel.PARAMETERFIELDNAME` list ไว้ (เช่น sort_order1,sort_order2,ExternalWhereClause) ถ้า redesign ตัด section ที่สร้าง field นั้นออก → สร้าง hidden + default (`txdate`/`status`) ไม่งั้น "Following parameters is required"
7. **jrxml (ถ้าแก้ .jrxml)**:
   - ORDER BY ต้องใช้ **computed `sort_field1/2`** ไม่ใช่ `$P!{sort_order1}` ดิบ (ค่าแปลกจาก print dialog เช่น `movcode` ทำ crash)
   - label textField ที่เช็ก `.equals("movementtypecode")` ต้องรับค่าที่ dialog ส่งจริงด้วย (เช่น `movcode`)
   - **แก้ .jrxml แล้วต้อง recompile → .jasper** (หน้า render จาก .jasper)
8. **chip filter** — `drilldownReport()` ต้อง ensureFieldInsideForm(`disp_*Code`, `filter_*`) + capture `_badges_<refName>` จาก `_dd_trigger`; date chip เติม `filter_month/filter_year` (month/year report) หรือ ensure `filter_fromdate/todate` (date-range) → `filter-badges.js` อ่าน
9. **ย้าย hidden เข้า form** — template ปิด `</form>` ก่อน → `ensureFieldInsideForm(id)` ทุก field ก่อน submit (ไม่งั้น drilldown ได้ค่าว่าง/หน้าเปล่า)
10. **ยอดรวมท้ายตาราง drilldown (`level1_filtersummary`)** — ก่อนใส่ field ใดๆ เข้า list นี้ ให้ถามก่อนว่า field นั้นเป็นค่า flow ต่อรายการ (sum ตรงๆ ได้ปกติ) หรือเป็นค่าสะสม/ratio (running balance, ราคาต่อหน่วย) ที่ sum ข้ามแถวไม่มีความหมาย ถ้าเป็นแบบหลัง: ราคาต่อหน่วย/ratio → **ห้ามใส่เข้า filtersummary เลย**, running balance (เช่น `balance_amount`) → ใส่ได้เพราะ `getsumary()` ใน `assets/js/index.js` รองรับแล้ว (ดู `RUNNING_BALANCE_FIELDS` array — sum แบบ "เอาแถวสุดท้ายต่อกลุ่ม materialcode มาบวกกัน" ไม่ใช่ sum ทุกแถว) เทียบผลกับยอดรวมใน PDF (jasper `resetType="Group"` variable) เสมอ ถ้าไม่ตรงกันแปลว่ายังมี field ที่ sum ผิดวิธีอยู่ · field ตัวแรกใน filtersummary list จะถูกบังคับเป็น label "ยอดรวม" เสมอ (ไม่ sum) — เลือก text field ไม่ใช่ field ตัวเลขที่อยากได้ยอดจริง

## ⚠️ Gotchas (กฎเหล็ก — เจอบ่อย เสียเวลาถ้าลืม)
1. **error ที่โค้ด repo ดู safe แต่ยัง crash = deploy≠repo → ขอ console stack trace ทันที** อย่าไล่ static เกิน 2 รอบ (เวอร์ชัน inline บน deploy อาจไม่มี null-guard เหมือน repo)
2. **อย่า assert ว่าไฟล์อยู่บน deploy จากการที่หลายที่อ้างถึง — verify ก่อน** (เช่น section-document-type.jsp หายจริงทั้ง repo+deploy ทั้งที่ 105 รายงานอ้าง)
3. **ก่อน blank/ลบค่า hidden field ที่มีอยู่ → grep หาผู้ใช้ก่อน** (field เดียวใช้ข้าม view/excel/drilldown/subreport — เคย set filter_branch='' แล้ว sub_header PDF พัง)
4. **type-inference error ('cannot determine value type') = resolver เดา type จากเนื้อหาค่า ไม่ใช่ metadata** → CAST ไม่ช่วย ต้องทำค่า homogeneous (`'-'`→`0`)
5. **ขอ log แบบกรอง** — red ERP มี Quartz `wfJob1Trigger` เด้ง stdout ทุกวินาที → ขอ user `grep -iE "Exception|acedrilldown|SQLException|Unknown column|doesn't exist"` ก่อนแปะ
6. **อย่าไล่ static ของที่อยู่นอก repo** (DB config / deploy version) — รู้ตัวเร็วแล้วขอ evidence/ถาม user แทน (ประหยัด tool call มหาศาล)
7. **ไฟล์ที่เจอจาก glob/folder-name pattern match ≠ ไฟล์ที่ถูกต้อง** — เปิดดู `reportCode`/`reportSqlCode` hardcode ในตัวไฟล์ หรือเช็คว่ามี `.jasper` ชื่อตรงกับ reportcode วางข้างๆ ก่อนแก้เสมอ (พลาดจริง: folder `X/YY/1` ดูคล้าย reportcode `X-YY-0` แต่เป็นคนละรายงาน — user เป็นคนจับได้)
8. **ก่อนแก้ไฟล์ shared/template** (`drilldown_new.jsp`, `assets/js/index.js`, `download_excel_file.jsp`, ไฟล์ path มีคำว่า `template`/`common`) **ต้อง grep หา field/function/table ที่กำลังจะแก้ก่อนเขียนโค้ด** ไม่ใช่รอ user ถามว่า "กระทบรายงานอื่นไหม" — ชื่อ field ในระบบนี้มักใช้ร่วมข้ามรายงานเป็นร้อยไฟล์ overwrite แบบไม่มีเงื่อนไขเสี่ยงเสมอ (แก้แบบ fill-only-if-empty ปลอดภัยกว่า)
9. **verify ว่า deploy ไป UAT จริงหรือยัง ห้ามเชื่อ file mtime (`ls -la`)** — ใช้ `md5sum` เทียบ repo vs deploy path เท่านั้น (เจอเคสจริง: ไฟล์บน network share mtime ใหม่กว่าแต่เนื้อหาเก่ากว่า/ครึ่งเดียว — สรุปว่า deploy ถูกต้องแล้วทั้งที่ยังไม่ครบ)
10. **"เรียกดู"/"พิมพ์" จากหน้า filter ต้นทาง กับ "พิมพ์" จากหน้า drilldown เป็นคนละ code path — คนละ `report_form`** หน้าแรกใช้ hidden field เฉพาะของรายงานนั้น หน้า drilldown (`drilldown_new.jsp`) มี `report_form` ของตัวเอง ไม่รู้จัก field พิเศษที่รายงานต้นทางสร้างเอง (เช่น `filter_todate_before_show`) ถ้าเจอ "null" โผล่เฉพาะตอนพิมพ์จาก drilldown แต่ไม่โผล่ตอนเรียกดูจากหน้า filter — ให้สงสัยจุดนี้ก่อน

## Per-report — ถามก่อนเริ่ม (ถ้า casebook ยังไม่มี)
- report code + ไฟล์ filter jsp อยู่ path ไหน
- มี `.bak-broken` ให้เทียบไหม (ใช้เป็นต้นฉบับ alias/filePath)
- ต้องการ drilldown ไหม (มี DB config หรือยัง)
- error จริงคืออะไร (ขอ screenshot / console stack / server log กรองแล้ว)

## Step สุดท้าย: บันทึกลง casebook (สำคัญ — นี่คือหัวใจ)
ทำรายงานเสร็จ **append 1 แถวลง `casebook.md`** เสมอ: report, module, alias, filePath, drilldown(suffix), quirk ที่เจอ, สถานะ.
เจอ pattern ระดับโมดูล (เช่น "PC ทุกตัวใช้ alias X") → จดใน section "Module patterns" ของ casebook.
```bash
# แก้ไฟล์ด้วย editor tool ปกติ (Edit/Write) — เพิ่มแถวในตาราง casebook.md
```

## หมายเหตุ
- Skill นี้ **เฉพาะงาน report** — งาน form ใช้ [[awaken-form]]
- ห้าม commit/push/restart server เอง (กฎ global) · ไม่แก้ DB จริงถ้าไม่ได้สั่ง
- vault memory (retro/lesson) ที่ `~/oracle/ψ/memory` มีรายละเอียดลึกกว่านี้ — ดึงมาอ่านได้เมื่อต้องเข้าใจ "ทำไม"

## Compile `.jrxml` เป็น `.jasper` ด้วย Jaspersoft Studio 7.0.3 (Windows)

Codex compile ได้โดยไม่ต้อง start/restart WildFly แม้ `java`/`javac` จะไม่อยู่ใน `PATH`:

1. หา Jaspersoft Studio จาก process หรือโฟลเดอร์ติดตั้ง แล้วใช้ embedded JRE 17 ที่
   `features/jre.win32.win32.x86_64.feature_17.0.8.1_1/eclipsetemurin_jre/bin/java.exe`
2. Embedded runtime เป็น **JRE ไม่ใช่ JDK**; source-file mode จะ error `Module jdk.compiler not in boot Layer` จึงต้อง compile Java helper ด้วย
   `plugins/org.eclipse.jdt.core.compiler.batch_*.jar`
3. Runtime classpath ที่ใช้ compile report ของ red ERP:
   - `red.war/WEB-INF/lib/*`
   - Studio `jasperreports-jdt-7.0.3.jar`
   - Studio `org.eclipse.jdt.core.compiler.batch_*.jar`
   - `redjaka.ear/lib/red-kernel-lib-1.0.0.jar` สำหรับ expression `red.kernel.util.MyFnc`
4. อย่าใช้ `red-kernel-ejb-1.0.0.jar` แทน — `MyFnc.class` อยู่ใน **red-kernel-lib**
5. เรียก `JasperCompileManager.compileReportToFile(source, output)` และตรวจ exit code, ชื่อ `.jasper`, ขนาด และ SHA-256 ทุกไฟล์
6. Warning `Log4j2 could not find a logging implementation ... Using SimpleLogger` ไม่ทำให้ compile ล้มเหลว ถ้า exit code เป็น 0 และมี `COMPILED ...` ครบ
7. Compile เสร็จแล้วห้าม copy เข้า deploy path อัตโนมัติถ้าผู้ใช้ยังไม่ได้สั่ง
