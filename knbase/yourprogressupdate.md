# Your Progress — Page Specification

> Analytics dashboard for the Thai Vowel Pronunciation App.
> Shows the user how much they've practiced, how accurate they are, and how they're improving over time.

---

## 1. Page header

| Element | Spec |
|---|---|
| Title | **"Your Progress"** |
| Left | Back arrow → returns to Home |
| Background | Card surface · sticky on scroll |
| Height | 64 dp |

---

## 2. Summary hero card

A gradient banner at the top — the page's "first impression" stat.

| Element | Value | Source |
|---|---|---|
| Big number | **76%** | `AVG(confidence) * 100` across all `practice_sessions` for `firebase_uid` |
| Label | "OVERALL ACCURACY" | static |
| Stat 1 | Sessions: **124** | `COUNT(*) FROM practice_sessions WHERE firebase_uid = ?` |
| Stat 2 | Best: **98%** | `MAX(confidence) * 100` |
| Stat 3 | Streak: **7 🔥** | `current_streak` from `user_streaks` |

**Design notes**
- Linear gradient from `--c-primary` → `--c-primary-deep` (Mint Macaron: `#10b981 → #047857`)
- White text · large 44px display number
- Decorative 📊 emoji at 18% opacity, top-right corner
- Border radius 22 dp

---

## 3. Practice Count — bar chart

| Property | Detail |
|---|---|
| Chart type | Vertical bar |
| X-axis | All 9 vowels of the selected length type |
| Y-axis | Session count per vowel |
| Bars | Gradient `--c-primary-soft → --c-primary` |
| Filter pill | top-right · toggles **"long vowels" ↔ "short vowels"** |

**SQL**
```sql
SELECT v.symbol, v.vowel_type, COUNT(*) AS session_count
FROM practice_sessions ps
JOIN vowel_lessons vl ON ps.lesson_id = vl.id
JOIN vowels v ON vl.vowel_id = v.id
WHERE ps.firebase_uid = ?
  AND v.vowel_type = ?  -- 'long' or 'short' from dropdown
GROUP BY v.id, v.symbol
ORDER BY v.id;
```

---

## 4. Average Accuracy — twin donut charts

Two circular gauges side by side comparing **long** vs **short** vowel performance.

| Donut | Value | Color |
|---|---|---|
| Long vowels | **71%** | `--c-primary` (mint green) |
| Short vowels | **43%** | `--c-warning` (orange — needs work) |

**Why both?** Tells the user instantly whether their weakness is *duration control* or *articulation*.

**SQL**
```sql
SELECT v.vowel_type, ROUND(AVG(ps.confidence) * 100, 1) AS avg_confidence_pct
FROM practice_sessions ps
JOIN vowel_lessons vl ON ps.lesson_id = vl.id
JOIN vowels v ON vl.vowel_id = v.id
WHERE ps.firebase_uid = ?
GROUP BY v.vowel_type;
```

---

## 5. Accuracy Trend — line chart with date filtering ⭐ **NEW**

The improvement-over-time chart. Now supports flexible time ranges so users can zoom in/out of their learning curve.

### 5.1 Period segmented control

Four buttons in a single row, segmented-control style.

| Button | What it shows |
|---|---|
| **Week** (default) | Last 7 days · X-axis = Sun, Mon, Tue, …, Sat |
| **Month** | Last 4 weeks · X-axis = W1, W2, W3, W4 |
| **Year** | Last 12 months · X-axis = J, F, M, A, …, D |
| **📅 Custom** | Opens the date range picker modal |

- Active button: filled `--c-primary` background, white text
- Inactive: transparent, soft ink color
- Single row, equal flex; rounded 12 dp container

### 5.2 Custom date range modal (bottom sheet)

When the user taps **Custom**, a bottom sheet slides up from the bottom of the screen.

**Modal contents (top to bottom):**

1. **Drag handle** — small pill at top, visual affordance for sheets
2. **Title** "Pick date range 📅"
3. **Quick range chips** (4 chips, horizontally wrapped)
   - Last 7 days · Last 14 days · Last 30 days · Last 90 days
   - Tapping any chip auto-fills the start/end fields
4. **Two date inputs** with an arrow between them
   - Native HTML `<input type="date">` — gives the OS-native picker on iOS/Android
   - Start ← → End
