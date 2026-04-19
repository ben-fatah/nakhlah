import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../domain/scan_history_notifier.dart';
import '../models/scan_result.dart';

/// Hybrid scan repository.
///
/// Flow on every new scan:
///   1. Save to [ScanHistoryNotifier] immediately (SharedPreferences) — instant UI.
///   2. Upload captured image to Firebase Storage asynchronously.
///   3. Write entry to `/users/{uid}/scan_history/{scanId}` in Firestore.
///
/// On app start, [syncFromFirestore()] merges cloud history into local state
/// so history survives device reinstalls and works across devices.
class ScanRepository {
  ScanRepository._();
  static final ScanRepository instance = ScanRepository._();

  final _auth     = FirebaseAuth.instance;
  final _storage  = FirebaseStorage.instance;
  final _firestore = FirebaseFirestore.instance;
  final _uuid     = const Uuid();

  // ── Save a new scan ─────────────────────────────────────────────────────────

  /// Save scan result locally (instant) then sync to Firebase in background.
  ///
  /// [imageFile] is the compressed image captured/picked by the user.
  /// Returns the generated scan ID.
  Future<String> saveScan({
    required ScanResult result,
    required File imageFile,
  }) async {
    final scanId = _uuid.v4();
    final now    = DateTime.now();

    // ── Step 1: local persist (instant, never blocks UI) ────────────────────
    final localEntry = ScanHistoryEntry(
      id: scanId,
      nameEn: result.nameEn,
      nameAr: result.nameAr,
      originEn: result.originEn,
      originAr: result.originAr,
      confidence: result.confidence,
      calories: result.calories,
      carbs: result.carbs,
      fiber: result.fiber,
      potassium: result.potassium,
      imagePath: imageFile.path,   // local temp path shown immediately
      imageUrl: null,              // will be updated after upload
      scannedAt: now,
    );
    scanHistoryNotifier.add(localEntry);

    // ── Step 2 & 3: upload + Firestore (fire-and-forget, never crashes app) ─
    _syncToFirebase(scanId: scanId, entry: localEntry, imageFile: imageFile);

    return scanId;
  }

  /// Upload image → Firestore. Runs in background — errors are logged only.
  Future<void> _syncToFirebase({
    required String scanId,
    required ScanHistoryEntry entry,
    required File imageFile,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return; // not signed in — local only

    try {
      // Upload image
      final url = await _uploadImage(uid: uid, scanId: scanId, file: imageFile);

      // Write to Firestore
      final data = _entryToFirestore(entry, url);
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('scan_history')
          .doc(scanId)
          .set(data);

      // Update local entry with the cloud URL so future displays use it
      if (url != null) {
        scanHistoryNotifier.updateImageUrl(scanId, url);
      }

      debugPrint('[ScanRepository] Synced scan $scanId → Firestore');
    } catch (e) {
      debugPrint('[ScanRepository] Firebase sync failed (non-fatal): $e');
    }
  }

  /// Upload compressed image to Storage. Returns download URL or null.
  Future<String?> _uploadImage({
    required String uid,
    required String scanId,
    required File file,
  }) async {
    try {
      final ext = file.path.split('.').last.toLowerCase();
      final contentType = (ext == 'jpg' || ext == 'jpeg') ? 'image/jpeg' : 'image/$ext';
      final ref = _storage
          .ref()
          .child('scan_images')
          .child(uid)
          .child('$scanId.$ext');
      final task = await ref.putFile(
        file,
        SettableMetadata(contentType: contentType),
      );
      return await task.ref.getDownloadURL();
    } catch (e) {
      debugPrint('[ScanRepository] Image upload failed: $e');
      return null;
    }
  }

  Map<String, dynamic> _entryToFirestore(ScanHistoryEntry e, String? imageUrl) => {
    'scanId':     e.id,
    'nameEn':     e.nameEn,
    'nameAr':     e.nameAr,
    'originEn':   e.originEn,
    'originAr':   e.originAr,
    'confidence': e.confidence,
    'calories':   e.calories,
    'carbs':      e.carbs,
    'fiber':      e.fiber,
    'potassium':  e.potassium,
    'imageUrl':   imageUrl,
    'scannedAt':  FieldValue.serverTimestamp(),
  };

  // ── Sync from Firestore → local (call once at startup) ─────────────────────

  /// Merge the user's cloud scan history into the local notifier.
  ///
  /// Only fetches entries newer than the oldest local entry to minimise reads.
  /// Safe to call even when offline — Firestore returns cached data.
  Future<void> syncFromFirestore() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      // Fetch last 50 entries from Firestore (enough for reasonable history)
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('scan_history')
          .orderBy('scannedAt', descending: true)
          .limit(50)
          .get(const GetOptions(source: Source.serverAndCache));

      final localIds = scanHistoryNotifier.value.map((e) => e.id).toSet();
      final newEntries = <ScanHistoryEntry>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final scanId = data['scanId'] as String? ?? doc.id;
        if (localIds.contains(scanId)) continue; // already local

        final ts = data['scannedAt'] as Timestamp?;
        newEntries.add(ScanHistoryEntry(
          id:         scanId,
          nameEn:     data['nameEn']     as String? ?? '',
          nameAr:     data['nameAr']     as String? ?? '',
          originEn:   data['originEn']   as String? ?? '',
          originAr:   data['originAr']   as String? ?? '',
          confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
          calories:   (data['calories']  as num?)?.toInt() ?? 0,
          carbs:      (data['carbs']     as num?)?.toInt() ?? 0,
          fiber:      (data['fiber']     as num?)?.toInt() ?? 0,
          potassium:  (data['potassium'] as num?)?.toInt() ?? 0,
          imageUrl:   data['imageUrl']   as String?,
          imagePath:  '',
          scannedAt:  ts?.toDate() ?? DateTime.now(),
        ));
      }

      if (newEntries.isNotEmpty) {
        scanHistoryNotifier.mergeFromCloud(newEntries);
        debugPrint('[ScanRepository] Merged ${newEntries.length} entries from Firestore');
      }
    } catch (e) {
      debugPrint('[ScanRepository] Firestore sync failed (non-fatal): $e');
    }
  }
}
