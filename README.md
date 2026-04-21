# 🌴 Nakhlah — Offline AI-Powered Date Identification

<p align="center">
  <img src="docs/assets/nakhlah_logo.png" alt="Nakhlah Logo" width="200"/>
</p>

<p align="center">
  <b>Smart Date Intelligence — Identify · Explore · Buy</b><br/>
  Flutter · Firebase · ONNX Runtime · EfficientNet-B2 (100% Offline AI)
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.22.x-blue?logo=flutter" />
  <img src="https://img.shields.io/badge/Dart-3.4-blue?logo=dart" />
  <img src="https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?logo=firebase" />
  <img src="https://img.shields.io/badge/AI-ONNX%20Runtime-red?logo=onnx" />
  <img src="https://img.shields.io/badge/Status-100%25%20Offline%20Inference-green" />
</p>

---

## 📖 Table of Contents

- [Project Overview](#project-overview)
- [Team Members](#team-members)
- [System Architecture](#system-architecture)
- [Key Features](#key-features)
- [AI Model Details](#ai-model-details)
- [Getting Started](#getting-started)
- [Firebase Setup](#firebase-setup)
- [Branch Strategy](#branch-strategy)

---

## 📱 Project Overview

**Nakhlah** is a mobile application that uses AI-powered image recognition to identify date fruit varieties. Users take a photo of any date and instantly receive identifying information, **entirely offline** without needing a backend server:

- 🌴 **Date Type** — Identifies up to 17 varieties (e.g., Medjool, Ajwa, Sukkari, Deglet Noor)
- 🗺️ **Origin Information** — Country and cultivation region
- 🥗 **Nutritional Profile** — Calories, sugar, fiber, vitamins, minerals
- 📊 **Confidence Score** — Color-coded reliability indicator
- 🛒 **Marketplace** — Verified trusted date sellers integrated directly

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

Nakhlah uses a **Backend-less, AI-Edge Architecture**. After a major architectural refactor, all complex backend microservices were eliminated in favor of **100% on-device AI inference** coupled with Firebase Serverless infrastructure.

```
┌────────────────────────────────────────────────────────┐
│               Flutter Presentation Layer               │
│          (Riverpod State Management, Routing)          │
└─────────────────────────┬──────────────────────────────┘
                          │
┌─────────────────────────▼──────────────────────────────┐
│                  Domain / Service Layer                │
│                                                        │
│  ┌──────────────────┐            ┌──────────────────┐  │
│  │ Firebase Auth    │            │ Local Inference  │  │
│  │ (Phone & Email)  │            │ (Dart Isolate)   │  │
│  └────────┬─────────┘            └────────┬─────────┘  │
└───────────┼───────────────────────────────┼────────────┘
            │                               │
┌───────────▼───────────┐         ┌─────────▼──────────┐
│    Firebase Cloud     │         │    ONNX Runtime    │
│  (Firestore Storage)  │         │  (EfficientNet-B2) │
└───────────────────────┘         └────────────────────┘
```

**Key Architectural Benefits**:
- **Offline Capable**: Image classification runs fully locally via the `onnxruntime` package. No internet required to scan!
- **Zero Backend DevOps**: FastAPI and Docker have been removed. Syncs data natively through Firebase Firestore.
- **Persistent Native Auth**: Relies directly on `FirebaseAuth` (Email/Password + Phone Auth with native SMS OTP completion) preventing session drops.

---

## ✨ Key Features

- **Blazing Fast On-Device AI**: Leverages background `Isolates` and `INT8` Dynamic Quantized ONNX weights (~8.7MB) to achieve high-accuracy image classification under 150ms on modern phones.
- **Phone Auth**: Standardized and robust phone login using Firebase's native verification.
- **Marketplace Hub**: Browse and review local sellers entirely powered by Firebase.
- **Idempotent Data Model**: Custom Firestore serialization ensures safe writes and protects user join timestamps (`createdAt`) across application sessions.

---

## 🤖 AI Model Details

- **Architecture**: EfficientNet-B2 (PyTorch) -> ONNX Format
- **Task**: Multi-class image classification (17 classes)
- **Classes**: `ajwa`, `allig`, `amber`, `aseel`, `deglet_nour`, `galaxy`, `kalmi`, `khorma`, `medjool`, `meneifi`, `muzafati`, `nabtat_ali`, `rutab`, `shaishe`, `sokari`, `sugaey`, `zahidi`
- **Export Format**: ONNX IR-9 with `INT8` Dynamic Quantization.
- **Integration**: Model binaries are bundled within the app's `assets/models` folder and actively maintained via `reexport_model.py`.

---

## 🚀 Getting Started

### Prerequisites

```bash
# Verify Git
git --version

# Flutter — must be stable channel, 3.22.x or 3.24.x
flutter channel stable
flutter upgrade
flutter --version
flutter doctor          # Fix ALL issues shown before continuing
```

### Clone & Run

```bash
git clone https://github.com/YOUR_ORG/nakhlah.git
cd nakhlah/NakhlahApp

# Install packages
flutter pub get

# Generate firebase_options.dart (requires permissions)
dart pub global activate flutterfire_cli
flutterfire configure

# Run on simulator or device
flutter run
```

---

## 🔥 Firebase Setup

If you need to set up the project on a new Firebase environment:

1. Go to https://console.firebase.google.com → Create project: **Nakhlah**
2. Enable: **Authentication** (Email/Password + Phone Auth), **Firestore**, **Storage**. *(Note: Phone Auth requires the Blaze Plan)*
3. Add an Android App → Package name: `com.nakhlah.app`
4. Register the required `SHA-1` and `SHA-256` keys to allow Firebase Phone Auth to function correctly.
5. Download `google-services.json` and place it at: `NakhlahApp/android/app/google-services.json`.

---

## 🌿 Branch Strategy

```text
main          ← Production-ready code only (protected)
develop       ← Integration branch — merge all features here first
│
├── feature/auth              ← Login, signup, reset password
├── feature/scan              ← Camera, AI scan, result screen
├── feature/marketplace       ← Marketplace and seller profiles
└── feature/profile           ← User profile and favorites
```

**Commit message convention:**
```text
feat: add camera scan screen
fix: resolve login validation error
chore: upgrade flutter dependencies
```

---

<p align="center">🌴 Nakhlah · King Saud University · 2025</p>
