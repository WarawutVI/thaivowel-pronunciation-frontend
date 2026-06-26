import os
import numpy as np
import tensorflow as tf
import librosa
from flask import Flask, request, jsonify
from pydub import AudioSegment
from scipy.signal import resample as scipy_resample
from fastdtw import fastdtw
from functions import detect_leading_silence, wav2mfcc, get_formants, smart_crop, extract_mel
from flask_cors import CORS

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})

BASE_DIR  = os.path.dirname(os.path.abspath(__file__))
TEMP_DIR  = os.path.join(BASE_DIR, "temp")
os.makedirs(TEMP_DIR, exist_ok=True)

MODEL_PATH = os.environ.get('MODEL_PATH', os.path.join(BASE_DIR, "models", "thesis1model.h5"))
model = tf.keras.models.load_model(MODEL_PATH)

# CNN+LSTM + Mel model — input shape (None, 128, 18, 1). See ref/realworld_test.ipynb
MEL_MODEL_PATH = os.environ.get('MEL_MODEL_PATH', os.path.join(BASE_DIR, "models", "exp_cnnlstm_mel_model.h5"))
mel_model = tf.keras.models.load_model(MEL_MODEL_PATH)


def prepare_audio(temp_path):
    """Trim leading/trailing silence and take the middle 50%, with guards so the
    clip never becomes empty (which would yield a 0-sample processed.wav)."""
    sound = AudioSegment.from_file(temp_path)

    start = detect_leading_silence(sound)
    end   = detect_leading_silence(sound.reverse())

    # Guard 1: if silence trimming would consume the whole clip, keep the original.
    trimmed = sound[start: len(sound) - end] if start + end < len(sound) else sound

    # Guard 2: only take the middle 50% if enough audio remains (>= 100 ms).
    trim_amt    = int(0.25 * len(trimmed))
    middle      = trimmed[trim_amt: len(trimmed) - trim_amt]
    final_sound = middle if len(middle) >= 100 else trimmed

    processed_wav = os.path.join(TEMP_DIR, "processed.wav")
    final_sound.export(processed_wav, format="wav")
    return processed_wav


@app.route('/predict', methods=['POST', 'OPTIONS'])
def predict():
    if request.method == 'OPTIONS':
        return jsonify({}), 200

    if 'file' not in request.files:
        return jsonify({"error": "No file uploaded"}), 400

    audio_file = request.files['file']
    temp_path  = os.path.join(TEMP_DIR, "temp_incoming.wav")
    audio_file.save(temp_path)

    try:
        processed_wav = prepare_audio(temp_path)

        feature    = wav2mfcc(processed_wav, max_len=14, n_mfcc=20)
        feature    = feature[np.newaxis, ..., np.newaxis]
        prediction = model.predict(feature)
        class_id   = int(np.argmax(prediction))
        confidence = float(np.max(prediction))
        print(f"Predicted Class: {class_id}, Confidence: {confidence:.4f}")

        user_formants = get_formants(processed_wav)
        print(f"User Formants -> F1: {user_formants['F1']} Hz, F2: {user_formants['F2']} Hz")

        return jsonify({
            "class_id":     class_id,
            "confidence":   confidence,
            "user_formants": user_formants,
        })

    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/predict2', methods=['POST', 'OPTIONS'])
def predict2():
    if request.method == 'OPTIONS':
        return jsonify({}), 200

    if 'file' not in request.files:
        return jsonify({"error": "No file uploaded"}), 400
    if 'index' not in request.form:
        return jsonify({"error": "No index provided"}), 400

    audio_file = request.files['file']
    index      = int(request.form['index'])
    temp_path  = os.path.join(TEMP_DIR, "temp_incoming.wav")
    audio_file.save(temp_path)

    try:
        processed_wav = prepare_audio(temp_path)

        feature    = wav2mfcc(processed_wav, max_len=14, n_mfcc=20)
        feature    = feature[np.newaxis, ..., np.newaxis]
        prediction = model.predict(feature)
        confidence = float(prediction[0][index])
        print(f"Index: {index}, Confidence: {confidence:.4f}")

        user_formants = get_formants(processed_wav)
        print(f"User Formants -> F1: {user_formants['F1']} Hz, F2: {user_formants['F2']} Hz")

        return jsonify({
            "class_id":      index,
            "confidence":    confidence,
            "user_formants": user_formants,
        })

    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/predict3', methods=['POST', 'OPTIONS'])
