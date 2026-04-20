import 'package:cloud_firestore/cloud_firestore.dart';

/// A chat room between a buyer and a seller about a specific item.
///
/// Stored at `chats/{chatId}` where:
///   `chatId = "${buyerId}_${sellerId}_${itemId}"`   (deterministic)
///
/// The deterministic key means the same buyer/seller/item always reuse
/// the existing room — no duplicates, no lookup needed.
class ChatRoom {
  final String id; // chatId = buyerId_sellerId_itemId
  final String buyerId;
  final String buyerName;
  final String buyerAvatarUrl;
  final String sellerId;
  final String sellerName;
  final String sellerAvatarUrl;
  final String itemId;
  final String itemTitle;
  final String itemImageUrl;
  final String lastMessage;
  final DateTime lastMessageAt;
  final String lastMessageSenderId;

  /// Unread count for the BUYER. Updated with FieldValue.increment.
  final int unreadBuyer;

  /// Unread count for the SELLER. Updated with FieldValue.increment.
  final int unreadSeller;

  const ChatRoom({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    this.buyerAvatarUrl = '',
    required this.sellerId,
    required this.sellerName,
    this.sellerAvatarUrl = '',
    required this.itemId,
    required this.itemTitle,
    this.itemImageUrl = '',
    this.lastMessage = '',
    required this.lastMessageAt,
    this.lastMessageSenderId = '',
    this.unreadBuyer = 0,
    this.unreadSeller = 0,
  });

  /// Unread count for the viewer identified by [uid].
  int unreadFor(String uid) =>
      uid == sellerId ? unreadSeller : unreadBuyer;

  factory ChatRoom.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return ChatRoom(
      id: doc.id,
      buyerId: d['buyerId'] as String? ?? '',
      buyerName: d['buyerName'] as String? ?? '',
      buyerAvatarUrl: d['buyerAvatarUrl'] as String? ?? '',
      sellerId: d['sellerId'] as String? ?? '',
      sellerName: d['sellerName'] as String? ?? '',
      sellerAvatarUrl: d['sellerAvatarUrl'] as String? ?? '',
      itemId: d['itemId'] as String? ?? '',
      itemTitle: d['itemTitle'] as String? ?? '',
      itemImageUrl: d['itemImageUrl'] as String? ?? '',
      lastMessage: d['lastMessage'] as String? ?? '',
      lastMessageAt:
          (d['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageSenderId: d['lastMessageSenderId'] as String? ?? '',
      unreadBuyer: (d['unreadBuyer'] as num?)?.toInt() ?? 0,
      unreadSeller: (d['unreadSeller'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'buyerId': buyerId,
    'buyerName': buyerName,
    'buyerAvatarUrl': buyerAvatarUrl,
    'sellerId': sellerId,
    'sellerName': sellerName,
    'sellerAvatarUrl': sellerAvatarUrl,
    'itemId': itemId,
    'itemTitle': itemTitle,
    'itemImageUrl': itemImageUrl,
    'lastMessage': lastMessage,
    'lastMessageAt': FieldValue.serverTimestamp(),
    'lastMessageSenderId': lastMessageSenderId,
    'unreadBuyer': unreadBuyer,
    'unreadSeller': unreadSeller,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

/// A single message inside a [ChatRoom].
///
/// Stored at `chats/{chatId}/messages/{msgId}`.
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime sentAt;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.sentAt,
    this.isRead = false,
  });

  factory ChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return ChatMessage(
      id: doc.id,
      senderId: d['senderId'] as String? ?? '',
      senderName: d['senderName'] as String? ?? '',
      text: d['text'] as String? ?? '',
      sentAt: (d['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: d['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'senderId': senderId,
    'senderName': senderName,
    'text': text,
    'sentAt': FieldValue.serverTimestamp(),
    'isRead': isRead,
  };
}
