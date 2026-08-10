# คู่มือ Database — Thai Vowel Pronunciation App

> **Stack:** MySQL · Firebase Auth · Flutter · Flask (Python)
> **จำนวนตาราง:** 7 tables (6 เดิม + 1 ใหม่: `practice_pair_sessions`)
> **อัปเดตล่าสุด:** เอกสารนี้ถูกเขียนใหม่ทั้งหมดหลังจากตรวจสอบ schema จริงผ่าน phpMyAdmin
> ทีละตาราง (เวอร์ชันก่อนหน้านี้มีข้อมูลล้าสมัยหลายจุด เช่น คอลัมน์ `jaw_en/jaw_th`,
> `f1/f2` ที่ถูกลบไปแล้วจริงในฐานข้อมูล — เอกสารนี้แก้ให้ตรงกับของจริง)
>
> เอกสารออกแบบเชิงลึก (ERD, rationale, migration SQL ฉบับเต็ม) อยู่ที่
> `thaivowel-pronunciation-backend/DATABASE_REDESIGN.md` และ
> `thaivowel-pronunciation-backend/sql/migration_v2.sql`

---

## ภาพรวม ERD

```
users (firebase_uid PK)
 ├──< user_streaks           (firebase_uid FK)
 ├──< practice_sessions      (firebase_uid FK)
 ├──< user_lesson_progress   (firebase_uid FK)
 └──< practice_pair_sessions (firebase_uid FK)              ← ตารางใหม่

vowels (id PK)
 ├── paired_vowel_id -> vowels.id (self-reference)          ← คอลัมน์ใหม่
 ├── model_class_index (เลข class ของ ML model)              ← คอลัมน์ใหม่
 └──< vowel_lessons           (vowel_id FK)
       ├──< user_lesson_progress (lesson_id FK)
       └──< practice_sessions    (lesson_id FK)

vowels ──< practice_pair_sessions.short_vowel_id             ← ตารางใหม่
vowels ──< practice_pair_sessions.long_vowel_id              ← ตารางใหม่
```

---

## สรุปการตัดสินใจ redesign (อัปเดตจากการรีวิวทีละตารางร่วมกัน)

| ตาราง | สิ่งที่เปลี่ยน | สถานะ |
|---|---|---|
| `users` | — | ✅ คงเดิม ไม่แก้ |
| `user_streaks` | เพิ่ม FK บน `firebase_uid` | ⏭️ ข้ามไว้ก่อน |
| `vowels` | เพิ่ม `model_class_index`, `paired_vowel_id` (ใส่ข้อมูลแล้ว, ยังไม่ล็อก constraint) | ✅ เพิ่มคอลัมน์แล้ว / ⏭️ constraint ข้ามไว้ก่อน |
| `vowel_lessons` | เพิ่ม `category` ENUM('vowel','word') พร้อม backfill | ✅ ทำแล้ว |
| `vowel_lessons` | เพิ่ม `UNIQUE(vowel_id, lesson_order)` | ⏭️ ข้ามไว้ก่อน |
| `user_lesson_progress` | เปลี่ยน `assessment_level` เป็น ENUM | ❌ ไม่ทำ คงเป็น VARCHAR(20) |
| `user_lesson_progress` | เพิ่ม FK บน `firebase_uid` | ⏭️ ข้ามไว้ก่อน |
| `practice_sessions` | เพิ่ม index `(firebase_uid, practiced_at)` | ⏭️ ข้ามไว้ก่อน |
| `practice_sessions` | เปลี่ยน `assessment_level` เป็น ENUM | ❌ ไม่ทำ คงเป็น VARCHAR(20) |
| `practice_sessions` | เพิ่ม FK บน `firebase_uid` | ⏭️ ข้ามไว้ก่อน |
| `practice_sessions` | แก้ trigger ให้อ่านจาก `vowel_lessons.category` | ✅ ทำแล้ว |
| `practice_pair_sessions` | สร้างตารางใหม่ | ✅ ออกแบบแล้ว (ยังไม่สร้างจริงในฐานข้อมูล) |

---

## 1. Table: `users`