5. **Mini calendar visual** showing the selected month
   - 7-column grid (S M T W T F S)
   - Selected start/end days: filled mint primary
   - Days in between: filled `--c-primary-soft` (range highlight)
   - Tapping a day extends the range
6. **Action row**
   - Cancel button (secondary, outlined) — closes without saving
   - "Apply range" button (primary, filled `--c-primary`) — applies and closes

**Interaction**
- Tap outside the sheet → cancel
- Drag the handle down → cancel (visual affordance; native dismissal)
- Apply → updates the trend chart + sets period to "custom"

### 5.3 Chart itself

- SVG line chart, area-filled with gradient (primary tint)
- Latest point: large filled dot in primary color
- Other points: small ring (primary border, card background fill)
- Gridlines at 20 / 50 / 80% with mono-font labels
- X-axis labels adapt per period (and skip every-other for year view to avoid overlap)

### 5.4 Trend summary line (below chart)

| Left | Right |
|---|---|
| **Avg 67%** (average across visible data) | **↗ +16% over week** (delta from first to last point) |

- Up arrow + success color if improving
- Down arrow + warning color if declining
- Period word changes based on filter ("over month", "over year", "over range")

### 5.5 Filter pill (long/short)

Still available at the bottom-right of the chart area — filters which vowel type's accuracy is shown.

### 5.6 SQL — flexible time-range query

```sql
SELECT
  DATE(ps.practiced_at)              AS day,
  DAYNAME(ps.practiced_at)           AS day_name,
  ROUND(AVG(ps.confidence) * 100, 1) AS avg_confidence_pct,
  COUNT(*)                           AS session_count
FROM practice_sessions ps
JOIN vowel_lessons vl ON ps.lesson_id = vl.id
JOIN vowels v ON vl.vowel_id = v.id
WHERE ps.firebase_uid = ?
  AND v.vowel_type    = ?           -- 'long' or 'short'
  AND ps.practiced_at >= ?          -- range start (ISO date)
  AND ps.practiced_at <= ?          -- range end (ISO date)
GROUP BY DATE(ps.practiced_at)
ORDER BY day;
```

For monthly/yearly views, group by `WEEK()` or `MONTH()` instead of `DATE()`.

---

## 6. Recent Sessions — history list

Scrollable list of the most recent attempts.

**Per row:**
- Left chip: vowel symbol on tinted background (mint tint for long, orange tint for short)
- Middle: "Long vowel" / "Short vowel" label + relative date ("Today · 14:32", "Yesterday · 19:04", "May 16 · 20:11")
- Right: accuracy pill (green if `is_passed = TRUE`, orange otherwise)

**"See all →"** link in section header opens the full history view.

**SQL**
```sql
SELECT v.symbol, v.vowel_type, vl.lesson_name,
       ROUND(ps.confidence * 100, 1) AS confidence_pct,
       ps.is_passed, ps.practiced_at
FROM practice_sessions ps
JOIN vowel_lessons vl ON ps.lesson_id = vl.id
JOIN vowels v ON vl.vowel_id = v.id
WHERE ps.firebase_uid = ?
ORDER BY ps.practiced_at DESC
LIMIT 20;
```

---

## 7. Data behind your score — schema visualization

An educational/thesis-flavored card showing the 6-table ERD as a friendly visual.

| Card | Icon | Color | Key fields |
|---|---|---|---|
| `users` | 👤 | mint | `firebase_uid · username · gender · age` |
| `user_streaks` | 🔥 | orange | `current_streak · longest_streak · last_practice_date` |
| `vowels` | อ | green | `symbol · vowel_type` |
| `vowel_lessons` | 📚 | green | `vowel_id ↗ · lesson_order · lesson_name` |
| `user_lesson_progress` | ✓ | mint | `lesson_id ↗ · is_completed · best_accuracy` |
| `practice_sessions` | 🎙️ | red | `lesson_id ↗ · predicted_vowel_id ↗ · confidence · is_passed` |

Below the grid, a friendly explainer:
> "Every time you press **record**, the app saves a row into `practice_sessions` with your confidence score, then updates progress + streak."

Useful for thesis presentations — shows how the front-end metric ties back to the database.

---

## 8. Vowels to work on — weak-vowels CTA list

Surfaces the 3 vowels where the user's average confidence is lowest. Each row offers a one-tap "Try again" jump back to the practice room for that specific vowel.

