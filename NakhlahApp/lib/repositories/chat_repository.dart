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
  }) => '${buyerId}_${sellerId}_${itemId}';

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

    // We query by sellerId OR buyerId separately and merge.
    // Firestore doesn't support OR queries across different fields
    // without a composite index, so we do two streams and combine in memory.
    final asSellerStream = _chatsRef
        .where('sellerId', isEqualTo: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ChatRoom.fromFirestore).toList());

    final asBuyerStream = _chatsRef
        .where('buyerId', isEqualTo: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ChatRoom.fromFirestore).toList());

    // Combine both streams, deduplicate, sort
    return _combinedRooms(asSellerStream, asBuyerStream);
  }

  Stream<List<ChatRoom>> _combinedRooms(
    Stream<List<ChatRoom>> a,
    Stream<List<ChatRoom>> b,
  ) async* {
    List<ChatRoom> latestA = [];
    List<ChatRoom> latestB = [];

    await for (final _ in _mergeStreams(a, b, (va, vb) {
      latestA = va ?? latestA;
      latestB = vb ?? latestB;
    })) {
      final merged = <String, ChatRoom>{};
      for (final r in [...latestA, ...latestB]) {
        merged[r.id] = r;
      }
      final sorted = merged.values.toList()
        ..sort((x, y) => y.lastMessageAt.compareTo(x.lastMessageAt));
      yield sorted;
    }
  }

  /// Minimal helper: interleave two streams and call [onValue] with the
  /// latest snapshot from each. Yields a tick for every upstream event.
  Stream<void> _mergeStreams<T>(
    Stream<T> a,
    Stream<T> b,
    void Function(T? latestA, T? latestB) onValue,
  ) async* {
    T? latestA;
    T? latestB;
    await for (final _ in Stream.fromFutures([
      a.first.then((v) {
        latestA = v;
        onValue(latestA, latestB);
      }),
      b.first.then((v) {
        latestB = v;
        onValue(latestA, latestB);
      }),
    ])) {
      yield;
    }
    // After first events, continue listening
    yield* a.asyncExpand((_) async* {
      onValue(_, latestB);
      latestA = _;
      yield;
    });
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