เก็บข้อมูล account ผู้ใช้ทั้งที่ login ด้วย Email และ Google — **ไม่มีการเปลี่ยนแปลง**

| คอลัมน์ | ประเภท | Constraint | คำอธิบาย |
|---|---|---|---|
| `firebase_uid` | VARCHAR(128) | PRIMARY KEY | UID จาก Firebase Auth |
| `username` | VARCHAR(100) | NOT NULL | ชื่อที่แสดงในแอป |
| `email` | VARCHAR(255) | NOT NULL | อีเมลจาก Firebase |
| `gender` | VARCHAR(20) | — | เพศผู้ใช้ |
| `age` | INT | — | อายุผู้ใช้ |
| `nationality` | VARCHAR(100) | NOT NULL DEFAULT 'Thai' | สัญชาติผู้ใช้ |
| `login_provider` | VARCHAR(20) | — | วิธี login (`email` / `google`) |
| `created_at` | DATETIME | DEFAULT CURRENT_TIMESTAMP | วันสมัครสมาชิก |

```sql
CREATE TABLE users (
  firebase_uid   VARCHAR(128) PRIMARY KEY,
  username       VARCHAR(100) NOT NULL,
  email          VARCHAR(255) NOT NULL,
  gender         VARCHAR(20),
  age            INT,
  nationality    VARCHAR(100) NOT NULL DEFAULT 'Thai',
  login_provider VARCHAR(20),
  created_at     DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

---

## 2. Table: `user_streaks`

เก็บข้อมูล streak แยกออกจาก `users` — **ไม่มีการเปลี่ยนแปลง** (พิจารณาเพิ่ม FK บน `firebase_uid` แล้ว แต่ข้ามไว้ก่อน)

| คอลัมน์ | ประเภท | Constraint | คำอธิบาย |
|---|---|---|---|
| `firebase_uid` | VARCHAR(128) | PRIMARY KEY | เจ้าของ streak |
| `current_streak` | INT | DEFAULT 0 | จำนวนวันที่ฝึกต่อเนื่องปัจจุบัน |
| `longest_streak` | INT | DEFAULT 0 | สถิติ streak ยาวที่สุดตลอดกาล |
| `last_practice_date` | DATE | — | วันที่ฝึกล่าสุด ใช้คำนวณ streak |

```sql
CREATE TABLE user_streaks (
  firebase_uid       VARCHAR(128) PRIMARY KEY,
  current_streak     INT DEFAULT 0,
  longest_streak     INT DEFAULT 0,
  last_practice_date DATE
);
```

**อัปเดต Streak หลังฝึกเสร็จแต่ละ session**
```sql
UPDATE user_streaks
SET current_streak = CASE
      WHEN last_practice_date = CURDATE() - INTERVAL 1 DAY THEN current_streak + 1
      WHEN last_practice_date < CURDATE() - INTERVAL 1 DAY THEN 1
      ELSE current_streak
    END,
    longest_streak = GREATEST(longest_streak, current_streak),
    last_practice_date = CURDATE()
