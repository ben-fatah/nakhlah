import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/locale_provider.dart';
import '../repositories/seller_review_repository.dart';
import '../repositories/user_repository.dart';
import '../theme/app_colors.dart';

/// Screen for a buyer to submit a rating and comment for a seller.
class SellerReviewScreen extends StatefulWidget {
  final String sellerId;
  final String itemId;
  final String itemTitle;

  const SellerReviewScreen({
    super.key,
    required this.sellerId,
    required this.itemId,
    required this.itemTitle,
  });

  @override
  State<SellerReviewScreen> createState() => _SellerReviewScreenState();
}

class _SellerReviewScreenState extends State<SellerReviewScreen> {
  final _commentCtrl = TextEditingController();
  int _rating = 0;
  bool _isLoading = false;

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localeProvider.isArabic
                ? 'يرجى اختيار التقييم'
                : 'Please select a rating',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;

    setState(() => _isLoading = true);

    try {
      final userRepo = UserRepository();
      final appUser = await userRepo.getUser(me.uid);
      final reviewerName = appUser?.fullName.isNotEmpty == true
          ? appUser!.fullName
          : (me.displayName ?? 'Buyer');

      await SellerReviewRepository.instance.addReview(
        sellerId: widget.sellerId,
        itemId: widget.itemId,
        reviewerId: me.uid,
        reviewerName: reviewerName,
        rating: _rating,
        comment: _commentCtrl.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localeProvider.isArabic
                ? 'شكراً لتقييمك!'
                : 'Thank you for your review!',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.verifiedGreen,
        ),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localeProvider.isArabic
                ? 'حدث خطأ، حاول مرة أخرى'
                : 'An error occurred, please try again',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = localeProvider.isArabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: AppBar(
          backgroundColor: AppColors.brown900,
          foregroundColor: Colors.white,
          title: Text(
            isAr ? 'تقييم البائع' : 'Review Seller',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              isAr ? 'تقييم تجربتك لمنتج:' : 'Rate your experience for:',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              widget.itemTitle,
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.brown900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final displayStar = index + 1;
                final isSelected = displayStar <= _rating;

                return GestureDetector(
                  onTap: () => setState(() => _rating = displayStar),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 44,
                      color: isSelected ? AppColors.goldBadge : Colors.grey.shade300,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Text(
              _rating == 0
                  ? (isAr ? 'لم يتم التقييم' : 'Not rated')
                  : '$_rating ${isAr ? 'نجوم' : 'Stars'}',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _rating > 0 ? AppColors.goldDark : Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Comment Box
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              decoration: InputDecoration(
                hintText: isAr
                    ? 'أضف تعليقاً (اختياري)...'
                    : 'Add a comment (optional)...',
                hintStyle: GoogleFonts.cairo(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.brown700),
                ),
              ),
              style: GoogleFonts.cairo(fontSize: 14),
            ),
            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brown700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isAr ? 'إرسال التقييم' : 'Submit Review',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
