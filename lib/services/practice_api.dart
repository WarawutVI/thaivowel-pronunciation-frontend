import 'dart:convert';
import 'dart:typed_data';
import 'package:frontend/services/class/daily_trend.dart';
import 'package:frontend/services/class/lesson_progress.dart';
import 'package:frontend/services/class/predict_result.dart';
import 'package:frontend/services/class/progress_summary.dart';
import 'package:frontend/services/class/session_record.dart';
import 'package:frontend/services/class/user_streak.dart';
import 'package:frontend/services/class/vowel_detail.dart';
import 'package:frontend/services/class/vowel_formant.dart';
import 'package:frontend/services/class/vowel_progress.dart';
import 'package:frontend/services/class/vowel_stats.dart';
import 'package:http/http.dart' as http;

export 'package:frontend/services/class/daily_trend.dart';
export 'package:frontend/services/class/lesson_progress.dart';
export 'package:frontend/services/class/predict_result.dart';
export 'package:frontend/services/class/progress_summary.dart';
export 'package:frontend/services/class/session_record.dart';
export 'package:frontend/services/class/user_streak.dart';
export 'package:frontend/services/class/vowel_detail.dart';
export 'package:frontend/services/class/vowel_formant.dart';
export 'package:frontend/services/class/vowel_progress.dart';
export 'package:frontend/services/class/vowel_stats.dart';

const String _base = 'https://perkiness-shadiness-extras.ngrok-free.dev';
const String _flaskBase = 'https://perkiness-shadiness-extras.ngrok-free.dev/model';

const Map<String, String> _headers = {
  'ngrok-skip-browser-warning': 'true',
};

const Map<String, String> _jsonHeaders = {
  'Content-Type': 'application/json',
  'ngrok-skip-browser-warning': 'true',
};

