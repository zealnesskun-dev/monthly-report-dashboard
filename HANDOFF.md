# Monthly Report Dashboard — Handoff Note
> วันที่: 2026-05-15 | ทำต่อที่บ้านได้เลย

---

## ไฟล์ที่ต้องเอาไป
```
Monthly_Report_Single.html   ← ตัวแอปทั้งหมด (single file)
เปิด Monthly Report.bat      ← launcher (ไว้เป็น backup)
HANDOFF.md                   ← ไฟล์นี้
```

## เปิดใช้งาน
**ดับเบิลคลิก `Monthly_Report_Single.html` ได้เลย** — ไม่ต้องรัน .bat  
ข้อมูลโหลดจาก Google Drive อัตโนมัติผ่าน GAS

---

## Architecture ปัจจุบัน

### Backend: Google Apps Script (GAS)
```
URL: https://script.google.com/macros/s/AKfycbzGUotNNlJiZbwhMGNGPjUXF4a3rEMAa_wWhdycZYFan_Pvw1LUATn1AB2PZ1NT7G9I/exec
Deploy: Execute as Me | Anyone can access
Drive folder: Monthly-Report-EPC/ (ใน Google Drive ของ zealnesskun@gmail.com)
```

**GAS endpoints (doGet):**
- `?action=loadAll` → โหลดทุกกองพร้อมกัน
- `?action=load&divId=kps` → โหลดกองเดียว

**GAS endpoints (doPost, no-cors):**
- `{action:"save", divId, tab, meta, password}` → บันทึกกอง
- `{action:"saveVersion", divId, versionName, tab, meta, password}` → บันทึก version

### Drive file structure
```
Monthly-Report-EPC/
├── mrd-kps.json    ← กปส-พ.
├── mrd-kts.json    ← กตส-พ.
├── mrd-kss.json    ← กสส-พ.
├── mrd-kbr.json    ← กบร-พ.
└── mrd-asc.json    ← อสค.
(ไม่มี images/ folder แล้ว — รูปเก็บใน JSON เลย)
```

### รูปภาพ
- **เก็บเป็น base64 dataURL ใน JSON** (ไม่มี upload แยก)
- compress ด้วย Canvas API ก่อนเก็บ (max 1200px, JPEG quality 0.72)
- คลิกรูป → เลือกไฟล์ → compress → เก็บใน state → **กด "บันทึก" เพื่อ sync ขึ้น Drive**

---

## Flow การใช้งาน
```
เปิด HTML → โหลดจาก GAS อัตโนมัติ → ดู/นำเสนอได้เลย
                ↓ ถ้าจะแก้ไข
            กดไอคอน ✎ (Toolbar) → ใส่ password: 123456
                ↓
            เลือกกอง (กปส / กตส / กสส / กบร / อสค)
                ↓
            แก้ได้เฉพาะ tab ของกองตัวเอง
                ↓
            กด "บันทึก" → ส่งขึ้น GAS → เขียน Drive
                ↓ ถ้าคนอื่นบันทึกไปแล้ว
            กด "↺ โหลดจาก Drive" → sync ใหม่
```

---

