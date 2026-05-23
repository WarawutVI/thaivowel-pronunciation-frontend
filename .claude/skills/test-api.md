# test-api

Test the Thai vowel pronunciation app backend API endpoints.

## What this skill does

1. Checks if the backend server is reachable at `http://127.0.0.1:4000`
2. Tests `POST /users` with sample registration data matching the payload sent by `lib/auth/age.dart`
3. Reports status codes, response bodies, and any errors

## Steps

Run the following tests using PowerShell `Invoke-WebRequest` or `curl`. Report pass/fail for each.

### 1. Health check (GET /)

```powershell
try {
  $r = Invoke-WebRequest -Uri "http://127.0.0.1:4000" -Method GET -TimeoutSec 5
  "OK: $($r.StatusCode)"
} catch { "FAIL: $_" }
```

### 2. POST /users — happy path

Use a test firebase_uid that is clearly fake (prefix `test_`) so it won't pollute production data.

```powershell
$body = @{
  firebase_uid   = "test_uid_skill_check"
  username       = "SkillTestUser"
  email          = "skill_test@example.com"
  gender         = "male"
  age            = 21
  login_provider = "email"
} | ConvertTo-Json

try {
  $r = Invoke-WebRequest -Uri "http://127.0.0.1:4000/users" `
       -Method POST `
       -ContentType "application/json" `
       -Body $body `
       -TimeoutSec 10
  "OK ($($r.StatusCode)): $($r.Content)"
} catch { "FAIL: $_" }
```

### 3. POST /users — duplicate uid (expect 4xx or handled error)

Re-send the same `firebase_uid` and confirm the server handles duplicates gracefully.

```powershell
# Same body as step 2 — reuse $body
try {
  $r = Invoke-WebRequest -Uri "http://127.0.0.1:4000/users" `
       -Method POST `
       -ContentType "application/json" `
       -Body $body `
       -TimeoutSec 10
  "RESPONSE ($($r.StatusCode)): $($r.Content)"
} catch [System.Net.WebException] {
  "Expected error: $($_.Exception.Response.StatusCode) - $($_.Exception.Message)"
}
```

### 4. POST /users — missing required field (expect 4xx)

```powershell
$badBody = @{ username = "NoUid" } | ConvertTo-Json
try {
  $r = Invoke-WebRequest -Uri "http://127.0.0.1:4000/users" `
       -Method POST `
       -ContentType "application/json" `
       -Body $badBody `
       -TimeoutSec 10
  "RESPONSE ($($r.StatusCode)): $($r.Content)"
} catch { "Expected error: $_" }
```

## After running

Summarise results in a table:

| Test | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| GET / | 200 | … | … |
| POST /users happy path | 200/201 | … | … |
| POST /users duplicate | 4xx or handled | … | … |
| POST /users missing field | 4xx | … | … |

If the server is not running, instruct the user to start it with:
```
cd <backend-directory> && node index.js
# or: npm start / npm run dev
```

Note: `10.0.2.2:3000` is the Android emulator alias for localhost. When testing from a desktop shell, use `127.0.0.1:4000` (the URL in `lib/auth/age.dart`).
