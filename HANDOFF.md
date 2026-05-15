# Monthly Report Dashboard — Handoff Note
> อัปเดต: 2026-05-15

---

## ไฟล์ในโปรเจกต์
```
index.html                   ← ตัวแอปทั้งหมด (single file)
เปิด Monthly Report.bat       ← launcher (ไว้เป็น backup)
HANDOFF.md                    ← ไฟล์นี้
กxx text.txt                  ← ข้อความต้นฉบับแต่ละกอง
```

## เปิดใช้งาน
- **ออนไลน์:** https://zealnesskun-dev.github.io/monthly-report-dashboard/
- **local:** ดับเบิลคลิก `index.html` ได้เลย — ไม่ต้องรัน .bat

ข้อมูลโหลดจาก Google Drive อัตโนมัติผ่าน GAS

---

## Architecture ปัจจุบัน

### Backend: Google Apps Script (GAS)
```
URL: https://script.google.com/macros/s/AKfycbz_9lXJ_0_C1MCS0pFS90_i5sTwSXubIrAyx25kh0EyvUfUih98OCXxcFOnIl0Hufup/exec
Deploy: Execute as Me | Anyone can access
Drive folder: Monthly-Report-EPC/ (ใน Google Drive ของ zealnesskun@gmail.com)
```

**GAS endpoints (doGet):**
- `?action=loadAll` → โหลดทุกกองพร้อมกัน
- `?action=load&divId=kps` → โหลดกองเดียว
- `?action=getImageUrl&divId=kps&imageId=xxx` → คืน URL รูปใน Drive

**GAS endpoints (doPost, no-cors):**
- `{action:"save", divId, tab, meta, password}` → บันทึกกอง
- `{action:"saveVersion", divId, versionName, tab, meta, password}` → บันทึก version
- `{action:"uploadImage", divId, imageId, imageData, password}` → อัพรูปขึ้น Drive

### Drive file structure
```
Monthly-Report-EPC/
├── mrd-kps.json    ← กปส-พ.   ├── mrd-kbr.json    ← กบร-พ.
├── mrd-kts.json    ← กตส-พ.   └── mrd-asc.json    ← อสค.
├── mrd-kss.json    ← กสส-พ.
├── images-kps/     ← รูปกอง กปส (1 ไฟล์ = 1 รูป)
├── images-kts/     ← รูปกอง กตส
├── images-kss/  ├── images-kbr/  └── images-asc/
```

### รูปภาพ — เก็บแยกไฟล์ใน Drive (ไม่ใช่ base64 ใน JSON แล้ว)
- คลิกรูป → เลือกไฟล์ → compress (Canvas API, max 1200px, JPEG 0.72)
- → POST ขึ้น Drive subfolder `images-{กอง}/` → GAS คืน URL
- JSON เก็บแค่ **URL** ของรูป (`https://lh3.googleusercontent.com/d/...`) ไม่ใช่ base64
- ผล: JSON เบามาก รองรับรูปเยอะ (50+ รูป/เดือน) ได้สบาย
- รูปแสดงผ่าน CDN `lh3.googleusercontent.com/d/{fileId}` — โค้ดแปลง URL เก่าแบบ `uc?id=` ให้อัตโนมัติ (`driveImg()`)

---

## Flow การใช้งาน
```
เปิดเว็บ → โหลดจาก GAS อัตโนมัติ → ดู/นำเสนอได้เลย
                ↓ ถ้าจะแก้ไข
            กดไอคอน ✎ (Toolbar) → ใส่ password: 123456
                ↓
            เลือกกอง (กปส / กตส / กสส / กบร / อสค)
                ↓
            แก้ได้เฉพาะ tab ของกองตัวเอง
            (อัพรูป → รอ "อัพโหลดสำเร็จ ✓" ~3-8 วินาที)
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
- [x] Save / Save As / Version history
- [x] รูปภาพ: อัพขึ้น Drive แยกไฟล์ในโฟลเดอร์รายกอง → JSON เก็บแค่ URL
- [x] "↺ โหลดจาก Drive" — sync ล่าสุด
- [x] Export / Import JSON (backup)
- [x] Presentation mode
- [x] Git + GitHub repo (public)
- [x] GitHub Pages — เว็บออนไลน์

## สิ่งที่ยังไม่ได้ทดสอบ / ต้องทำต่อ
- [ ] **ทดสอบ multi-user** — 2 คนแก้คนละกองพร้อมกัน
- [ ] **เปลี่ยน password** — `123456` อยู่ใน public repo ใครก็เห็น

---

## ข้อจำกัดที่รู้แล้ว
| ปัญหา | สาเหตุ | วิธีแก้ |
|---|---|---|
| POST ไม่รู้ว่าสำเร็จหรือเปล่า | no-cors อ่าน response ไม่ได้ | save: เปิดใหม่ดูว่าข้อมูลอยู่ไหม / upload รูป: ใช้ GET getImageUrl ตามไปเช็ค |
| No real-time sync | ไม่มี polling | กด "↺ โหลดจาก Drive" ก่อนนำเสนอ |
| password อยู่ใน public repo | repo เป็น public | ถ้าต้องการความปลอดภัยให้เปลี่ยน password |

---

## Git / GitHub
```
Repo (public): https://github.com/zealnesskun-dev/monthly-report-dashboard
```

**workflow (ทำได้ทุกเครื่องที่มี git):**
```
git pull              ← ก่อนเริ่มแก้ ดึงของล่าสุด
...แก้ไฟล์...
git add .
git commit -m "ข้อความ"
git push              ← ส่งขึ้น GitHub
```

**เครื่องใหม่:** `git clone https://github.com/zealnesskun-dev/monthly-report-dashboard.git`
(login ผ่าน browser ครั้งเดียว — Git Credential Manager จัดการให้)