## สิ่งที่ทำแล้ว ✓
- [x] 5 กอง แยก JSON file ใน Drive
- [x] Auth: password 123456 → เลือกกอง → edit เฉพาะกองตัวเอง
- [x] Auto-load จาก GAS ตอนเปิดหน้า
- [x] Save / Save As / Version history (local)
- [x] รูปภาพ: compress → dataURL → เก็บใน JSON
- [x] "↺ โหลดจาก Drive" — sync ล่าสุด
- [x] Export / Import JSON (backup)
- [x] Presentation mode
- [x] POST ใช้ no-cors (ทำงานได้จาก file://)

## สิ่งที่ยังไม่ได้ทดสอบ / ต้องทำต่อ
- [ ] **ทดสอบบันทึกจริง** — กด บันทึก แล้วเปิดใหม่ ข้อมูลต้องยังอยู่
- [ ] **ทดสอบรูปภาพ** — อัพโหลดรูป บันทึก ปิด-เปิดใหม่ รูปต้องยังขึ้น
- [ ] **GitHub Pages** — deploy เพื่อแชร์ URL ให้ทีม (ไม่ต้องส่งไฟล์)
- [ ] **ทดสอบ multi-user** — 2 คนแก้คนละกองพร้อมกัน

---

## ข้อจำกัดที่รู้แล้ว
| ปัญหา | สาเหตุ | วิธีแก้ |
|---|---|---|
| POST จาก file:// ไม่รู้ว่าสำเร็จหรือเปล่า | no-cors อ่าน response ไม่ได้ | ทดสอบโดยปิด-เปิดใหม่แล้วดูว่าข้อมูลอยู่ไหม |
| รูปใน JSON ทำให้ไฟล์ใหญ่ | base64 overhead ~33% | ยอมรับได้ — รูปถูก compress แล้ว |
| No real-time sync | ไม่มี polling | กด "↺ โหลดจาก Drive" ก่อนนำเสนอ |

---

## ถ้าจะทำ GitHub Pages (ต่อที่บ้าน)
1. สมัคร github.com → New repository (public)
2. อัพโหลด `Monthly_Report_Single.html` เปลี่ยนชื่อเป็น `index.html`
3. Settings → Pages → Branch: main → Save
4. ได้ URL: `https://username.github.io/repo-name`
5. ไปที่ console.cloud.google.com → OAuth consent screen → Authorized JavaScript origins → เพิ่ม URL นั้น
6. แชร์ URL ให้ทีม — ทุกคนเข้าได้เลย ไม่ต้องส่งไฟล์

---

## GAS Code (ถ้าต้องสร้างใหม่)
เปิด script.google.com → New project → วางโค้ดนี้ → Deploy → Web App → Execute as Me → Anyone

```javascript
const FOLDER_NAME = "Monthly-Report-EPC";
const WRITE_PASSWORD = "123456";

function doGet(e) {
  try {
    const action = e.parameter.action;
    if (action === "loadAll") return respond(loadAll());
    if (action === "load") return respond(loadDivision(e.parameter.divId));
    return respond({ error: "unknown action" });
  } catch (err) { return respond({ error: err.message }); }
}

function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);
    if (data.password !== WRITE_PASSWORD) return respond({ error: "unauthorized" });
    if (data.action === "save") { saveDivision(data.divId, data.tab, data.meta); return respond({ ok: true }); }
    if (data.action === "saveVersion") { saveVersion(data.divId, data.versionName, data.tab, data.meta); return respond({ ok: true }); }
    return respond({ error: "unknown action" });
  } catch (err) { return respond({ error: err.message }); }
}

function respond(data) {
  return ContentService.createTextOutput(JSON.stringify(data)).setMimeType(ContentService.MimeType.JSON);
}
function getFolder() { const it = DriveApp.getFoldersByName(FOLDER_NAME); return it.hasNext() ? it.next() : DriveApp.createFolder(FOLDER_NAME); }
function loadAll() { const r = {}; ["kps","kts","kss","kbr","asc"].forEach(id => { const d = loadDivision(id); if (d) r[id] = d; }); return r; }
function loadDivision(divId) { const it = getFolder().getFilesByName("mrd-"+divId+".json"); if (!it.hasNext()) return null; return JSON.parse(it.next().getBlob().getDataAsString()); }
function saveDivision(divId, tab, meta) { const folder = getFolder(); const name = "mrd-"+divId+".json"; const content = JSON.stringify({kind:"mrd-division",divisionId:divId,period:meta&&meta.period,savedAt:new Date().toISOString(),tab}); const it = folder.getFilesByName(name); if (it.hasNext()) it.next().setContent(content); else folder.createFile(name, content, MimeType.PLAIN_TEXT); }
function saveVersion(divId, versionName, tab, meta) { const date = new Date().toISOString().slice(0,10); const safe = versionName.replace(/[\/\\:*?"<>|]/g,"_").substring(0,50); const content = JSON.stringify({kind:"mrd-division-version",divisionId:divId,versionName,period:meta&&meta.period,savedAt:new Date().toISOString(),tab}); getFolder().createFile("mrd-"+divId+"_"+date+"_"+safe+".json", content, MimeType.PLAIN_TEXT); }
```

---

## Key constants ในโค้ด
```javascript
// Monthly_Report_Single.html
const ADMIN_PASSWORD_HASH = "MTIzNDU2"; // btoa("123456")
const STORAGE_KEY = "mrd-state-v3";     // localStorage key
const GAS_URL = "https://script.google.com/macros/s/AKfycbzGUotNNlJiZbwhMGNGPjUXF4a3rEMAa_wWhdycZYFan_Pvw1LUATn1AB2PZ1NT7G9I/exec";
const DIVISIONS = [
  { id: "kps", short: "กปส-พ.", tabIdx: 0 },
  { id: "kts", short: "กตส-พ.", tabIdx: 1 },
  { id: "kss", short: "กสส-พ.", tabIdx: 2 },
  { id: "kbr", short: "กบร-พ.", tabIdx: 3 },
  { id: "asc", short: "อสค.",   tabIdx: 4 },
];
```
