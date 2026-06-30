# DTW Waveform Visualization Plan

## Overview

Replace the current Flutter-side WAV decoding + waveform drawing with a
backend-computed DTW alignment. Flask loads the reference audio, aligns it
with the user recording using DTW, and returns both waveforms as normalized
arrays. Flutter receives and draws them directly.

---

## Why DTW

The current approach draws reference and user waveforms independently — if the
user speaks slightly faster or slower than the reference, the bars will not
align visually even when the pronunciation is correct. DTW (Dynamic Time
Warping) warps the time axis of both signals so similar acoustic events line
up, making the comparison visually meaningful.

---

## Architecture Change

```
BEFORE
------
Flutter  →  records audio
         →  loads reference WAV from assets/
         →  decodes both WAVs (decodePcmWav)
         →  preprocesses (preprocessSamples)
         →  draws two waveforms independently

AFTER
-----
Flutter  →  records audio  →  POST /predict3 (file + index)
Flask    →  loads reference WAV from server assets
         →  extracts downsampled arrays from both
         →  runs DTW to align user → reference timeline
         →  returns aligned arrays + confidence + formants
Flutter  →  draws ref_wave and user_wave from response
```

---

## Backend Changes (Flask `/predict3`)

### New response fields

```json
{
  "class_id":      0,
  "confidence":    0.87,
  "user_formants": { "F1": 800.0, "F2": 1200.0 },
  "ref_wave":      [0.00, 0.12, 0.45, ...],
  "user_wave":     [0.00, 0.10, 0.41, ...]
}
```

- `ref_wave` — 200-point normalized reference signal  
- `user_wave` — 200-point user signal, DTW-aligned to the reference timeline  
- Both arrays are in range `[-1.0, 1.0]`

### Python logic to add

```python
import numpy as np
from scipy.spatial.distance import cdist

REF_AUDIO_DIR = "assets/references"   # server-side reference WAVs

def load_ref_wave(vowel_id: int, lesson_order: int) -> np.ndarray:
    """Load and downsample reference WAV to 200 points."""
    path = f"{REF_AUDIO_DIR}/{vowel_id}/{lesson_order}.wav"
    # read PCM, normalize to [-1, 1], downsample to 200 pts
    ...

def dtw_align(ref: np.ndarray, user: np.ndarray) -> np.ndarray:
    """Return user signal resampled onto the reference timeline via DTW path."""
    # cost matrix
    D = cdist(ref.reshape(-1, 1), user.reshape(-1, 1), metric='euclidean')
    # cumulative cost + traceback
    N, M = D.shape
    C = np.full((N, M), np.inf)
    C[0, 0] = D[0, 0]
    for i in range(1, N):
        C[i, 0] = C[i-1, 0] + D[i, 0]
    for j in range(1, M):
        C[0, j] = C[0, j-1] + D[0, j]
    for i in range(1, N):
        for j in range(1, M):
            C[i, j] = D[i, j] + min(C[i-1,j], C[i,j-1], C[i-1,j-1])
    # traceback
    path = []
    i, j = N - 1, M - 1
    while i > 0 or j > 0:
        path.append((i, j))
        moves = [(i-1,j), (i,j-1), (i-1,j-1)]
        i, j = min(((r,c) for r,c in moves if r>=0 and c>=0),
                   key=lambda rc: C[rc[0]][rc[1]])
    path.append((0, 0))
    path.reverse()
    # map user samples onto ref timeline (200 pts)
    aligned = np.array([user[j] for _, j in path])
    # resample aligned to exactly 200 points
    indices = np.linspace(0, len(aligned) - 1, 200).astype(int)
    return aligned[indices]

def to_wave_array(signal: np.ndarray, n: int = 200) -> list:
    """Downsample and normalize a signal to n points in [-1, 1]."""
    indices = np.linspace(0, len(signal) - 1, n).astype(int)
    s = signal[indices].astype(float)
    peak = np.max(np.abs(s))
    return (s / peak).tolist() if peak > 0 else s.tolist()
```

### Updated `/predict3` endpoint (additions only)

```python
# after existing prediction logic:
ref_signal  = load_ref_wave(vowel_id, lesson_order)   # from request fields
user_signal = load_user_wave(cropped_wav)              # already cropped

ref_wave  = to_wave_array(ref_signal)
user_wave = to_wave_array(dtw_align(ref_signal, user_signal))

return jsonify({
    "class_id":      class_id,
    "confidence":    confidence,
    "user_formants": user_formants,
    "ref_wave":      ref_wave,
    "user_wave":     user_wave,
})
```

> **Request must also send `lesson_order`** (or the server derives it from `index`)
> so Flask knows which reference file to load.

---

## Frontend Changes (Flutter)

### 1. `PredictResult` — add wave arrays

**`lib/services/class/predict_result.dart`**

```dart
class PredictResult {
  final double confidence;
  final bool isPassed;
  final String assessmentLevel;
  final double userF1;
  final double userF2;
  final List<double> refWave;   // NEW
  final List<double> userWave;  // NEW

  factory PredictResult.fromJson(Map<String, dynamic> j) {
    ...
    return PredictResult(
      ...
      refWave:  (j['ref_wave']  as List? ?? []).map((e) => (e as num).toDouble()).toList(),
      userWave: (j['user_wave'] as List? ?? []).map((e) => (e as num).toDouble()).toList(),
    );
  }
}
```

### 2. `recording_page.dart` — remove local WAV loading

Remove:
- `_loadRefWaveform()` — no longer needed (assets/ not used for waveform)
- `_loadUserWaveform()` — no longer needed
- `Future.wait([...])` call

Replace with:
```dart
// In _submitToApi, after predict():
setState(() {
  _refSamples  = result.refWave;
  _userSamples = result.userWave;
  ...
});
```

### 3. Fix `_buildSuggestion` formant comparison

```dart
// BEFORE (buggy — compares raw Hz values)
final f1Diff      = _userF1;
final f1Threshold = ref.f1;

// AFTER (correct — compares deviation from reference)
final f1Diff      = _userF1 - ref.f1;
final f1Threshold = 100.0;   // Hz margin
final f2Diff      = _userF2 - ref.f2;
final f2Threshold = 200.0;
```

Also hide suggestion when score is Good or Excellent:

```dart
if (suggestion.isNotEmpty && !passed) ...[
  // show suggestion
]
```

### 4. `vowel_utils.dart` — remove unused code

Once the backend returns arrays, these are no longer called:
- `decodePcmWav()`
- `preprocessSamples()`

They can be kept for reference or deleted.

---

## Files Changed Summary

| File | Change |
|---|---|
| `Flask /predict3` | Add DTW + `ref_wave` / `user_wave` to response |
| `lib/services/class/predict_result.dart` | Add `refWave`, `userWave` fields |
| `lib/pages/practice/recording_page.dart` | Remove local WAV loading; fix suggestion bug |
| `lib/services/vowel_utils.dart` | `decodePcmWav` / `preprocessSamples` become unused |
| `lib/widgets/waveform_display.dart` | No change — already draws any two arrays |

---

## Checklist

- [ ] Server has reference WAV files accessible at runtime
- [ ] Request sends `lesson_order` (or `index` maps to filename)
- [ ] DTW tested on a sample pair before wiring to endpoint
- [ ] `ref_wave` / `user_wave` validated as 200-point float arrays
- [ ] Flutter `PredictResult` updated
- [ ] `recording_page.dart` `_submitToApi` simplified
- [ ] Suggestion bug fixed (formant diff + hide when passed)