WHERE firebase_uid = ?;
```

---

## 3. Table: `vowels`

รายชื่อสระทั้งหมด 18 ตัว แยก Short / Long

**สิ่งที่เปลี่ยน:**
- ⚠️ คอลัมน์ `f1`, `f2` (ของเก่า) **ถูกลบไปแล้วจริงในฐานข้อมูล** (ไม่ใช่แค่แผน — ยืนยันจาก phpMyAdmin) เอกสารเก่าที่อ้างถึงคอลัมน์นี้ล้าสมัยแล้ว
- ⚠️ คอลัมน์ `jaw_en`/`jaw_th` (ของเก่า) ถูกแทนที่ด้วย `tongue_level_en`/`tongue_level_th` แล้วจริงในฐานข้อมูล
- ✅ เพิ่ม `model_class_index` — เลข class ของ ML model (0–17) ที่ `/predict`, `/predict_pair` ใช้ ก่อนหน้านี้โค้ดคำนวณจาก `vowel.id - 1` เอาเอง (เปราะบาง ถ้ามีการเรียงลำดับใหม่จะพังเงียบๆ) ตอนนี้เก็บเป็นคอลัมน์จริงแล้ว
- ✅ เพิ่ม `paired_vowel_id` — ชี้ไปยัง `vowels.id` ของคู่สระ (สั้น↔ยาว) ใช้โดยฟีเจอร์ "สระเสียงใกล้เคียงกัน" ก่อนหน้านี้จับคู่แบบ positional (เรียงตามลำดับที่ query กลับมา) เท่านั้น
- ⏭️ ยังไม่ได้ล็อก `NOT NULL` / `UNIQUE` / `CHECK` / `FOREIGN KEY` ให้สองคอลัมน์ใหม่นี้ — ใส่ข้อมูล backfill ครบแล้ว แต่ยังเปิดให้แก้ไขได้อิสระ (ตัดสินใจข้ามส่วนนี้ไว้ก่อน)

| คอลัมน์ | ประเภท | คำอธิบาย |
|---|---|---|
| `id` | INT, PK, AUTO_INCREMENT | id สระ 1–18 |
| `symbol` | VARCHAR(20) | ตัวสระ เช่น อา, อิ, อะ |
| `vowel_type` | ENUM('short','long') | Short Vowels / Long Vowels |
| `description_en` / `description_th` | TEXT | คำอธิบายสระ |
| `lips_en` / `lips_th` | VARCHAR(100) | วิธีเปล่งเสียง: ริมฝีปาก |
| `tongue_en` / `tongue_th` | VARCHAR(100) | วิธีเปล่งเสียง: ลิ้น |
| `tongue_level_en` / `tongue_level_th` | VARCHAR(100) | ระดับลิ้น (แทนที่ `jaw_en`/`jaw_th` เดิม) |
| `link_video` | VARCHAR(500) | URL วิดีโอประกอบการสอนสระ |
| `unicode_phonetic` | VARCHAR(50) | สัญลักษณ์ IPA เช่น `/aː/`, `/i/` |
| `f1_min` / `f1_max` / `f2_min` / `f2_max` | FLOAT | ช่วงค่า Formant อ้างอิง (แทนที่ `f1`/`f2` ค่าเดี่ยวเดิม) |
| `model_class_index` 🆕 | TINYINT UNSIGNED | เลข class ของ ML model (0–17) |
| `paired_vowel_id` 🆕 | INT | id ของสระคู่ (สั้น↔ยาว) |

```sql
CREATE TABLE vowels (
  id                 INT AUTO_INCREMENT PRIMARY KEY,
  symbol             VARCHAR(20)  NOT NULL,
  vowel_type         ENUM('short','long') NOT NULL,
  description_en     TEXT,
  description_th     TEXT,
  lips_en            VARCHAR(100),
  lips_th            VARCHAR(100),
  tongue_en          VARCHAR(100),
  tongue_th          VARCHAR(100),
  link_video         VARCHAR(500),
  f1_min             FLOAT,
  f1_max             FLOAT,
  f2_min             FLOAT,
  f2_max             FLOAT,
  unicode_phonetic   VARCHAR(50),
  tongue_level_en    VARCHAR(100),
  tongue_level_th    VARCHAR(100),
  model_class_index  TINYINT UNSIGNED,   -- 🆕
  paired_vowel_id    INT                 -- 🆕
);
```

### โค้ดที่ใช้เพิ่ม + backfill สองคอลัมน์ใหม่ (รันแล้ว/พร้อมรัน)

```sql
ALTER TABLE vowels
  ADD COLUMN model_class_index TINYINT UNSIGNED NULL AFTER unicode_phonetic,
  ADD COLUMN paired_vowel_id   INT NULL AFTER model_class_index;

-- model_class_index = vowels.id - 1
UPDATE vowels SET model_class_index = CASE id
  WHEN 1  THEN 0  WHEN 2  THEN 1  WHEN 3  THEN 2  WHEN 4  THEN 3  WHEN 5  THEN 4
  WHEN 6  THEN 5  WHEN 7  THEN 6  WHEN 8  THEN 7  WHEN 9  THEN 8
  WHEN 10 THEN 9  WHEN 11 THEN 10 WHEN 12 THEN 11 WHEN 13 THEN 12 WHEN 14 THEN 13
  WHEN 15 THEN 14 WHEN 16 THEN 15 WHEN 17 THEN 16 WHEN 18 THEN 17