**GitHub Pages:** เปิดอยู่แล้ว → push แล้วเว็บอัปเดตเองภายใน ~1 นาที

---

## GAS Code (โค้ดเต็ม — ถ้าต้องสร้างใหม่)
เปิด script.google.com → New project → วางโค้ดนี้ → Deploy → Web App → Execute as Me → Anyone

> **กับดักที่ต้องรู้:** ทุกครั้งที่แก้โค้ด GAS ต้อง Deploy → Manage deployments → ✏️ → Version: **New version** ไม่งั้นโค้ดใหม่ไม่มีผล (URL คงเดิม)

```javascript
const FOLDER_NAME = "Monthly-Report-EPC";
const WRITE_PASSWORD = "123456";

function doGet(e) {
  try {
    const action = e.parameter.action;
    if (action === "loadAll") return respond(loadAll());
    if (action === "load") return respond(loadDivision(e.parameter.divId));
    if (action === "getImageUrl") return respond(getImageUrl(e.parameter.divId, e.parameter.imageId));
    return respond({ error: "unknown action" });
  } catch (err) { return respond({ error: err.message }); }
}

function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);
    if (data.password !== WRITE_PASSWORD) return respond({ error: "unauthorized" });
    const action = data.action;
    if (action === "save") { saveDivision(data.divId, data.tab, data.meta); return respond({ ok: true }); }
    if (action === "saveVersion") { saveVersion(data.divId, data.versionName, data.tab, data.meta); return respond({ ok: true }); }
    if (action === "uploadImage") { uploadImageToDrive(data.divId, data.imageId, data.imageData); return respond({ ok: true }); }
    return respond({ error: "unknown action" });
  } catch (err) { return respond({ error: err.message }); }
}

function respond(data) {
  return ContentService.createTextOutput(JSON.stringify(data)).setMimeType(ContentService.MimeType.JSON);
}

function getFolder() {
  const it = DriveApp.getFoldersByName(FOLDER_NAME);
  return it.hasNext() ? it.next() : DriveApp.createFolder(FOLDER_NAME);
}

function getImageFolder(divId) {
  const parent = getFolder();
  const name = "images-" + divId;
  const it = parent.getFoldersByName(name);
  return it.hasNext() ? it.next() : parent.createFolder(name);
}

function loadAll() {
  const result = {};
  ["kps","kts","kss","kbr","asc"].forEach(id => { const d = loadDivision(id); if (d) result[id] = d; });
  return result;
}

function loadDivision(divId) {
  const it = getFolder().getFilesByName("mrd-" + divId + ".json");
  if (!it.hasNext()) return null;
  return JSON.parse(it.next().getBlob().getDataAsString());
}

function saveDivision(divId, tab, meta) {
  const folder = getFolder();
  const name = "mrd-" + divId + ".json";
  const content = JSON.stringify({ kind:"mrd-division", divisionId:divId, period:meta&&meta.period, savedAt:new Date().toISOString(), tab });
  const it = folder.getFilesByName(name);
  if (it.hasNext()) it.next().setContent(content);
  else folder.createFile(name, content, MimeType.PLAIN_TEXT);
}

function saveVersion(divId, versionName, tab, meta) {
  const date = new Date().toISOString().slice(0,10);
  const safe = versionName.replace(/[\/\\:*?"<>|]/g,"_").substring(0,50);
  const content = JSON.stringify({ kind:"mrd-division-version", divisionId:divId, versionName, period:meta&&meta.period, savedAt:new Date().toISOString(), tab });
  getFolder().createFile("mrd-"+divId+"_"+date+"_"+safe+".json", content, MimeType.PLAIN_TEXT);
}

function uploadImageToDrive(divId, imageId, dataUrl) {
  const folder = getImageFolder(divId);
  const fileName = imageId + ".jpg";
  const b64 = dataUrl.split(",")[1];
  const blob = Utilities.newBlob("")
    .setBytes(Utilities.base64Decode(b64))
    .setContentType("image/jpeg")
    .setName(fileName);
  const existing = folder.getFilesByName(fileName);
  if (existing.hasNext()) existing.next().setTrashed(true);
  const file = folder.createFile(blob);
  file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
}

function getImageUrl(divId, imageId) {
  const it = getImageFolder(divId).getFilesByName(imageId + ".jpg");
  if (!it.hasNext()) return { url: null };
  return { url: "https://lh3.googleusercontent.com/d/" + it.next().getId() };
}
```

---

## Key constants ในโค้ด
```javascript
// index.html
const ADMIN_PASSWORD_HASH = "MTIzNDU2"; // btoa("123456")
const STORAGE_KEY = "mrd-state-v3";     // localStorage key
const GAS_URL = "https://script.google.com/macros/s/AKfycbz_9lXJ_0_C1MCS0pFS90_i5sTwSXubIrAyx25kh0EyvUfUih98OCXxcFOnIl0Hufup/exec";
const DIVISIONS = [
  { id: "kps", short: "กปส-พ.", tabIdx: 0 },
  { id: "kts", short: "กตส-พ.", tabIdx: 1 },
  { id: "kss", short: "กสส-พ.", tabIdx: 2 },
  { id: "kbr", short: "กบร-พ.", tabIdx: 3 },
  { id: "asc", short: "อสค.",   tabIdx: 4 },
];
```