class PracticeApi {
  // POST /users
  static Future<void> createUser({
    required String firebaseUid,
    required String username,
    required String email,
    required String gender,
    required int age,
    required String nationality,
    required String loginProvider,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/users'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'firebase_uid': firebaseUid,
        'username': username,
        'email': email,
        'gender': gender,
        'age': age,
        'nationality': nationality,
        'login_provider': loginProvider,
      }),
    );
    // 201 = created, 409 = already exists (both OK)
    if (res.statusCode != 201 && res.statusCode != 409) {
      throw Exception('Failed to create user: ${res.statusCode}');
    }
  }

  // GET /vowels?type=short|long&firebase_uid=X
  static Future<List<VowelProgress>> fetchVowels(
      String firebaseUid, String type) async {
    final uri = Uri.parse('$_base/vowels')
        .replace(queryParameters: {'type': type, 'firebase_uid': firebaseUid});
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) throw Exception('Failed to load vowels');
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => VowelProgress.fromJson(e as Map<String, dynamic>)).toList();
  }

  // GET /lessons?vowel_id=X&firebase_uid=Y
  static Future<List<LessonProgress>> fetchLessons(
      String firebaseUid, int vowelId) async {
    final uri = Uri.parse('$_base/lessons').replace(queryParameters: {
      'vowel_id': vowelId.toString(),
      'firebase_uid': firebaseUid,
    });
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) throw Exception('Failed to load lessons');
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => LessonProgress.fromJson(e as Map<String, dynamic>)).toList();
  }

  // POST Flask /predict3
  static Future<PredictResult> predict(Uint8List audioBytes, int vowelIndex) async {
    final req = http.MultipartRequest('POST', Uri.parse('$_flaskBase/predict3'));
    req.headers.addAll(_headers);
    req.fields['index'] = vowelIndex.toString();
    req.files.add(http.MultipartFile.fromBytes(
      'file',
      audioBytes,
      filename: 'recording.wav',
    ));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200) throw Exception('Prediction failed: ${res.statusCode}');
    return PredictResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // POST /practice_sessions
  static Future<void> saveSession({
    required String firebaseUid,
    required int lessonId,
    required double confidence,
    required String assessmentLevel,
    required bool isPassed,
    required int durationSeconds,
  }) async {
    await http.post(
      Uri.parse('$_base/practice_sessions'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'firebase_uid': firebaseUid,
        'lesson_id': lessonId,
        'confidence': confidence,
        'assessment_level': assessmentLevel,
        'is_passed': isPassed,
        'duration_seconds': durationSeconds,
      }),
    );
  }

  // POST /user_lesson_progress (UPSERT)
  static Future<void> saveProgress({
    required String firebaseUid,
    required int lessonId,
    required bool isCompleted,
    required double bestAccuracy,
    required String assessmentLevel,
  }) async {
    await http.post(
      Uri.parse('$_base/user_lesson_progress'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'firebase_uid': firebaseUid,
        'lesson_id': lessonId,
        'is_completed': isCompleted,
        'best_accuracy': bestAccuracy,
        'assessment_level': assessmentLevel,
      }),
    );
  }

  // PUT /user_streaks
  static Future<void> updateStreak(String firebaseUid) async {
    await http.put(
      Uri.parse('$_base/user_streaks'),
      headers: _jsonHeaders,
      body: jsonEncode({'firebase_uid': firebaseUid}),
    );
  }

  // GET /user_streaks?firebase_uid=X
  static Future<UserStreak> fetchStreak(String firebaseUid) async {
    final uri = Uri.parse('$_base/user_streaks')
        .replace(queryParameters: {'firebase_uid': firebaseUid});
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) throw Exception('Failed to load streak');
    return UserStreak.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // GET /progress/summary?firebase_uid=X
  static Future<ProgressSummary> fetchSummary(String firebaseUid) async {
    final uri = Uri.parse('$_base/progress/summary')
        .replace(queryParameters: {'firebase_uid': firebaseUid});
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) throw Exception('Failed to load progress summary');
    return ProgressSummary.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // GET /progress/vowel_stats?firebase_uid=X&type=short|long
  static Future<List<VowelStats>> fetchVowelStats(
      String firebaseUid, String type) async {
    final uri = Uri.parse('$_base/progress/vowel_stats')
        .replace(queryParameters: {'firebase_uid': firebaseUid, 'type': type});
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) throw Exception('Failed to load vowel stats');
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => VowelStats.fromJson(e as Map<String, dynamic>)).toList();
  }

  // GET /practice_sessions/recent?firebase_uid=X&limit=N
  static Future<List<SessionRecord>> fetchRecentSessions(
      String firebaseUid, {int limit = 5}) async {
    final uri = Uri.parse('$_base/practice_sessions/recent').replace(
        queryParameters: {
          'firebase_uid': firebaseUid,
          'limit': limit.toString()
        });
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) throw Exception('Failed to load sessions');
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => SessionRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  // GET /vowels/:vowelId/formants
  static Future<VowelFormant> fetchVowelFormant(int vowelId) async {
    final res = await http.get(
      Uri.parse('$_base/vowels/$vowelId/formants'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception('Failed to load vowel formant');
    return VowelFormant.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // GET /vowels/details
  static Future<List<VowelDetail>> fetchVowelDetails() async {
    final res = await http.get(
      Uri.parse('$_base/vowels/details'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception('Failed to load vowel details');
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => VowelDetail.fromJson(e as Map<String, dynamic>)).toList();
  }

  // GET /progress/trend
  static Future<List<DailyTrend>> fetchTrend(
    String firebaseUid,
    String type, {
    String period = 'week',
    String? start,
    String? end,
  }) async {
    final params = <String, String>{
      'firebase_uid': firebaseUid,
      'type': type,
      'period': period,
    };
    if (start != null) params['start'] = start;
    if (end != null) params['end'] = end;
    final uri = Uri.parse('$_base/progress/trend').replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) throw Exception('Failed to load trend');
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => DailyTrend.fromJson(e as Map<String, dynamic>)).toList();
  }
}