END
WHERE id BETWEEN 1 AND 18;

-- paired_vowel_id: 1<->10 อา/อะ, 2<->11 อี/อิ, 3<->12 อือ/อึ, 4<->13 อู/อุ,
-- 5<->14 เอ/เอะ, 6<->15 แอ/แอะ, 7<->16 โอ/โอะ, 8<->17 ออ/เอาะ, 9<->18 เออ/เออะ
UPDATE vowels SET paired_vowel_id = CASE id
  WHEN 1  THEN 10 WHEN 2  THEN 11 WHEN 3  THEN 12 WHEN 4  THEN 13 WHEN 5  THEN 14
  WHEN 6  THEN 15 WHEN 7  THEN 16 WHEN 8  THEN 17 WHEN 9  THEN 18
  WHEN 10 THEN 1  WHEN 11 THEN 2  WHEN 12 THEN 3  WHEN 13 THEN 4  WHEN 14 THEN 5
  WHEN 15 THEN 6  WHEN 16 THEN 7  WHEN 17 THEN 8  WHEN 18 THEN 9
END
WHERE id BETWEEN 1 AND 18;
```

### Seed Data (สระทั้ง 18 ตัว, ตามข้อมูลจริงในฐานข้อมูล)

```sql
-- Long Vowels (id 1-9)
INSERT INTO vowels (symbol, vowel_type) VALUES
('อา', 'long'), ('อี', 'long'), ('อือ', 'long'), ('อู', 'long'), ('เอ', 'long'),
('แอ', 'long'), ('โอ', 'long'), ('ออ', 'long'), ('เออ', 'long'),
-- Short Vowels (id 10-18)
('อะ', 'short'), ('อิ', 'short'), ('อึ', 'short'), ('อุ', 'short'), ('เอะ', 'short'),
('แอะ', 'short'), ('โอะ', 'short'), ('เอาะ', 'short'), ('เออะ', 'short');
```

---

## 4. Table: `vowel_lessons`

แบบฝึกย่อยของสระแต่ละตัว — `lesson_order = 1` คือแบบฝึกสระเดี่ยว (ที่ใช้งานจริงตอนนี้)
ส่วน `lesson_order > 1` คือคำ (พยัญชนะ+สระ เช่น กา, ขา) ที่มีอยู่ในฐานข้อมูลแล้ว
แต่ **ยังไม่เปิดใช้ในแอปจริง** เพราะความแม่นยำของโมเดลสำหรับคำยังไม่พอ — เก็บไว้สำหรับอนาคต

**สิ่งที่เปลี่ยน:**
- ✅ เพิ่ม `category` ENUM('vowel','word') — บันทึกว่า lesson นี้เป็นสระเดี่ยวหรือคำ เป็น**ข้อมูลจริง**แทนที่จะให้ trigger ใน `practice_sessions` ต้องเดาจาก `lesson_order = 1` ทุกครั้ง (ตรวจสอบแล้วว่า backfill ถูกต้อง — ทุกสระมี lesson แบบ `'vowel'` พอดี 1 รายการ)
- ⏭️ `UNIQUE(vowel_id, lesson_order)` — ข้ามไว้ก่อน

| คอลัมน์ | ประเภท | คำอธิบาย |
|---|---|---|
| `id` | INT, PK, AUTO_INCREMENT | Lesson id |
| `vowel_id` | INT, FK → vowels.id | สระที่ lesson นี้สังกัด |
| `lesson_order` | INT | ลำดับ — 1 = สระเดี่ยว, 2+ = คำ (ยังไม่เปิดใช้) |
| `lesson_name` | VARCHAR(50) | ชื่อแบบฝึกย่อย เช่น อา, กา, ขา |
| `unicode_phonetic` | VARCHAR(50) | สัญลักษณ์ IPA |
| `category` 🆕 | ENUM('vowel','word') | `'vowel'` = สระเดี่ยว, `'word'` = คำ |

```sql
CREATE TABLE vowel_lessons (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  vowel_id         INT NOT NULL,
  lesson_order     INT NOT NULL,
  lesson_name      VARCHAR(50) NOT NULL,
  unicode_phonetic VARCHAR(50),
  category         ENUM('vowel','word') NOT NULL DEFAULT 'word',  -- 🆕
  FOREIGN KEY (vowel_id) REFERENCES vowels(id)
);
```

### โค้ดที่ใช้เพิ่ม + backfill `category` (รันแล้ว)

```sql
ALTER TABLE vowel_lessons
  ADD COLUMN category ENUM('vowel','word') NOT NULL DEFAULT 'word' AFTER lesson_name;

