import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/chat_models.dart';
import '../providers/locale_provider.dart';
import '../repositories/chat_repository.dart';
import '../theme/app_colors.dart';
import 'chat_screen.dart';

/// Inbox screen — shows all chat rooms the current user participates in.
///
/// Works for both buyers (conversations they started) and sellers
/// (messages from buyers about their items).
///
/// Unread counts are shown as badges on each room tile.
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = localeProvider.isArabic;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: AppBar(
          backgroundColor: AppColors.brown900,
          foregroundColor: Colors.white,
          title: Text(
            isAr ? 'المحادثات' : 'Messages',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          ),
        ),
        body: StreamBuilder<List<ChatRoom>>(
          stream: ChatRepository.instance.watchMyRooms(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.brown700),
              );
            }

            final rooms = snap.data ?? [];

            if (rooms.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 56,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isAr ? 'لا توجد محادثات بعد' : 'No conversations yet',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isAr
                          ? 'تواصل مع بائع لتبدأ!'
                          : 'Contact a seller to start!',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemCount: rooms.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 10),
              itemBuilder: (context, i) =>
                  _ChatRoomTile(room: rooms[i], myUid: uid, isAr: isAr),
            );
          },
        ),
      ),
    );
  }
}

// ── Chat Room Tile ─────────────────────────────────────────────────────────────

class _ChatRoomTile extends StatelessWidget {
  final ChatRoom room;
  final String myUid;
  final bool isAr;

  const _ChatRoomTile({
    required this.room,
    required this.myUid,
    required this.isAr,
  });

  bool get _isSeller => myUid == room.sellerId;

  /// The name of the OTHER party to display.
  String get _peerName => _isSeller ? room.buyerName : room.sellerName;

  /// Avatar URL of the other party.
  String get _peerAvatar =>
      _isSeller ? room.buyerAvatarUrl : room.sellerAvatarUrl;

  int get _unread => room.unreadFor(myUid);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: room.id,
              peerName: _peerName,
              itemTitle: room.itemTitle,
              isSeller: _isSeller,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _unread > 0
                  ? AppColors.brown700.withValues(alpha: 0.3)
                  : AppColors.borderLight,
              width: _unread > 0 ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // ── Avatar ─────────────────────────────────────────────────
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brown100,
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: ClipOval(
                      child: _peerAvatar.isNotEmpty
                          ? Image.network(
                              _peerAvatar,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _avatarFallback(),
                            )
                          : _avatarFallback(),
                    ),
                  ),
                  // Unread badge
                  if (_unread > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: AppColors.brown700,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _unread > 9 ? '9+' : '$_unread',
                            style: GoogleFonts.cairo(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // ── Text ───────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            _peerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontWeight: _unread > 0
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.brown900,
                            ),
                          ),
                        ),
                        Text(
                          _formatTime(room.lastMessageAt),
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: _unread > 0
                                ? AppColors.brown700
                                : Colors.grey.shade400,
                            fontWeight: _unread > 0
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Item title
                    Text(
                      room.itemTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: AppColors.goldDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Last message
                    Text(
                      room.lastMessage.isEmpty
                          ? (isAr ? 'بدأت المحادثة' : 'Conversation started')
                          : room.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: _unread > 0
                            ? AppColors.brown900
                            : Colors.grey.shade500,
                        fontWeight: _unread > 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback() {
    final initial = _peerName.isNotEmpty ? _peerName[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.cairo(
          color: AppColors.brown700,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '$h:$m';
    }
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    if (dt.year == now.year) return '${dt.day} ${months[dt.month - 1]}';
    return '${dt.day}/${dt.month}/${dt.year % 100}';
  }
}
