import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_models.dart';
import '../models/market_item.dart';

/// All Firestore operations for the `chats` collection.
///
/// Chat room IDs are deterministic:
///   `chatId = "${buyerId}_${sellerId}_${itemId}"`
///
/// This guarantees that the same buyer + seller + item never creates
/// duplicate rooms — regardless of how many times the user taps
/// "Contact Seller".
///
/// Unread counts are always updated with [FieldValue.increment] — never
/// set directly — to ensure atomic, race-condition-free increments.
class ChatRepository {
  ChatRepository._();
  static final instance = ChatRepository._();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _chatsRef =>
      _firestore.collection('chats');

  CollectionReference<Map<String, dynamic>> _messagesRef(String chatId) =>
      _chatsRef.doc(chatId).collection('messages');

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Build the deterministic chat room id.
  static String buildChatId({
    required String buyerId,
    required String sellerId,
    required String itemId,
  }) => '${buyerId}_${sellerId}_$itemId';

  User get _me {
    final u = _auth.currentUser;
    if (u == null) throw Exception('Not authenticated');
    return u;
  }

  // ── Room management ───────────────────────────────────────────────────────

  /// Open (or create) a chat room for the current user about [item].
  ///
  /// If the room already exists the existing document is returned unchanged.
  /// The seller's name/avatar and item fields are denormalized on creation.
  ///
  /// Returns the [chatId] to pass to [ChatScreen].
  Future<String> openRoom({
    required MarketItem item,
    required String buyerName,
    String buyerAvatarUrl = '',
  }) async {
    final me = _me;
    final chatId = buildChatId(
      buyerId: me.uid,
      sellerId: item.sellerId,
      itemId: item.id,
    );

    final docRef = _chatsRef.doc(chatId);
    final snap = await docRef.get();

    if (!snap.exists) {
      // Create room with zero unread counts
      final room = ChatRoom(
        id: chatId,
        buyerId: me.uid,
        buyerName: buyerName,
        buyerAvatarUrl: buyerAvatarUrl,
        sellerId: item.sellerId,
        sellerName: item.sellerName,
        sellerAvatarUrl: item.sellerAvatarUrl,
        itemId: item.id,
        itemTitle: item.title,
        itemImageUrl: item.imageUrl,
        lastMessageAt: DateTime.now(),
      );
      await docRef.set(room.toFirestore());
    }

    return chatId;
  }

  // ── Messaging ─────────────────────────────────────────────────────────────

  /// Send a text message and atomically update the chat room summary.
  ///
  /// The opposite party's unreadCount is incremented with [FieldValue.increment]
  /// — never overwritten — to prevent race conditions.
  Future<void> sendMessage({
    required String chatId,
    required String text,
    required String senderName,
    required bool isSeller, // true = sender is the seller
  }) async {
    final me = _me;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // 1. Write message document (auto-id)
    await _messagesRef(chatId).add(
      ChatMessage(
        id: '',
        senderId: me.uid,
        senderName: senderName,
        text: trimmed,
        sentAt: DateTime.now(),
      ).toFirestore(),
    );

    // 2. Update chat room summary atomically
    // Increment the OTHER party's unread counter.
    await _chatsRef.doc(chatId).update({
      'lastMessage': trimmed,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageSenderId': me.uid,
      // buyer sent → seller's counter goes up, and vice-versa
      if (isSeller)
        'unreadBuyer': FieldValue.increment(1)
      else
        'unreadSeller': FieldValue.increment(1),
    });
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Real-time stream of messages in chronological order.
  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _messagesRef(chatId)
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => ChatMessage.fromFirestore(d)).toList(),
        );
  }

  /// Real-time stream of all rooms the current user participates in,
  /// newest message first.
  ///
  /// Works for both buyers (`buyerId == uid`) and sellers (`sellerId == uid`).
  Stream<List<ChatRoom>> watchMyRooms() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    // Firestore doesn't support OR queries across fields, so we run
    // two separate queries and merge the results in memory.
    final sellerQuery = _chatsRef
        .where('sellerId', isEqualTo: uid)
        .orderBy('lastMessageAt', descending: true);

    final buyerQuery = _chatsRef
        .where('buyerId', isEqualTo: uid)
        .orderBy('lastMessageAt', descending: true);

    late final StreamController<List<ChatRoom>> controller;
    StreamSubscription? subA;
    StreamSubscription? subB;

    List<ChatRoom> sellerRooms = [];
    List<ChatRoom> buyerRooms = [];

    void emit() {
      if (controller.isClosed) return;
      final merged = <String, ChatRoom>{};
      for (final r in [...sellerRooms, ...buyerRooms]) {
        merged[r.id] = r;
      }
      final sorted = merged.values.toList()
        ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      controller.add(sorted);
    }

    controller = StreamController<List<ChatRoom>>.broadcast(
      onListen: () {
        subA = sellerQuery.snapshots().listen((s) {
          sellerRooms = s.docs.map(ChatRoom.fromFirestore).toList();
          emit();
        });

        subB = buyerQuery.snapshots().listen((s) {
          buyerRooms = s.docs.map(ChatRoom.fromFirestore).toList();
          emit();
        });
      },
      onCancel: () {
        subA?.cancel();
        subB?.cancel();
      },
    );

    return controller.stream;
  }

  // ── Mark as read ──────────────────────────────────────────────────────────

  /// Reset the unread counter for [uid] in [chatId] to 0.
  Future<void> markRead({
    required String chatId,
    required bool isSeller,
  }) async {
    await _chatsRef.doc(chatId).update({
      if (isSeller) 'unreadSeller': 0 else 'unreadBuyer': 0,
    });
  }
}