UPDATE vowel_lessons SET category = 'vowel' WHERE lesson_order = 1;

-- ตรวจสอบ (ต้องได้ 0 แถว) — ยืนยันแล้วว่าผ่าน
SELECT vowel_id, COUNT(*) AS vowel_category_rows
FROM vowel_lessons WHERE category = 'vowel'
GROUP BY vowel_id HAVING COUNT(*) <> 1;
```

---

## 5. Table: `user_lesson_progress`

บันทึกสถานะของ user แต่ละ lesson (สีบนการ์ด) — **ไม่มีการเปลี่ยนแปลง**
(พิจารณาเปลี่ยน `assessment_level` เป็น ENUM และเพิ่ม FK บน `firebase_uid` แล้ว แต่ตัดสินใจไม่ทำทั้งคู่)

| คอลัมน์ | ประเภท | Constraint | คำอธิบาย |
|---|---|---|---|
| `id` | INT | PK, AUTO_INCREMENT | — |
| `firebase_uid` | VARCHAR(128) | NOT NULL | เจ้าของ progress |
| `lesson_id` | INT | FK → vowel_lessons.id | แบบฝึกย่อยที่ทำ |
| `is_completed` | TINYINT(1) | DEFAULT 0 | 1 = สีเขียว, 0 = สีส้ม |
| `best_accuracy` | FLOAT | DEFAULT 0.0 | % accuracy สูงสุดที่เคยทำได้ |
| `assessment_level` | VARCHAR(20) | — | ระดับล่าสุด (Incorrect / Needs Improvement / Good / Excellent) — **คงเป็น free text ตามเดิม ไม่แปลงเป็น ENUM** |
| `attempts` | INT | DEFAULT 0 | ฝึก lesson นี้กี่ครั้งแล้ว |
| `last_practiced_at` | DATETIME | — | ฝึกครั้งล่าสุดเมื่อไหร่ |

```sql
CREATE TABLE user_lesson_progress (
  id                INT AUTO_INCREMENT PRIMARY KEY,
  firebase_uid      VARCHAR(128) NOT NULL,
  lesson_id         INT NOT NULL,
  is_completed      TINYINT(1) DEFAULT 0,
  best_accuracy     FLOAT DEFAULT 0.0,
  assessment_level  VARCHAR(20),
  attempts          INT DEFAULT 0,
  last_practiced_at DATETIME,
  UNIQUE KEY uq_user_lesson (firebase_uid, lesson_id),
  FOREIGN KEY (lesson_id) REFERENCES vowel_lessons(id)
);
```

**อัปเดตหลัง user ฝึกเสร็จ**
```sql
INSERT INTO user_lesson_progress
  (firebase_uid, lesson_id, is_completed, best_accuracy, assessment_level, attempts, last_practiced_at)
VALUES
  (?, ?, ?, ?, ?, 1, NOW())
ON DUPLICATE KEY UPDATE
  is_completed      = GREATEST(is_completed, VALUES(is_completed)),
  assessment_level  = IF(VALUES(best_accuracy) > best_accuracy, VALUES(assessment_level), assessment_level),
  best_accuracy     = GREATEST(best_accuracy, VALUES(best_accuracy)),
  attempts          = attempts + 1,
  last_practiced_at = NOW();
