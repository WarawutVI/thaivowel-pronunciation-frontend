from flask import Flask, jsonify, request
from flask_mysqldb import MySQL
import MySQLdb
from datetime import date, timedelta

app = Flask(__name__)

# Database Configuration (matching your Node.js code)
app.config['MYSQL_HOST'] = 'localhost'
app.config['MYSQL_USER'] = 'root'
app.config['MYSQL_PASSWORD'] = 'root'
app.config['MYSQL_DB'] = 'database'

db = MySQL(app)
with app.app_context():
    try:
        cursor = db.connection.cursor()
        cursor.close()
        print("Connected to MySQL successfully!")
    except MySQLdb.OperationalError as err:
        print(f"Database connection failed: {err}")
    except Exception as err:
        print(f"An unexpected error occurred: {err}")



@app.route('/users/<firebase_uid>', methods=['GET'])
def get_user(firebase_uid):
    cursor = db.connection.cursor()
    cursor.execute(
        "SELECT firebase_uid, username, email, gender, age, login_provider, created_at "
        "FROM users WHERE firebase_uid = %s",
        (firebase_uid,)
    )
    row = cursor.fetchone()
    cursor.close()

    if row is None:
        return jsonify({"error": "User not found"}), 404

    keys = ["firebase_uid", "username", "email", "gender", "age", "login_provider", "created_at"]
    user = dict(zip(keys, row))
    user["created_at"] = str(user["created_at"])
    return jsonify(user), 200


@app.route('/users', methods=['POST'])
def create_user():
    data = request.get_json()
    required = ["firebase_uid", "username", "email", "gender", "age", "login_provider"]
    missing = [f for f in required if not data or f not in data]
    if missing:
        return jsonify({"error": f"Missing fields: {', '.join(missing)}"}), 400

    if data["gender"] not in ("male", "female", "other"):
        return jsonify({"error": "gender must be 'male', 'female', or 'other'"}), 400
    if data["login_provider"] not in ("email", "google"):
        return jsonify({"error": "login_provider must be 'email' or 'google'"}), 400

    cursor = db.connection.cursor()
    try:
        cursor.execute(
            "INSERT INTO users (firebase_uid, username, email, gender, age, login_provider) "
            "VALUES (%s, %s, %s, %s, %s, %s)",
            (data["firebase_uid"], data["username"], data["email"],
             data["gender"], data["age"], data["login_provider"])
        )
        cursor.execute(
            "INSERT INTO user_streaks (firebase_uid) VALUES (%s)",
            (data["firebase_uid"],)
        )
        db.connection.commit()
    except MySQLdb.IntegrityError:
        db.connection.rollback()
        return jsonify({"error": "User already exists"}), 409
    finally:
        cursor.close()

    return jsonify({"message": "User created", "firebase_uid": data["firebase_uid"]}), 201


@app.route('/vowels', methods=['GET'])
def get_vowels():
    vowel_type = request.args.get('type')
    firebase_uid = request.args.get('firebase_uid')
    if not vowel_type or not firebase_uid:
        return jsonify({"error": "Missing 'type' or 'firebase_uid'"}), 400

    cursor = db.connection.cursor()
    cursor.execute("""
        SELECT
          v.id        AS vowel_id,
          v.symbol,
          v.vowel_type,
          COUNT(CASE WHEN ulp.is_completed = TRUE THEN 1 END) AS completed,
          COUNT(vl.id) AS total
        FROM vowels v
        LEFT JOIN vowel_lessons vl ON vl.vowel_id = v.id
        LEFT JOIN user_lesson_progress ulp
          ON ulp.lesson_id = vl.id AND ulp.firebase_uid = %s
        WHERE v.vowel_type = %s
        GROUP BY v.id
        ORDER BY v.id
    """, (firebase_uid, vowel_type))
    rows = cursor.fetchall()
    cursor.close()

    result = [
        {"vowel_id": r[0], "symbol": r[1], "vowel_type": r[2],
         "completed": int(r[3]), "total": int(r[4])}
        for r in rows
    ]
    return jsonify(result), 200


