# 🌴 Nakhlah — AI-Powered Date Identification Platform

<p align="center">
  <img src="docs/assets/nakhlah_logo.png" alt="Nakhlah Logo" width="200"/>
</p>

<p align="center">
  <b>Smart Date Intelligence — Identify · Explore · Buy</b><br/>
  Flutter · Firebase · EfficientNet-B0 · FastAPI · Docker
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.41.6-blue?logo=flutter" />
  <img src="https://img.shields.io/badge/Dart-3.4-blue?logo=dart" />
  <img src="https://img.shields.io/badge/Java-17_LTS-orange?logo=openjdk" />
  <img src="https://img.shields.io/badge/Python-3.10-yellow?logo=python" />
  <img src="https://img.shields.io/badge/FastAPI-0.110.0-green?logo=fastapi" />
  <img src="https://img.shields.io/badge/PyTorch-2.2.1-red?logo=pytorch" />
  <img src="https://img.shields.io/badge/Docker-Required-blue?logo=docker" />
</p>

---

## 📖 Table of Contents

- [Project Overview](#project-overview)
- [Team Members](#team-members)
- [System Architecture](#system-architecture)
- [Folder Structure](#folder-structure)
- [Tech Stack and Versions](#tech-stack-and-versions)
- [AI Model Details](#ai-model-details)
- [Model Evaluation](#model-evaluation)
- [Getting Started](#getting-started)
- [Firebase Setup](#firebase-setup)
- [Running the Project](#running-the-project)
- [API Reference](#api-reference)
- [Branch Strategy](#branch-strategy)
- [Sprint Plan](#sprint-plan)
- [Production Considerations](#production-considerations)
- [Risk Management](#risk-management)

---

## 📱 Project Overview

**Nakhlah** is a mobile application that uses AI-powered image recognition to identify date fruit varieties. Users take a photo of any date and instantly receive:

- 🌴 **Date Type** — e.g., Medjool, Ajwa, Sukkari, Deglet Noor
- 🗺️ **Origin Information** — country and cultivation region
- 🥗 **Nutritional Profile** — calories, sugar, fiber, vitamins, minerals
- 📊 **Confidence Score** — color-coded reliability indicator
- 🛒 **Marketplace** — verified trusted date sellers

Supports **English** and **Arabic (RTL layout)** — Android platform.

---

## 👥 Team Members

| Name | Role | Student ID |
|------|------|------------|
| Abderrahmane Benfatah | AI Specialist & Fullstack | 444106928 |
| Mansour Abahussain | AI Lead & Fullstack | 444100453 |
| Omar Ramdhan | Testing, UI/UX & Fullstack | 444106902 |
| Ahmed Albabtain | UI/UX & Fullstack | 444100806 |
| Mohammad Alfarraj | UI/UX & Fullstack | 443102025 |

---

## 🏗️ System Architecture

Nakhlah uses a **4-Layer Multi-Tier Architecture** with fully separated concerns:

```
┌───────────────────────────────────────────────────────┐
│             Layer 1 — Presentation Layer              │
│         Flutter Mobile App (Android, Dart 3.4)        │
│    Firebase Auth ──── Firebase Storage ──── Dio HTTP  │
└─────────────────────────┬─────────────────────────────┘
                          │  HTTPS + Firebase ID Token
                          │  (JWT verified server-side)
┌─────────────────────────▼─────────────────────────────┐
│             Layer 2 — Application Layer               │
│           FastAPI Backend (Python 3.10)               │
│   Auth Middleware ── Router ── Firebase Admin SDK     │
└─────────────────────────┬─────────────────────────────┘
                          │  Internal Docker Network
                          │  HTTP to port 8001
┌─────────────────────────▼─────────────────────────────┐
│             Layer 3 — AI Inference Layer              │
│      ONNX Runtime  (EfficientNet-B0)                  │
│           Standalone Microservice (Docker)            │
│    Preprocess ── Inference ── Postprocess ── JSON     │
└─────────────────────────┬─────────────────────────────┘
                          │  Read / Write
┌─────────────────────────▼─────────────────────────────┐
│               Layer 4 — Data Layer                    │
│        Firestore Database + Firebase Storage          │
│   Users ── ScanHistory ── DateDatabase ── Sellers     │
└───────────────────────────────────────────────────────┘
```

**Key Architecture Decisions:**

- AI Inference is an **independent microservice** in its own Docker container — non-blocking, independently scalable
- FastAPI verifies **Firebase ID Tokens** server-side via `firebase-admin` on every protected request
- Flutter uses **Dio** (not the basic http package) for interceptors, token refresh, and error handling
- Model is exported to **ONNX** for faster CPU inference without the full PyTorch runtime

---

## 📂 Folder Structure

```
nakhlah/
│
├── 📱 app/                              ← Flutter Mobile Application
│   ├── android/
│   │   ├── app/
│   │   │   ├── build.gradle             ← compileSdk 34, minSdk 23
│   │   │   └── google-services.json     ← ⚠️ NEVER COMMIT (gitignored)
│   │   └── build.gradle                 ← AGP 8.2, Gradle 8.4
│   │
│   ├── lib/
│   │   ├── main.dart                    ← App entry point
│   │   ├── firebase_options.dart        ← ⚠️ NEVER COMMIT (auto-generated)
│   │   │
│   │   ├── core/
│   │   │   ├── constants/
│   │   │   │   ├── app_colors.dart
│   │   │   │   ├── app_routes.dart
│   │   │   │   └── api_constants.dart   ← Backend URL config
│   │   │   ├── theme/
│   │   │   │   └── app_theme.dart
│   │   │   └── utils/
│   │   │       ├── validators.dart
│   │   │       └── extensions.dart
│   │   │
│   │   ├── l10n/                        ← Localization files
│   │   │   ├── app_en.arb
│   │   │   └── app_ar.arb
│   │   │
│   │   ├── models/
│   │   │   ├── date_model.dart
│   │   │   ├── user_model.dart
│   │   │   ├── scan_result_model.dart
│   │   │   └── seller_model.dart
│   │   │
│   │   ├── services/
│   │   │   ├── auth_service.dart        ← Firebase Auth wrapper
│   │   │   ├── scan_service.dart        ← Calls FastAPI /scan
│   │   │   ├── firestore_service.dart   ← Firestore CRUD
│   │   │   └── api_service.dart         ← Dio client with interceptors
│   │   │
│   │   ├── providers/                   ← Riverpod state management
│   │   │   ├── auth_provider.dart
│   │   │   ├── scan_provider.dart
│   │   │   └── language_provider.dart
│   │   │
│   │   └── screens/
│   │       ├── auth/
│   │       ├── home/
│   │       ├── scan/
│   │       ├── history/
│   │       ├── explore/
│   │       ├── marketplace/
│   │       └── profile/
│   │
│   ├── assets/
│   │   ├── images/
│   │   └── fonts/
│   │
│   └── pubspec.yaml
│
├── 🤖 ai/                               ← AI Model (PyTorch + ONNX export)
│   ├── dataset/
│   │   ├── raw/                         ← Original downloaded images
│   │   └── processed/                   ← Cleaned and labeled
│   │       ├── train/
│   │       │   ├── ajwa/
│   │       │   ├── medjool/
│   │       │   ├── sukkari/
│   │       │   └── .../                 ← One folder per class
│   │       ├── val/
│   │       └── test/
│   │
│   ├── notebooks/
│   │   ├── 01_data_exploration.ipynb
│   │   ├── 02_model_training.ipynb      ← EfficientNet-B0 fine-tuning
│   │   ├── 03_model_evaluation.ipynb    ← Accuracy, F1, confusion matrix
│   │   └── 04_export_onnx.ipynb         ← Export .pt to .onnx
│   │
│   ├── src/
│   │   ├── train.py                     ← Training pipeline
│   │   ├── evaluate.py                  ← Metrics + confusion matrix
│   │   ├── predict.py                   ← Single image prediction
│   │   ├── model.py                     ← EfficientNet-B0 definition
│   │   ├── dataset.py                   ← Dataset loader + augmentations
│   │   └── inference_api.py             ← FastAPI microservice (port 8001)
│   │
│   ├── models/
│   │   ├── best_model.pt                ← PyTorch weights (use Git LFS)
│   │   └── model.onnx                   ← ONNX export (use Git LFS)
│   │
│   ├── Dockerfile
│   └── requirements.txt
│
├── 🖥️ backend/                          ← FastAPI Application Backend
│   ├── app/
│   │   ├── main.py                      ← FastAPI entry + global middleware
│   │   ├── dependencies.py              ← Firebase ID Token verification
│   │   │
│   │   ├── routers/
│   │   │   ├── scan.py                  ← POST /scan
│   │   │   ├── dates.py                 ← GET /dates
│   │   │   └── users.py                 ← GET PUT /users
│   │   │
│   │   ├── services/
│   │   │   ├── inference_service.py     ← Calls AI microservice at :8001
│   │   │   └── firebase_service.py      ← Firestore read/write
│   │   │
│   │   ├── middleware/
│   │   │   └── auth_middleware.py       ← firebase-admin token verify
│   │   │
│   │   └── schemas/
│   │       └── models.py                ← Pydantic v2 request/response schemas
│   │
│   ├── Dockerfile
│   └── requirements.txt
│
├── 🎨 design/
│   ├── wireframes/
│   ├── mockups/
│   └── style_guide.md
│
├── 📄 docs/
│   ├── assets/
│   ├── architecture.md
│   ├── api_reference.md
│   ├── model_evaluation/               ← Confusion matrix images, metrics CSV
│   └── sprint_notes/
│
├── secrets/                            ← ⚠️ NEVER COMMIT (gitignored)
│   └── firebase_key.json
│
├── .gitignore
├── docker-compose.yml
└── README.md
```

---

## 🛠️ Tech Stack and Versions

### Frontend — Flutter

| Tool | Version | Notes |
|------|---------|-------|
| Flutter | **3.22.x stable** | Latest stable, full Android 14 support |
| Dart | **3.4** (bundled) | Do NOT install separately |
| Java JDK | **17 LTS** | Required by AGP 8.x — do not use 8 or 11 |
| Android Gradle Plugin | **8.2** | Specified in `android/build.gradle` |
| Gradle | **8.4** | Matches AGP 8.2 |
| compileSdk | **34** | Android 14 |
| minSdk | **23** | Android 6.0 — covers ~98% of devices |

**Flutter packages (pubspec.yaml):**
```yaml
dio: ^5.4.3                    # HTTP client — use this, NOT http package
firebase_core: ^2.27.0
firebase_auth: ^4.17.8
cloud_firestore: ^4.15.8
firebase_storage: ^11.6.9
flutter_riverpod: ^2.5.1       # State management
image_picker: ^1.0.7           # Camera and gallery
intl: ^0.19.0                  # Locale and RTL formatting
cached_network_image: ^3.3.1   # Image caching
flutter_localizations:
  sdk: flutter
```

### Backend — Python / FastAPI

| Tool | Version |
|------|---------|
| Python | **3.10** |
| FastAPI | **0.110.0** |
| Pydantic | **2.6.4** |
| firebase-admin | **6.4.0** |
| uvicorn | **0.29.0** |
| httpx | **0.27.0** |

### AI / ML

| Tool | Version |
|------|---------|
| PyTorch | **2.2.1** |
| torchvision | **0.17.1** |
| ONNX Runtime | **1.17.3** |
| NumPy | **1.26.4** |
| Pandas | **2.2.1** |
| scikit-learn | **1.4.2** |

---

## 🤖 AI Model Details

```
Architecture   : EfficientNet-B0
Pretrained On  : ImageNet (transfer learning, fine-tuned)
Task           : Multi-class image classification
Classes        : 8+ date varieties
Optimizer      : AdamW (lr=1e-4, weight_decay=1e-2)
Loss Function  : CrossEntropyLoss
LR Scheduler   : CosineAnnealingLR
Input Size     : 224 x 224 RGB
Augmentations  : RandomRotation(30), ColorJitter, RandomHorizontalFlip,
                 RandomResizedCrop(224), Normalize(ImageNet mean/std)
Export Format  : ONNX (for fast CPU inference without full PyTorch)
```

**Why EfficientNet-B0?**
- Only 5.3M parameters — fast inference on CPU
- State-of-the-art on fine-grained food/plant image classification
- Works excellently with small custom datasets via transfer learning
- Easy ONNX export for production deployment

---

## 📊 Model Evaluation

Results will be recorded here after training is complete.

| Metric | Target | Achieved |
|--------|--------|---------|
| Accuracy | ≥ 85% | TBD |
| Precision | ≥ 84% | TBD |
| Recall | ≥ 83% | TBD |
| F1 Score | ≥ 84% | TBD |
| Inference Latency | ≤ 3s | TBD |

Confusion matrix and per-class breakdown will be saved at `docs/model_evaluation/`.

---

## 🚀 Getting Started

### Step 1 — Install Prerequisites (Everyone)

```bash
# Verify Git
git --version

# Flutter — must be stable channel, 3.22.x
flutter channel stable
flutter upgrade
flutter --version
flutter doctor          # Fix ALL issues shown before continuing

# Java 17 LTS — download from https://www.oracle.com/java/technologies/downloads/#java17
java -version           # Must show 17.x.x

# Docker Desktop — https://www.docker.com/products/docker-desktop/
docker --version
docker compose version

# Python 3.10 — https://www.python.org/downloads/
python --version        # Must show 3.10.x
```

### Step 2 — Clone Repository

```bash
git clone https://github.com/YOUR_ORG/nakhlah.git
cd nakhlah
git checkout develop
```

### Step 3 — Flutter App (Frontend Team)

```bash
cd app
flutter pub get

# Get google-services.json from team lead (Mansour)
# Place it at: app/android/app/google-services.json

# Generate firebase_options.dart
dart pub global activate flutterfire_cli
flutterfire configure

# Run on emulator or device
flutter run
```

### Step 4 — Backend and AI (AI Team — Docker Recommended)

```bash
# From repo root — starts backend + AI microservice
docker compose up --build

# Backend API docs:  http://localhost:8000/docs
# AI service:        http://localhost:8001
```

Manual alternative:
```bash
# Terminal 1 — AI inference microservice
cd ai
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
uvicorn src.inference_api:app --reload --port 8001

# Terminal 2 — FastAPI backend
cd backend
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

---

## 🔥 Firebase Setup

1. Go to https://console.firebase.google.com → Create project: **Nakhlah**
2. Enable: **Authentication** (Email/Password), **Firestore**, **Storage**
3. Android App → Package name: `com.nakhlah.app`
4. Download `google-services.json` → share with team **privately** (Discord DM only — never commit)
5. Download Firebase Admin SDK key → save as `secrets/firebase_key.json` (never commit)
6. Create `.env` file in `backend/`:
```env
FIREBASE_CREDENTIALS=./secrets/firebase_key.json
AI_SERVICE_URL=http://ai:8001
```

---

## ▶️ Running the Project

| Component | Command | URL |
|-----------|---------|-----|
| Flutter App | `flutter run` (inside `app/`) | Android device |
| Full Backend (Docker) | `docker compose up` (root) | localhost:8000 + 8001 |
| API Docs | Auto-generated by FastAPI | http://localhost:8000/docs |
| AI Training | Upload `ai/notebooks/02_model_training.ipynb` to Colab | — |

---

## 📡 API Reference

### `POST /scan`

Upload an image and receive date identification.

**Headers:** `Authorization: Bearer <firebase_id_token>`  
**Body:** `multipart/form-data` with `image` field

**Response:**
```json
{
  "date_type": "Ajwa",
  "confidence": 0.94,
  "confidence_label": "High",
  "origin": {
    "region": "Al-Madinah",
    "country": "Saudi Arabia"
  },
  "nutrition": {
    "calories": 277,
    "sugar_g": 66.5,
    "fiber_g": 6.7,
    "protein_g": 1.8
  }
}
```

### `GET /dates`
Returns all date varieties from the database.

### `GET /dates/{id}`
Returns detailed info for one variety.

Full interactive docs at `http://localhost:8000/docs` when backend is running.

---

## 🛡️ Production Considerations

| Concern | Implementation |
|---------|---------------|
| Auth Security | Firebase ID Token verified server-side via `firebase-admin` on every request |
| HTTPS | Enforced in production; HTTP redirected |
| Rate Limiting | `slowapi` on `/scan` — 10 req/min per user |
| Input Validation | Pydantic v2 schemas on all endpoints |
| Image Validation | File type + max size check before inference |
| Error Handling | Global FastAPI exception handlers with structured JSON |
| Logging | Structured uvicorn logs with request tracing |
| Model Versioning | Model files tagged by version in `ai/models/` |
| Docker Pinning | All images use exact version tags — never `latest` |
| Secrets | Loaded via environment variables — never in source code |

---

## 🌿 Branch Strategy

```
main          ← Production-ready code only (protected)
develop       ← Integration branch — merge all features here first
│
├── feature/auth              ← Login, signup, reset password
├── feature/scan              ← Camera, AI scan, result screen
├── feature/ai-model          ← EfficientNet training and ONNX export
├── feature/marketplace       ← Marketplace and seller profiles
├── feature/explore           ← Browse and search date database
└── feature/profile           ← User profile and favorites
```

**Commit message convention:**
```
feat: add camera scan screen
fix: resolve login validation error
docs: update model evaluation results
chore: upgrade flutter dependencies
test: add unit tests for scan service
```

---

## 📅 Sprint Plan

| Sprint | Weeks | Focus | Points |
|--------|-------|-------|--------|
| Sprint 1 | 1–2 | Auth, Camera, Language Toggle | 20 |
| Sprint 2 | 3–4 | AI Model, Origin, Nutrition, History | 26 |
| Sprint 3 | 5–6 | Marketplace, Search, Favorites | 30 |
| Sprint 4 | 7–8 | Polish, ONNX export, Testing, Demo | 29 |

---

## ⚠️ Risk Management

| Risk | Severity | Response |
|------|----------|----------|
| Low AI accuracy | High | Augmentation, transfer learning, larger dataset |
| Integration issues | Medium | Early integration testing in Sprint 2 |
| Time constraints | High | Prioritize MUST features, defer WOULD/COULD |
| Dataset limitations | Medium | Collect from multiple sources, balance classes |
| Team availability | Medium | Trello tracking, shared documentation |
| Env setup conflicts | Medium | Docker eliminates this entirely |

---

## ✅ Success Criteria

- [ ] AI identifies ≥ 8 date varieties at ≥ 85% accuracy
- [ ] All MUST-priority user stories implemented
- [ ] Firebase ID Token verified on every backend request
- [ ] AI inference responds in ≤ 3 seconds end-to-end
- [ ] Full Arabic RTL and English LTR support
- [ ] Clean demo-ready build with no critical bugs

---

<p align="center">🌴 Nakhlah · King Saud University · 2025</p>
# nakhlah
AI-powered date identification app