```

---

## 6. Table: `practice_sessions`

บันทึกทุกครั้งที่ user กด Record และได้ผลจาก AI model

**สิ่งที่เปลี่ยน:**
- ✅ แก้ trigger `trg_practice_sessions_category` ให้อ่านค่าจาก `vowel_lessons.category` (ข้อมูลจริง) แทนการเดาจาก `lesson_order = 1` ทุกครั้งที่ insert
- ⏭️ index `(firebase_uid, practiced_at)`, เปลี่ยน `assessment_level` เป็น ENUM, เพิ่ม FK บน `firebase_uid` — ข้ามไว้ก่อนทั้งหมด

| คอลัมน์ | ประเภท | Constraint | คำอธิบาย |
|---|---|---|---|
| `id` | INT | PK, AUTO_INCREMENT | — |
| `firebase_uid` | VARCHAR(128) | NOT NULL | เจ้าของ session |
| `lesson_id` | INT | FK → vowel_lessons.id | lesson ที่ฝึก |
| `confidence` | FLOAT | NOT NULL | ค่า confidence จาก CNN (ใช้แทน accuracy) |
| `assessment_level` | VARCHAR(20) | — | ระดับผลลัพธ์ (free text) |
| `is_passed` | TINYINT(1) | NOT NULL | ผ่านเกณฑ์หรือไม่ (confidence ≥ 0.51) |
| `category` | ENUM('vowel','word') | ตั้งค่าโดย trigger | 🆕 อ่านจาก `vowel_lessons.category` แล้ว |
| `duration_seconds` | INT | DEFAULT 0 | เวลาที่ใช้ต่อ session (วินาที) |
| `practiced_at` | DATETIME | DEFAULT CURRENT_TIMESTAMP | วันเวลาที่ฝึก |

```sql
CREATE TABLE practice_sessions (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  firebase_uid     VARCHAR(128) NOT NULL,
  lesson_id        INT NOT NULL,
  confidence       FLOAT NOT NULL,
  assessment_level VARCHAR(20),
  is_passed        TINYINT(1) NOT NULL,
  category         ENUM('vowel','word'),
  duration_seconds INT DEFAULT 0,
  practiced_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (lesson_id) REFERENCES vowel_lessons(id)
);
```

### Trigger (เวอร์ชันใหม่ที่แก้แล้ว)

```sql
DROP TRIGGER IF EXISTS trg_practice_sessions_category;

DELIMITER $$
CREATE TRIGGER trg_practice_sessions_category
BEFORE INSERT ON practice_sessions
FOR EACH ROW
BEGIN
  DECLARE v_category ENUM('vowel','word');
  SELECT category INTO v_category FROM vowel_lessons WHERE id = NEW.lesson_id;
  SET NEW.category = COALESCE(v_category, 'word');
END$$
DELIMITER ;
```

### Queries หลักที่ใช้ในหน้า Progress

**History list (เรียงล่าสุดก่อน)**
```sql
SELECT v.symbol, v.vowel_type, vl.lesson_name,
       ROUND(ps.confidence * 100, 1) AS confidence_pct,
       ps.is_passed, ps.practiced_at
FROM practice_sessions ps
JOIN vowel_lessons vl ON ps.lesson_id = vl.id
JOIN vowels v         ON vl.vowel_id  = v.id
WHERE ps.firebase_uid = ?
ORDER BY ps.practiced_at DESC
LIMIT 20;
```

**Average Accuracy donut (short vs long)**
```sql
SELECT v.vowel_type, ROUND(AVG(ps.confidence) * 100, 1) AS avg_confidence_pct
FROM practice_sessions ps
JOIN vowel_lessons vl ON ps.lesson_id = vl.id
JOIN vowels v         ON vl.vowel_id  = v.id
WHERE ps.firebase_uid = ?
GROUP BY v.vowel_type;
```

**สระที่ยังอ่อน (Weak vowels — 3 อันดับต่ำสุด)**
```sql
SELECT v.symbol, v.vowel_type,
       ROUND(AVG(ps.confidence) * 100, 1) AS avg_confidence_pct,
       COUNT(*) AS attempts
