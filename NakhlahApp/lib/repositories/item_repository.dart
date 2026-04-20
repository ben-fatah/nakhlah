import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/market_item.dart';

/// All Firestore / Storage operations for the `items` collection.
///
/// Items are stored at the top-level `items/{itemId}` to support
/// market-wide queries without collection group searches.
class ItemRepository {
  ItemRepository._();
  static final instance = ItemRepository._();

  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;
  static const _uuid = Uuid();

  CollectionReference<Map<String, dynamic>> get _itemsRef =>
      _firestore.collection('items');

  // ── Create ────────────────────────────────────────────────────────────────

  /// Add a new item listing for the currently signed-in seller.
  ///
  /// [imageFile] is required for new items — uploaded to
  /// `item_images/{itemId}.jpg`.
  Future<MarketItem> addItem({
    required String sellerName,
    required String sellerAvatarUrl,
    required String title,
    required String description,
    double? price,
    required File imageFile,
    String variety = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final itemId = _uuid.v4();
    final imageUrl = await _uploadImage(itemId: itemId, file: imageFile);

    final item = MarketItem(
      id: itemId,
      sellerId: user.uid,
      sellerName: sellerName,
      sellerAvatarUrl: sellerAvatarUrl,
      title: title.trim(),
      description: description.trim(),
      price: price,
      imageUrl: imageUrl,
      variety: variety,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _itemsRef.doc(itemId).set(item.toFirestore());
    return item;
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Fetch a single item once. Returns null if not found.
  Future<MarketItem?> getItem(String id) async {
    final doc = await _itemsRef.doc(id).get();
    if (!doc.exists) return null;
    return MarketItem.fromFirestore(doc);
  }

  /// Stream of all active items, newest first (market feed).
  Stream<List<MarketItem>> watchActiveItems() {
    return _itemsRef
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => MarketItem.fromFirestore(d)).toList(),
        );
  }

  /// Stream of all items belonging to [sellerId], newest first
  /// (for Seller Dashboard — includes inactive).
  Stream<List<MarketItem>> watchSellerItems(String sellerId) {
    return _itemsRef
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => MarketItem.fromFirestore(d)).toList(),
        );
  }

  // ── Update ────────────────────────────────────────────────────────────────

  /// Edit an existing item. Optionally replace the image.
  Future<void> updateItem({
    required MarketItem item,
    File? newImageFile,
  }) async {
    String imageUrl = item.imageUrl;
    if (newImageFile != null) {
      imageUrl = await _uploadImage(itemId: item.id, file: newImageFile);
    }
    final updated = item.copyWith(imageUrl: imageUrl);
    await _itemsRef.doc(item.id).update(updated.toUpdateMap());
  }

  /// Soft delete — sets isActive = false. Chat history references remain valid.
  Future<void> deactivateItem(String itemId) async {
    await _itemsRef.doc(itemId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Hard delete — use only when also deleting Storage image.
  Future<void> deleteItem(String itemId) async {
    await _itemsRef.doc(itemId).delete();
    try {
      await _storage.ref().child('item_images/$itemId.jpg').delete();
    } catch (_) {
      // Storage file may not exist; ignore.
    }
  }

  // ── Storage ───────────────────────────────────────────────────────────────

  Future<String> _uploadImage({
    required String itemId,
    required File file,
  }) async {
    final ext = file.path.split('.').last.toLowerCase();
    final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
    final ref = _storage
        .ref()
        .child('item_images')
        .child('$itemId.$ext');

    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: contentType),
    );
    return task.ref.getDownloadURL();
  }
}