def predict3():
    """CNN+LSTM + Mel pipeline (see ref/realworld_test.ipynb):
    smart_crop (peak-energy 500 ms window) -> log-Mel (128x18) -> CNN+LSTM."""
    if request.method == 'OPTIONS':
        return jsonify({}), 200

    if 'file' not in request.files:
        return jsonify({"error": "No file uploaded"}), 400
    if 'index' not in request.form:
        return jsonify({"error": "No index provided"}), 400

    audio_file = request.files['file']
    index      = int(request.form['index'])
    temp_path  = os.path.join(TEMP_DIR, "temp_incoming.wav")
    audio_file.save(temp_path)

    try:
        cropped_wav = smart_crop(temp_path, TEMP_DIR)
        mel        = extract_mel(cropped_wav)          # (128, 18)
        feature    = mel[np.newaxis, ..., np.newaxis]  # (1, 128, 18, 1)
        prediction = mel_model.predict(feature)
        confidence = float(prediction[0][index])
        print(f"Index: {index}, Confidence: {confidence:.4f}")

        user_formants = get_formants(cropped_wav)
        print(f"User Formants -> F1: {user_formants['F1']} Hz, F2: {user_formants['F2']} Hz")

        # --- Waveform arrays: 200-pt amplitude envelopes, DTW-aligned ---
        N_WAVE  = 200
        curve   = np.load(_dba_path(index)).flatten().astype(np.float64)
        ref_env = np.abs(scipy_resample(curve, N_WAVE))
        if ref_env.max() > 0:
            ref_env /= ref_env.max()

        y_user, _ = librosa.load(cropped_wav, sr=16000, mono=True)
        chunk     = max(1, len(y_user) // N_WAVE)
        user_env  = np.array([
            np.max(np.abs(y_user[i * chunk:(i + 1) * chunk]))
            for i in range(N_WAVE)
        ], dtype=np.float64)
        if user_env.max() > 0:
            user_env /= user_env.max()

        _, path  = fastdtw(user_env.tolist(), ref_env.tolist(),
                           dist=lambda a, b: abs(a - b))
        aligned  = np.zeros(N_WAVE)
        count    = np.zeros(N_WAVE)
        for ui, ri in path:
            aligned[ri] += user_env[ui]
            count[ri]   += 1
        count[count == 0] = 1
        user_wave = aligned / count
        if user_wave.max() > 0:
            user_wave /= user_wave.max()

        return jsonify({
            "class_id":      index,
            "confidence":    confidence,
            "user_formants": user_formants,
            "ref_wave":      ref_env.tolist(),
            "user_wave":     user_wave.tolist(),
        })

    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"error": str(e)}), 500


def _dba_path(class_id: int) -> str:
    """Map model class_id (0–17) to DBA .npy filename.
    0–8  → long vowels  01_dba.npy … 09_dba.npy
    9–17 → short vowels s1_dba.npy … s9_dba.npy
    """
    if class_id < 9:
        name = f"{class_id + 1:02d}_dba.npy"
    else:
        name = f"s{class_id - 8}_dba.npy"
    return os.path.join(BASE_DIR, "references_dba", name)


@app.route('/waveform', methods=['POST', 'OPTIONS'])
def waveform():
    """Return 80 amplitude bars for the DBA reference and user audio.

    Form fields:
      file  – WAV audio
      index – vowel class_id (0–17)
      n_bars – optional, default 80
    Response:
      { ref_bars: [...], user_bars: [...], score: float }
    """
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    if 'file' not in request.files:
        return jsonify({"error": "No file uploaded"}), 400
    if 'index' not in request.form:
        return jsonify({"error": "No index provided"}), 400

    audio_file = request.files['file']
    index      = int(request.form['index'])
    n_bars     = int(request.form.get('n_bars', 80))
    temp_path  = os.path.join(TEMP_DIR, "temp_incoming.wav")
    audio_file.save(temp_path)

    try:
        # Reference bars: load DBA .npy → resample → normalize
        curve    = np.load(_dba_path(index)).flatten().astype(np.float64)
        ref_bars = scipy_resample(curve, n_bars)
        ref_bars = np.abs(ref_bars)
        if ref_bars.max() > 0:
            ref_bars /= ref_bars.max()

        # User bars: smart-crop → chunk max amplitude → normalize
        cropped  = smart_crop(temp_path, TEMP_DIR)
        y, _     = librosa.load(cropped, sr=16000, mono=True)
        chunk    = max(1, len(y) // n_bars)
        user_raw = np.array([
            np.max(np.abs(y[i * chunk:(i + 1) * chunk])) for i in range(n_bars)
        ], dtype=np.float64)
        if user_raw.max() > 0:
            user_raw /= user_raw.max()

        # DTW align user bars onto reference
        distance, path = fastdtw(user_raw.tolist(), ref_bars.tolist(),
                                  dist=lambda a, b: abs(a - b))
        aligned = np.zeros(n_bars)
        count   = np.zeros(n_bars)
        for ui, ri in path:
            aligned[ri] += user_raw[ui]
            count[ri]   += 1
        count[count == 0] = 1
        user_bars = aligned / count
        if user_bars.max() > 0:
            user_bars /= user_bars.max()

        score = round(max(0.0, 1.0 - distance / (n_bars * 2.0)) * 100, 1)
        print(f"[waveform] index={index}  score={score}  dtw_dist={distance:.4f}")

        return jsonify({
            "ref_bars":  ref_bars.tolist(),
            "user_bars": user_bars.tolist(),
            "score":     score,
        })

    except Exception as e:
        print(f"[waveform] Error: {e}")
        return jsonify({"error": str(e)}), 500


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', debug=False, port=port)