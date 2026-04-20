import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/chat_models.dart';
import '../providers/locale_provider.dart';
import '../repositories/chat_repository.dart';
import '../theme/app_colors.dart';
import 'seller_review_screen.dart';

/// Real-time chat between a buyer and a seller.
///
/// Receives a pre-created [chatId] and the [isSeller] flag so it knows whose
/// counter to reset and which side to increment on send.
class ChatScreen extends StatefulWidget {
  /// The deterministic chat room id (`buyerId_sellerId_itemId`).
  final String chatId;

  /// Display name for the AppBar (the OTHER party's name).
  final String peerName;

  /// The item title shown as a subtitle in the AppBar.
  final String itemTitle;

  /// `true` when the current user is the seller in this room.
  final bool isSeller;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.peerName,
    required this.itemTitle,
    required this.isSeller,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _repo = ChatRepository.instance;

  late final String _myUid;
  late final String _myName;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser!;
    _myUid = user.uid;
    _myName = user.displayName ?? 'User';

    // Mark messages as read when the screen opens
    _repo.markRead(chatId: widget.chatId, isSeller: widget.isSeller);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _msgCtrl.clear();

    try {
      await _repo.sendMessage(
        chatId: widget.chatId,
        text: text,
        senderName: _myName,
        isSeller: widget.isSeller,
      );
      _scrollToBottom();
    } catch (_) {
      // Restore text so user doesn't lose it
      _msgCtrl.text = text;
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = localeProvider.isArabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(child: _buildMessageList()),
            _buildInputBar(isAr),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.brown900,
      foregroundColor: Colors.white,
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.peerName,
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            widget.itemTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
      actions: [
        if (!widget.isSeller)
          IconButton(
            tooltip: localeProvider.isArabic ? 'تقييم البائع' : 'Review Seller',
            icon: const Icon(Icons.star_outline_rounded),
            onPressed: () {
              final parts = widget.chatId.split('_');
              if (parts.length >= 3) {
                // chatId = buyerId_sellerId_itemId
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SellerReviewScreen(
                      sellerId: parts[1],
                      itemId: parts.sublist(2).join('_'),
                      itemTitle: widget.itemTitle,
                    ),
                  ),
                );
              }
            },
          ),
      ],
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<List<ChatMessage>>(
      stream: _repo.watchMessages(widget.chatId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.brown700),
          );
        }

        final messages = snap.data ?? [];

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 48,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  localeProvider.isArabic
                      ? 'ابدأ المحادثة...'
                      : 'Start the conversation...',
                  style: GoogleFonts.cairo(
                    color: Colors.grey.shade400,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        }

        // Auto-scroll when new messages arrive
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          itemCount: messages.length,
          itemBuilder: (context, i) {
            final msg = messages[i];
            final isMe = msg.senderId == _myUid;

            // Show date divider when day changes
            final showDivider = i == 0 ||
                !_sameDay(messages[i - 1].sentAt, msg.sentAt);

            return Column(
              children: [
                if (showDivider) _DateDivider(date: msg.sentAt),
                _MessageBubble(message: msg, isMe: isMe),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInputBar(bool isAr) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            8,
        top: 8,
        left: 12,
        right: 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: TextField(
                controller: _msgCtrl,
                maxLines: null,
                textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                style: GoogleFonts.cairo(fontSize: 14),
                decoration: InputDecoration(
                  hintText: isAr ? 'اكتب رسالة...' : 'Type a message...',
                  hintStyle: GoogleFonts.cairo(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSending ? null : _send,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isSending
                    ? AppColors.brown700.withValues(alpha: 0.4)
                    : AppColors.brown700,
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Message Bubble ─────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? AppColors.brown700 : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: isMe ? Colors.white : AppColors.brown900,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _formatTime(message.sentAt),
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.65)
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Date Divider ───────────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              _formatDate(date),
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      return 'Yesterday';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
