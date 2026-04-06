# Nakhlah Backend — Setup Guide

## Architecture

```
Flutter App
    │  HTTPS + Firebase ID Token
    ▼
FastAPI Backend  (:8000)          ← Layer 2
    │  HTTP (Docker internal)
    ▼
AI Microservice  (:8001)          ← Layer 3
    │  loads
nakhlah_model_v1.pth (EfficientNet-B0, 9 classes)
    │
Firestore + Firebase Storage      ← Layer 4
```

---

## 1. Prerequisites

- Docker + Docker Compose installed
- Your trained model file: `nakhlah_model_v1.pth`
- Firebase project with:
  - Authentication enabled
  - Firestore database created
  - Storage bucket created
  - Service account JSON downloaded

---

## 2. Project layout

```
nakhlah-backend/
├── app/                    ← FastAPI application
│   ├── main.py
│   ├── dependencies.py
│   ├── routers/
│   │   ├── scan.py         POST /scan, GET /scan/history
│   │   ├── dates.py        GET /dates, GET /dates/{name}
│   │   └── users.py        GET/PUT /users/me
│   ├── services/
│   │   ├── inference_service.py
│   │   └── firebase_service.py
│   └── schemas/models.py
├── ai_service/
│   ├── main.py             ← Model loader + POST /predict
│   ├── requirements.txt
│   └── Dockerfile
├── flutter/
│   ├── scan_service.dart        ← Drop into lib/services/
│   ├── scan_result_screen.dart  ← Drop into lib/screens/
│   └── scan_screen_patch.dart   ← Replace _analyzeImage in scan_screen.dart
├── models/                 ← PUT YOUR .pth FILE HERE
├── docker-compose.yml
├── Dockerfile
└── requirements.txt
```

---

## 3. First-time setup

### Step 1 — Place your model
```bash
mkdir -p models
cp /path/to/nakhlah_model_v1.pth models/
```

### Step 2 — Place Firebase credentials
```bash
cp /path/to/your-service-account.json firebase-credentials.json
```

### Step 3 — Set your Storage bucket
Edit `docker-compose.yml`, find this line and update it:
```yaml
FIREBASE_STORAGE_BUCKET: your-project-id.appspot.com
```

### Step 4 — Build and run
```bash
docker compose up --build
```

Backend will be at `http://localhost:8000`
AI service will be at `http://localhost:8001`

---

## 4. API Reference

### POST /scan
Upload an image and get a classification result.

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Body:** `multipart/form-data` with field `file` (JPEG/PNG/WEBP, max 10 MB)

**Response:**
```json
{
  "scan_id": "uuid",
  "user_id": "firebase_uid",
  "label": "Ajwa",
  "confidence": 0.9821,
  "all_predictions": [
    {"label": "Ajwa",    "confidence": 0.9821, "class_index": 0},
    {"label": "Medjool", "confidence": 0.0102, "class_index": 2},
    ...
  ],
  "image_url": "https://storage.googleapis.com/...",
  "scanned_at": "2024-01-01T12:00:00Z"
}
```

### GET /scan/history
Returns the authenticated user's last 20 scans.

### GET /users/me
Returns the authenticated user's profile.

### PUT /users/me
Updates `display_name`.

### GET /dates
Returns all date variety documents from Firestore.

### GET /dates/{name}
Returns info for a specific date variety (e.g. `/dates/Ajwa`).

---

## 5. Flutter integration

### pubspec.yaml — add these if not present
```yaml
dependencies:
  dio: ^5.4.3
  firebase_auth: ^4.0.0   # already in your project
```

### Copy these files
```
flutter/scan_service.dart        →  lib/services/scan_service.dart
flutter/scan_result_screen.dart  →  lib/screens/scan_result_screen.dart
```

### Patch scan_screen.dart
1. Add import at the top:
```dart
import '../services/scan_service.dart';
import 'scan_result_screen.dart';
```

2. Replace `_analyzeImage()` with the version in `flutter/scan_screen_patch.dart`

### Update the base URL in scan_service.dart
```dart
// Android emulator
static const String _baseUrl = 'http://10.0.2.2:8000';

// iOS simulator
static const String _baseUrl = 'http://127.0.0.1:8000';

// Physical device (use your machine's LAN IP)
static const String _baseUrl = 'http://192.168.1.X:8000';

// Production
static const String _baseUrl = 'https://api.nakhlah.app';
```

---

## 6. Firestore — Seed date info (optional)

Create a `date_database` collection with documents like this:

Document ID: `ajwa`
```json
{
  "name": "Ajwa",
  "arabic_name": "عجوة",
  "origin": "Al-Madinah, Saudi Arabia",
  "description": "Dark, soft date from Madinah, highly prized in Islamic tradition.",
  "season": "August – October",
  "nutritional_info": {
    "calories_per_100g": 277,
    "sugar_g": 63,
    "fiber_g": 7
  }
}
```

Document IDs: `ajwa`, `galaxy`, `medjool`, `meneifi`, `nabtat_ali`,
              `rutab`, `shaishe`, `sokari`, `sugaey`

---

## 7. Production checklist

- [ ] Set `FIREBASE_STORAGE_BUCKET` correctly
- [ ] Restrict CORS in `main.py` to your app's domain
- [ ] Use HTTPS (put Nginx or a reverse proxy in front)
- [ ] Remove exposed ports for `ai_service` in `docker-compose.yml` (keep internal only)
- [ ] Add rate limiting (e.g. `slowapi`)
- [ ] Use GPU Docker image for faster inference if available