| Per row | |
|---|---|
| Vowel chip | tinted card with the Thai symbol |
| Stats | "Average 47%" + "4 attempts" |
| Action | Orange "Try again" pill button → `practiceRoom?vowelId=N` |

**SQL**
```sql
SELECT v.symbol, v.vowel_type,
       ROUND(AVG(ps.confidence) * 100, 1) AS avg_confidence_pct,
       COUNT(*) AS attempts
FROM practice_sessions ps
JOIN vowel_lessons vl ON ps.lesson_id = vl.id
JOIN vowels v ON vl.vowel_id = v.id
WHERE ps.firebase_uid = ?
GROUP BY v.id, v.symbol, v.vowel_type
ORDER BY avg_confidence_pct ASC
LIMIT 3;
```

---

## 9. Visual / token reference

| Token | Value | Used on |
|---|---|---|
| `--c-primary` | `#10b981` | Primary lines, bars, active pills, hero gradient start |
| `--c-primary-deep` | `#047857` | Hero gradient end |
| `--c-primary-soft` | `#a7f3d0` | Bar gradient bottom, calendar range fill |
| `--c-primary-tint` | `#ecfdf5` | Card subtle fills, info banners |
| `--c-success` | `#22c55e` | Passed badge |
| `--c-success-tint` | `#dcfce7` | Long-vowel chip bg |
| `--c-warning` | `#f97316` | Short-vowel donut, failed state, weak-vowel CTA |
| `--c-warning-tint` | `#ffedd5` | Short-vowel chip bg |
| `--c-bg` | `#f4faf7` | Page background |
| `--c-bg-card` | `#ffffff` | Card surfaces |
| `--c-ink` | `#022c22` | Primary text |
| `--c-ink-soft` | `#475569` | Secondary text |
| `--c-ink-mute` | `#94a3b8` | Tertiary text, gridline labels |
| `--c-border` | `rgba(2,44,34,0.08)` | Card borders, dividers |

**Typography**
- Display + UI: **Plus Jakarta Sans** (400 / 500 / 700 / 800)
- Thai glyphs: **IBM Plex Sans Thai** (400 / 700)
- Numeric / IPA: **JetBrains Mono** (500)

**Radii**
- Cards: 22 dp
- Pills / chips: 999 (full round)
- Small chips: 12 dp
- Bottom sheet: 24 dp top-only

**Spacing**
- Page padding: 14 px sides, 16 px content gutter
- Card inner padding: 14 px
- Vertical rhythm between cards: 14 px

---

## 10. State management

| State | Type | Default |
|---|---|---|
| `filter` | `'long' \| 'short'` | `'long'` |
| `trendPeriod` | `'week' \| 'month' \| 'year' \| 'custom'` | `'week'` |
| `dateRange` | `{ start: ISO, end: ISO }` | last 7 days |
| `showRangePicker` | `boolean` | `false` |

All UI updates are derived from these — no external store needed. In Flutter, hold these in a `StatefulWidget` or `Provider`.

---

## 11. Edge cases & accessibility

- **No data yet** — show empty state on each card ("Practice a few times to see your trend!")
- **Single session** — trend chart shows a single dot with a horizontal dashed line
- **Future-dated start** — clamp `start <= end <= today`
- **Date input → keyboard nav** — native pickers handle this on both platforms
- **Touch targets** — all interactive pills ≥ 32 dp tall; calendar day cells ≥ 32 dp; CTA buttons ≥ 44 dp
- **Color-blind users** — every state combines color + icon (✓ / ✗ / ↗ / ↘), never color alone

---

## 12. Quick implementation checklist (Flutter)

- [ ] `progress_screen.dart` — scaffold + `ListView` of cards
- [ ] `summary_hero.dart` — gradient banner stat block
- [ ] `practice_count_chart.dart` — bar chart (use `fl_chart` package)
- [ ] `accuracy_donuts.dart` — two `CircularPercentIndicator` widgets
- [ ] `accuracy_trend.dart` — line chart + period segmented control
- [ ] `date_range_sheet.dart` — `showModalBottomSheet` with quick chips + native date pickers + custom mini calendar
- [ ] `history_list.dart` — `ListView.builder` of session rows
- [ ] `weak_vowels.dart` — top-3 query results with CTA buttons
- [ ] `schema_viz.dart` — static decorative grid (optional)
- [ ] API: `GET /progress?range=...&filter=...` returns combined payload

---

**File maps to:** `src/screens-feedback.jsx → ScreenProgress` in the prototype.