@app.route('/lessons', methods=['GET'])
def get_lessons():
    vowel_id = request.args.get('vowel_id')
    firebase_uid = request.args.get('firebase_uid')
    if not vowel_id or not firebase_uid:
        return jsonify({"error": "Missing 'vowel_id' or 'firebase_uid'"}), 400

    cursor = db.connection.cursor()
    cursor.execute("""
        SELECT
          vl.id           AS lesson_id,
          vl.lesson_order,
          vl.lesson_name,
          ulp.is_completed,
          COALESCE(ulp.best_accuracy, 0.0) AS best_accuracy,
          COALESCE(ulp.attempts, 0)        AS attempts
        FROM vowel_lessons vl
        LEFT JOIN user_lesson_progress ulp
          ON vl.id = ulp.lesson_id AND ulp.firebase_uid = %s
        WHERE vl.vowel_id = %s
        ORDER BY vl.lesson_order
    """, (firebase_uid, vowel_id))
    rows = cursor.fetchall()
    cursor.close()

    result = [
        {
            "lesson_id": r[0],
            "lesson_order": r[1],
            "lesson_name": r[2],
            "is_completed": r[3],
            "best_accuracy": float(r[4]),
            "attempts": int(r[5]),
        }
        for r in rows
    ]
    return jsonify(result), 200


@app.route('/practice_sessions', methods=['POST'])
def create_practice_session():
    data = request.get_json()
    required = ["firebase_uid", "lesson_id", "confidence", "is_passed", "duration_seconds"]
    missing = [f for f in required if data is None or f not in data]
    if missing:
        return jsonify({"error": f"Missing fields: {', '.join(missing)}"}), 400

    cursor = db.connection.cursor()
    cursor.execute(
        "INSERT INTO practice_sessions "
        "(firebase_uid, lesson_id, confidence, is_passed, duration_seconds) "
        "VALUES (%s, %s, %s, %s, %s)",
        (data["firebase_uid"], data["lesson_id"], data["confidence"],
         data["is_passed"], data["duration_seconds"])
    )
    db.connection.commit()
    cursor.close()
    return jsonify({"message": "ok"}), 200


@app.route('/user_lesson_progress', methods=['POST'])
def upsert_lesson_progress():
    data = request.get_json()
    required = ["firebase_uid", "lesson_id", "is_completed", "best_accuracy"]
    missing = [f for f in required if data is None or f not in data]
    if missing:
        return jsonify({"error": f"Missing fields: {', '.join(missing)}"}), 400

    cursor = db.connection.cursor()
    cursor.execute("""
        INSERT INTO user_lesson_progress
          (firebase_uid, lesson_id, is_completed, best_accuracy, attempts, last_practiced_at)
        VALUES (%s, %s, %s, %s, 1, NOW())
        ON DUPLICATE KEY UPDATE
          is_completed      = GREATEST(is_completed, VALUES(is_completed)),
          best_accuracy     = GREATEST(best_accuracy, VALUES(best_accuracy)),
          attempts          = attempts + 1,
          last_practiced_at = NOW()
    """, (data["firebase_uid"], data["lesson_id"],
          data["is_completed"], data["best_accuracy"]))
    db.connection.commit()
    cursor.close()
    return jsonify({"message": "ok"}), 200


@app.route('/user_streaks', methods=['PUT'])
def update_streak():
    data = request.get_json()
    if not data or "firebase_uid" not in data:
        return jsonify({"error": "Missing 'firebase_uid'"}), 400

    cursor = db.connection.cursor()
    cursor.execute("""
        UPDATE user_streaks
        SET
          current_streak = CASE
            WHEN last_practice_date = CURDATE() - INTERVAL 1 DAY THEN current_streak + 1
            WHEN last_practice_date < CURDATE() - INTERVAL 1 DAY THEN 1
            ELSE current_streak
          END,
          longest_streak = GREATEST(longest_streak,
            CASE
              WHEN last_practice_date = CURDATE() - INTERVAL 1 DAY THEN current_streak + 1
              WHEN last_practice_date < CURDATE() - INTERVAL 1 DAY THEN 1
              ELSE current_streak
            END
          ),
          last_practice_date = CURDATE()
        WHERE firebase_uid = %s
    """, (data["firebase_uid"],))
    db.connection.commit()
    cursor.close()
    return jsonify({"message": "ok"}), 200