FROM practice_sessions ps
JOIN vowel_lessons vl ON ps.lesson_id = vl.id
JOIN vowels v         ON vl.vowel_id  = v.id
WHERE ps.firebase_uid = ?
GROUP BY v.id, v.symbol, v.vowel_type
ORDER BY avg_confidence_pct ASC
LIMIT 3;
```

---

## 7. Table: `practice_pair_sessions` 🆕 (ยังไม่ได้สร้างจริงในฐานข้อมูล)

เก็บผลแบบฝึก "สระเสียงใกล้เคียงกัน" (เช่น อะ → อา) — อัดเสียงครั้งเดียว พูดสองเสียงต่อกัน
ส่งไป `/model/predict_pair` แล้วได้คะแนนแยกกลับมา 2 ค่า (`segment1`, `segment2`)
ตอนนี้ frontend (`PairRecordingPage`) แสดงผลอย่างเดียว **ยังไม่บันทึกลงฐานข้อมูล** — ตารางนี้คือที่ที่จะเก็บผลนั้น

**เหตุผลที่แยกตารางใหม่แทนการยัดใส่ `practice_sessions`:** การฝึกคู่สระมี 2 คะแนน + ไม่มี `lesson_id` เดียว (ไม่ผูกกับ lesson แบบคำ) ถ้ายัดใส่ตารางเดิมจะทำให้ query/logic เดิมของ `practice_sessions` ซับซ้อนขึ้นโดยไม่จำเป็น

| คอลัมน์ | ประเภท | คำอธิบาย |
|---|---|---|
| `id` | INT, PK, AUTO_INCREMENT | — |
| `firebase_uid` | VARCHAR(128) | เจ้าของ session |
| `short_vowel_id` | INT, FK → vowels.id | สระสั้นที่ฝึก (เช่น อะ) |
| `long_vowel_id` | INT, FK → vowels.id | สระยาวที่ฝึก (เช่น อา) |
| `confidence_short` | FLOAT | คะแนนของเสียงสั้น |
| `confidence_long` | FLOAT | คะแนนของเสียงยาว |
| `assessment_level_short` / `_long` | VARCHAR(20) | ระดับผลลัพธ์แยกแต่ละเสียง (free text ตามแพทเทิร์นตารางอื่น) |
| `is_passed` | TINYINT(1), คำนวณอัตโนมัติ | ผ่านทั้งคู่ (สั้น**และ**ยาว ≥ 0.51) ถึงจะนับว่าผ่าน — ตรงกับ logic ที่ UI ใช้อยู่แล้ว |
| `user_f1_short` / `user_f2_short` | FLOAT | ค่า formant ของเสียงสั้นที่ผู้ใช้พูด |
| `user_f1_long` / `user_f2_long` | FLOAT | ค่า formant ของเสียงยาวที่ผู้ใช้พูด |
| `duration_seconds` | INT | เวลาที่ใช้อัด |
| `practiced_at` | DATETIME | วันเวลาที่ฝึก |

```sql
CREATE TABLE practice_pair_sessions (
  id                      INT AUTO_INCREMENT PRIMARY KEY,
  firebase_uid            VARCHAR(128) NOT NULL,
  short_vowel_id          INT NOT NULL,
  long_vowel_id           INT NOT NULL,

  confidence_short        FLOAT NOT NULL,
  confidence_long         FLOAT NOT NULL,

  assessment_level_short  VARCHAR(20),
  assessment_level_long   VARCHAR(20),

  is_passed  TINYINT(1) GENERATED ALWAYS AS
               (confidence_short >= 0.51 AND confidence_long >= 0.51) STORED,

  user_f1_short FLOAT, user_f2_short FLOAT,
  user_f1_long  FLOAT, user_f2_long  FLOAT,

  duration_seconds INT DEFAULT 0,
  practiced_at     DATETIME DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (short_vowel_id) REFERENCES vowels(id),
  FOREIGN KEY (long_vowel_id)  REFERENCES vowels(id)
);
```

**บันทึก session ใหม่ (หลัง Flask ส่งผล `/predict_pair` กลับมา)**
```sql
INSERT INTO practice_pair_sessions
  (firebase_uid, short_vowel_id, long_vowel_id, confidence_short, confidence_long,
   assessment_level_short, assessment_level_long,
   user_f1_short, user_f2_short, user_f1_long, user_f2_long, duration_seconds)
