# Frontend Update Guide — Thai Vowel Pronunciation App

> Changes the **Flutter** app must apply after the latest backend + database update.
> Stack: Flutter → Flask (this repo) → MySQL + Firebase Auth

---

## TL;DR — what changed

| # | Area | Change | Frontend action |
|---|---|---|---|
| 1 | API | New endpoint **`/predict3`** (CNN+LSTM + Mel model) | Switch recording upload to it (or add as option) |
| 2 | Scoring | **`is_passed` threshold 70% → 51%** | Update pass/fail logic |
| 3 | Scoring | New **4-level assessment** (Incorrect / Needs Improvement / Good / Excellent) | Show level label; compute & store it |
| 4 | DB | `users.nationality` added | Collect + send on sign-up |
| 5 | DB | `assessment_level` added to `practice_sessions` **and** `user_lesson_progress` | Send on every save |
| 6 | Lessons | **6 lessons per vowel** (was 9) | Practice grid now shows 6 cards |
| 7 | Vowels | New symbols (`อา`…), full guidance text, YouTube links | Re-pull vowel data |

---

## 1. New API endpoint — `/predict3`

Same request/response contract as `/predict2`, but runs the **CNN+LSTM + Mel** model
(`exp_cnnlstm_mel_model.h5`) with a peak-energy crop pipeline.

**Through `main.py` dispatcher:** `http://localhost:4000/model/predict3`

**Request** — `multipart/form-data`
| field | type | notes |
|---|---|---|
| `file` | WAV file | the recording |
| `index` | int (0–17) | the **target** vowel class id |

**Response** — `application/json`
```json
{
  "class_id": 0,
  "confidence": 0.87,
  "user_formants": { "F1": 800.0, "F2": 1200.0 }
}
```

- `confidence` is the model's probability **for the class you sent as `index`** (0.0–1.0), not the argmax.
- `class_id` echoes back your `index`.
- Old `/predict` (argmax) and `/predict2` still exist — `/predict3` is additive.

---

## 2 & 3. Scoring rule + assessment levels (Table VIII)

Convert `confidence` (0.0–1.0) to a whole-number percent first, then map:

| Accuracy (%) | Assessment level | `is_passed` |
|---|---|---|
| < 30 | Incorrect | 0 |
| 30 – 50 | Needs Improvement | 0 |
| 51 – 80 | **Good** | **1** |
| 81 – 100 | **Excellent** | **1** |

> **Rule:** `is_passed = 1` ⟺ accuracy ≥ 51% (i.e. at least *Good*).
> This replaces the old ≥ 70% threshold.

**Dart helper:**
```dart
int accuracyPct(double confidence) => (confidence * 100).round(); // 0–100

String assessmentLevel(int pct) =>
    pct < 30  ? 'Incorrect'
  : pct <= 50 ? 'Needs Improvement'
  : pct <= 80 ? 'Good'
  :             'Excellent';

int isPassed(int pct) => pct >= 51 ? 1 : 0;
```

Rounding to a whole percent first avoids the 50–51 / 80–81 gaps in the table.

---

## 4. `users.nationality`

New column: `VARCHAR(100) NOT NULL DEFAULT 'Thai'`.

- Add a nationality field to the sign-up / demographic form (defaults to `Thai`).
- Include it in the user INSERT:

```sql
INSERT INTO users (firebase_uid, username, email, gender, age, nationality, login_provider)
VALUES (?, ?, ?, ?, ?, ?, ?);
```

---

## 5. `assessment_level` columns

`assessment_level VARCHAR(20)` was added to **both** tables. Compute it with
`assessmentLevel()` above and send it on every save.

**`practice_sessions` INSERT (after each recording):**
```sql
INSERT INTO practice_sessions
  (firebase_uid, lesson_id, confidence, assessment_level, is_passed, duration_seconds)
VALUES (?, ?, ?, ?, ?, ?);
```

**`user_lesson_progress` upsert:** `assessment_level` only changes when a new
**best** score is reached (stays in sync with `best_accuracy`):
```sql
INSERT INTO user_lesson_progress
  (firebase_uid, lesson_id, is_completed, best_accuracy, assessment_level, attempts, last_practiced_at)
VALUES (?, ?, ?, ?, ?, 1, NOW())
ON DUPLICATE KEY UPDATE
  is_completed     = GREATEST(is_completed, VALUES(is_completed)),
  assessment_level = IF(VALUES(best_accuracy) > best_accuracy, VALUES(assessment_level), assessment_level),
  best_accuracy    = GREATEST(best_accuracy, VALUES(best_accuracy)),
  attempts         = attempts + 1,
  last_practiced_at = NOW();
```
> ⚠️ Keep the `assessment_level` line **before** the `best_accuracy` line — it
> compares against the *old* best, which only works if `best_accuracy` hasn't been updated yet.

---

## 6. Lessons reduced to 6 per vowel

- Each vowel now has **6 lessons** (was 9): words **ก ข ง จ ซ ด**.
- Practice page grids that hardcoded 9 cards / “x/9” must become **6** / “x/6”.
- Lesson IDs were renumbered (6 per vowel): vowel 1 → 1–6, vowel 2 → 7–12, … vowel 9 → 49–54, … vowel 18 → 103–108.
- **Don't hardcode lesson IDs** — always read them from `vowel_lessons` for the selected vowel.

---

## 7. Vowel content changes

The `vowels` table data was replaced. Re-fetch instead of caching old values.

- `symbol` now uses standalone forms: `อา`, `อี`, `อือ`, … (was `-า`, `-ี`, …).
- `description_en` / `description_th` now contain full step-by-step pronunciation guidance.
- `lips_*`, `tongue_*`, `jaw_*` text updated (e.g. tongue is now `Low-central`, `High-front`, …).
- `link_video` populated for vowels 1 & 2 (YouTube); `NULL` for the rest → hide the video button when null.
- `f1` / `f2` / `unicode_phonetic` unchanged in meaning.

---

## Migration checklist (run once on the live DB)

```sql
ALTER TABLE users
  ADD COLUMN nationality VARCHAR(100) NOT NULL DEFAULT 'Thai' AFTER age;

ALTER TABLE practice_sessions
  ADD COLUMN assessment_level VARCHAR(20) DEFAULT NULL AFTER confidence;

ALTER TABLE user_lesson_progress
  ADD COLUMN assessment_level VARCHAR(20) DEFAULT NULL AFTER best_accuracy;
```

Then re-run `seed_dump.sql` (it truncates + reseeds with the new structure).

See `database_guide.md` for the full schema and dashboard queries.