@app.route('/user_streaks', methods=['GET'])
def get_user_streaks():
    firebase_uid = request.args.get('firebase_uid')
    if not firebase_uid:
        return jsonify({"error": "Missing 'firebase_uid'"}), 400

    cursor = db.connection.cursor()
    cursor.execute(
        "SELECT current_streak, longest_streak, last_practice_date "
        "FROM user_streaks WHERE firebase_uid = %s",
        (firebase_uid,)
    )
    row = cursor.fetchone()
    cursor.close()

    if row is None:
        return jsonify({"current_streak": 0, "longest_streak": 0, "last_practice_date": None}), 200

    return jsonify({
        "current_streak": row[0],
        "longest_streak": row[1],
        "last_practice_date": str(row[2]) if row[2] else None,
    }), 200


@app.route('/progress/summary', methods=['GET'])
def get_progress_summary():
    firebase_uid = request.args.get('firebase_uid')
    if not firebase_uid:
        return jsonify({"error": "Missing 'firebase_uid'"}), 400

    cursor = db.connection.cursor()
    cursor.execute("""
        SELECT
          COALESCE(AVG(ps.confidence), 0.0)                                           AS overall_accuracy,
          COUNT(ps.id)                                                                 AS total_sessions,
          COALESCE(MAX(ps.confidence), 0.0)                                           AS best_accuracy,
          COALESCE(AVG(CASE WHEN v.vowel_type = 'long'  THEN ps.confidence END), 0.0) AS long_avg_accuracy,
          COALESCE(AVG(CASE WHEN v.vowel_type = 'short' THEN ps.confidence END), 0.0) AS short_avg_accuracy
        FROM practice_sessions ps
        JOIN vowel_lessons vl ON vl.id = ps.lesson_id
        JOIN vowels v          ON v.id  = vl.vowel_id
        WHERE ps.firebase_uid = %s
    """, (firebase_uid,))
    row = cursor.fetchone()
    cursor.close()

    return jsonify({
        "overall_accuracy":   float(row[0]),
        "total_sessions":     int(row[1]),
        "best_accuracy":      float(row[2]),
        "long_avg_accuracy":  float(row[3]),
        "short_avg_accuracy": float(row[4]),
    }), 200


@app.route('/progress/vowel_stats', methods=['GET'])
def get_vowel_stats():
    firebase_uid = request.args.get('firebase_uid')
    vowel_type = request.args.get('type')
    if not firebase_uid or not vowel_type:
        return jsonify({"error": "Missing 'firebase_uid' or 'type'"}), 400

    cursor = db.connection.cursor()
    cursor.execute("""
        SELECT
          v.id                              AS vowel_id,
          v.symbol,
          v.vowel_type,
          COUNT(ps.id)                      AS practice_count,
          COALESCE(AVG(ps.confidence), 0.0) AS avg_accuracy
        FROM vowels v
        LEFT JOIN vowel_lessons vl ON vl.vowel_id = v.id
        LEFT JOIN practice_sessions ps
          ON ps.lesson_id = vl.id AND ps.firebase_uid = %s
        WHERE v.vowel_type = %s
        GROUP BY v.id
        ORDER BY v.id
    """, (firebase_uid, vowel_type))
    rows = cursor.fetchall()
    cursor.close()

    result = [
        {
            "vowel_id":       r[0],
            "symbol":         r[1],
            "vowel_type":     r[2],
            "practice_count": int(r[3]),
            "avg_accuracy":   float(r[4]),
        }
        for r in rows
    ]
    return jsonify(result), 200