VALUES
  (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
```

**สถานะ FK บน `firebase_uid`:** ยังไม่ตัดสินใจ (ตามแพทเทิร์นตารางอื่นๆ ที่ข้ามไว้)

### แผนการแสดงผลใน History card (คุยไว้แล้ว ยังไม่ได้สร้าง)

ต้องการให้ History card ในหน้า Progress รวมทั้งสองแบบไว้ใน list เดียว เรียงตามเวลา —
แถวของการฝึกสระเดี่ยวแสดงแบบเดิม ส่วนแถวของการฝึกคู่สระจะยุบแสดงเหมือนแถวปกติ 1 แถว
แล้วมี dropdown ให้กดขยายดูคะแนนแยกของแต่ละเสียง (สั้น/ยาว) เมื่อต้องการ
ต้องรอ: (1) สร้างตารางนี้จริงในฐานข้อมูล (2) เพิ่ม endpoint `POST /practice_pair_sessions`
(3) แก้ `GET /practice_sessions/recent` ให้ UNION สองตารางเข้าด้วยกัน (4) แก้ frontend model/widget

---

## Flow การทำงาน (Flutter → Flask → MySQL)

### แบบฝึกสระเดี่ยว (มีอยู่แล้ว)
```
1. User กด Record
   └── Flutter จับเวลาเริ่ม (duration)

2. ส่งไฟล์เสียงไปยัง Flask /model/predict (พร้อม index = vowel.model_class_index)
   └── Flask ส่งกลับ: { class_id, confidence, user_formants }

3. Flutter รับผลแล้ว INSERT practice_sessions
   └── firebase_uid, lesson_id, confidence, assessment_level, is_passed, duration_seconds
   └── trigger เติม category ให้อัตโนมัติจาก vowel_lessons.category

4. Flutter UPDATE user_lesson_progress
   └── is_completed, best_accuracy, assessment_level, attempts, last_practiced_at

5. Flutter UPDATE user_streaks
   └── ตรวจ last_practice_date แล้ว streak++ หรือ reset + อัปเดต longest_streak
```

### แบบฝึกคู่สระ (ใหม่ — ฝั่งแสดงผลเสร็จแล้ว ฝั่งบันทึกยังไม่เสร็จ)
```
1. User กด Record พูดสระสั้นแล้วต่อด้วยสระยาวในคลิปเดียว

2. ส่งไฟล์เสียงไปยัง Flask /model/predict_pair
   (พร้อม index1 = short.model_class_index, index2 = long.model_class_index)
   └── Flask แยกเสียงเป็น 2 ช่วง แล้วส่งกลับ: { segment1: {...}, segment2: {...} }

3. Flutter แสดงผลใน dialog (pair_result_modal.dart) — ✅ เสร็จแล้ว

4. [ยังไม่ทำ] Flutter ควร INSERT practice_pair_sessions
   └── ต้องมี endpoint POST /practice_pair_sessions ใน apiservice.py ก่อน

5. [ยังไม่ทำ] Flutter ควร UPDATE user_streaks เหมือนแบบฝึกสระเดี่ยว
```

---

## สรุปตาราง

| ตาราง | จำนวน rows (ประมาณ) | หน้าที่ |
|---|---|---|
| `users` | 1 ต่อ user | เก็บ account |
| `user_streaks` | 1 ต่อ user | เก็บ streak ต่อเนื่อง |
| `vowels` | 18 (fixed) | รายชื่อสระ + ข้อมูลอ้างอิงสำหรับ ML/การจับคู่ |
| `vowel_lessons` | ขึ้นกับจำนวน lesson ต่อสระจริงในฐานข้อมูล | แบบฝึกย่อย (สระเดี่ยว + คำ) |
| `user_lesson_progress` | user × lesson | สถานะสีการ์ด |
| `practice_sessions` | ทุกครั้งที่ record แบบสระเดี่ยว | ประวัติ + dashboard |
| `practice_pair_sessions` 🆕 | ทุกครั้งที่ record แบบคู่สระ | ประวัติการฝึกคู่สระ (ยังไม่มีข้อมูลจนกว่าจะสร้าง endpoint บันทึก) |