@app.route('/practice_sessions/recent', methods=['GET'])
def get_recent_sessions():
    firebase_uid = request.args.get('firebase_uid')
    limit = request.args.get('limit', 5)
    if not firebase_uid:
        return jsonify({"error": "Missing 'firebase_uid'"}), 400

    cursor = db.connection.cursor()
    cursor.execute("""
        SELECT
          v.symbol,
          v.vowel_type,
          vl.lesson_name,
          ps.confidence,
          ps.practiced_at
        FROM practice_sessions ps
        JOIN vowel_lessons vl ON vl.id = ps.lesson_id
        JOIN vowels v          ON v.id  = vl.vowel_id
        WHERE ps.firebase_uid = %s
        ORDER BY ps.practiced_at DESC
        LIMIT %s
    """, (firebase_uid, int(limit)))
    rows = cursor.fetchall()
    cursor.close()

    result = [
        {
            "symbol":       r[0],
            "vowel_type":   r[1],
            "lesson_name":  r[2],
            "confidence":   float(r[3]),
            "practiced_at": r[4].isoformat() if r[4] else None,
        }
        for r in rows
    ]
    return jsonify(result), 200


@app.route('/progress/trend', methods=['GET'])
def get_progress_trend():
    firebase_uid = request.args.get('firebase_uid')
    vowel_type   = request.args.get('type')
    period       = request.args.get('period', 'week')  # 'week' | 'month' | 'year'

    if not firebase_uid or not vowel_type:
        return jsonify({"error": "Missing 'firebase_uid' or 'type'"}), 400

    today  = date.today()
    cursor = db.connection.cursor()

    if period == 'week':
        # One point per day for the last 7 days; fill 0.0 for days with no practice.
        start = today - timedelta(days=6)
        cursor.execute("""
            SELECT
              DATE(ps.practiced_at) AS day,
              AVG(ps.confidence)    AS avg_accuracy
            FROM practice_sessions ps
            JOIN vowel_lessons vl ON vl.id = ps.lesson_id
            JOIN vowels v          ON v.id  = vl.vowel_id
            WHERE ps.firebase_uid = %s
              AND v.vowel_type    = %s
              AND DATE(ps.practiced_at) BETWEEN %s AND %s
            GROUP BY DATE(ps.practiced_at)
            ORDER BY day ASC
        """, (firebase_uid, vowel_type, start, today))
        rows   = cursor.fetchall()
        db_map = {r[0]: float(r[1]) for r in rows}
        result = [
            {"date": str(start + timedelta(days=i)),
             "avg_accuracy": db_map.get(start + timedelta(days=i), 0.0)}
            for i in range(7)
        ]

    elif period == 'month':
        # One point per week for the last 30 days; date = first practice day of that week.
        start = today - timedelta(days=29)
        cursor.execute("""
            SELECT
              DATE(MIN(ps.practiced_at)) AS week_start,
              AVG(ps.confidence)          AS avg_accuracy
            FROM practice_sessions ps
            JOIN vowel_lessons vl ON vl.id = ps.lesson_id
            JOIN vowels v          ON v.id  = vl.vowel_id
            WHERE ps.firebase_uid = %s
              AND v.vowel_type    = %s
              AND DATE(ps.practiced_at) BETWEEN %s AND %s
            GROUP BY YEARWEEK(ps.practiced_at, 1)
            ORDER BY week_start ASC
        """, (firebase_uid, vowel_type, start, today))
        rows   = cursor.fetchall()
        result = [
            {"date": str(r[0]), "avg_accuracy": float(r[1])}
            for r in rows
        ]

    elif period == 'year':
        # One point per month for the last 12 months; date = first day of that month.
        start = (today.replace(day=1) - timedelta(days=365)).replace(day=1)
        cursor.execute("""
            SELECT
              DATE(DATE_FORMAT(ps.practiced_at, '%%Y-%%m-01')) AS month_start,
              AVG(ps.confidence)                                AS avg_accuracy
            FROM practice_sessions ps
            JOIN vowel_lessons vl ON vl.id = ps.lesson_id
            JOIN vowels v          ON v.id  = vl.vowel_id
            WHERE ps.firebase_uid = %s
              AND v.vowel_type    = %s
              AND DATE(ps.practiced_at) >= %s
            GROUP BY DATE_FORMAT(ps.practiced_at, '%%Y-%%m')
            ORDER BY month_start ASC
        """, (firebase_uid, vowel_type, start))
        rows   = cursor.fetchall()
        result = [
            {"date": str(r[0]), "avg_accuracy": float(r[1])}
            for r in rows
        ]

    else:
        result = []

    cursor.close()
    return jsonify(result), 200


if __name__ == '__main__':
    app.run(debug=True, port=4000)