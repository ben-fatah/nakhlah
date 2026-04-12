import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../domain/cart_notifier.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../theme/app_colors.dart';

/// Full cart screen with quantity controls and order summary.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isAr = localeProvider.isArabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.screenBg,
        body: Column(
          children: [
            _CartHeader(l: l),
            Expanded(
              child: ValueListenableBuilder<List<CartItem>>(
                valueListenable: cartNotifier,
                builder: (context, items, _) {
                  if (items.isEmpty) return _EmptyCart(l: l);
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) =>
                              _CartItemCard(item: items[i], l: l),
                        ),
                      ),
                      _OrderSummary(items: items, l: l),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────
class _CartHeader extends StatelessWidget {
  final AppLocalizations l;
  const _CartHeader({required this.l});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brown900, AppColors.brown700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.isArabic ? 'سلة التسوق' : 'My Cart',
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                ValueListenableBuilder<List<CartItem>>(
                  valueListenable: cartNotifier,
                  builder: (_, items, __) {
                    final total = items.fold(0, (s, i) => s + i.quantity);
                    return Text(
                      l.isArabic
                          ? '$total منتج'
                          : '$total item${total == 1 ? '' : 's'}',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Clear all button
          ValueListenableBuilder<List<CartItem>>(
            valueListenable: cartNotifier,
            builder: (_, items, __) {
              if (items.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _showClearDialog(context, l),
                style: TextButton.styleFrom(foregroundColor: AppColors.gold),
                child: Text(
                  l.isArabic ? 'مسح الكل' : 'Clear All',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          l.isArabic ? 'مسح السلة؟' : 'Clear Cart?',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: Text(
          l.isArabic
              ? 'سيتم حذف جميع المنتجات من السلة.'
              : 'All items will be removed from your cart.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l.isArabic ? 'إلغاء' : 'Cancel',
              style: GoogleFonts.cairo(),
            ),
          ),
          TextButton(
            onPressed: () {
              cartNotifier.clear();
              Navigator.pop(context);
            },
            child: Text(
              l.isArabic ? 'مسح' : 'Clear',
              style: GoogleFonts.cairo(color: Colors.red.shade600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cart Item Card ─────────────────────────────────────────────────────────────
class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final AppLocalizations l;
  const _CartItemCard({required this.item, required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.brown900.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              item.imagePath,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 70,
                height: 70,
                color: AppColors.brown100,
                child: const Icon(
                  Icons.eco_rounded,
                  color: AppColors.brown700,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brown900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.isArabic
                      ? 'ر.س ${item.price.toStringAsFixed(0)} / ${item.unit}'
                      : 'SAR ${item.price.toStringAsFixed(0)} / ${item.unit}',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Subtotal
                    Text(
                      l.isArabic
                          ? 'ر.س ${(item.price * item.quantity).toStringAsFixed(0)}'
                          : 'SAR ${(item.price * item.quantity).toStringAsFixed(0)}',
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brown700,
                      ),
                    ),
                    const Spacer(),
                    // Quantity controls
                    _QuantityControl(productId: item.productId),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Delete button
          GestureDetector(
            onTap: () => cartNotifier.remove(item.productId),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red.shade400,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quantity Control ──────────────────────────────────────────────────────────
class _QuantityControl extends StatelessWidget {
  final String productId;
  const _QuantityControl({required this.productId});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<CartItem>>(
      valueListenable: cartNotifier,
      builder: (_, items, __) {
        final qty = cartNotifier.quantityOf(productId);
        return Row(
          children: [
            _QtyButton(
              icon: Icons.remove,
              onTap: () => cartNotifier.decrement(productId),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '$qty',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brown900,
                ),
              ),
            ),
            _QtyButton(
              icon: Icons.add,
              onTap: () => cartNotifier.increment(productId),
            ),
          ],
        );
      },
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.brown100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.brown700),
      ),
    );
  }
}

// ── Order Summary ─────────────────────────────────────────────────────────────
class _OrderSummary extends StatelessWidget {
  final List<CartItem> items;
  final AppLocalizations l;
  const _OrderSummary({required this.items, required this.l});

  @override
  Widget build(BuildContext context) {
    final subtotal = items.fold(0.0, (s, i) => s + i.price * i.quantity);
    final delivery = subtotal > 0 ? 15.0 : 0.0;
    final total = subtotal + delivery;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brown900.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _SummaryRow(
              label: l.isArabic ? 'المجموع الفرعي' : 'Subtotal',
              value:
                  '${l.isArabic ? 'ر.س' : 'SAR'} ${subtotal.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 6),
            _SummaryRow(
              label: l.isArabic ? 'رسوم التوصيل' : 'Delivery',
              value:
                  '${l.isArabic ? 'ر.س' : 'SAR'} ${delivery.toStringAsFixed(0)}',
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(),
            ),
            _SummaryRow(
              label: l.isArabic ? 'الإجمالي' : 'Total',
              value:
                  '${l.isArabic ? 'ر.س' : 'SAR'} ${total.toStringAsFixed(0)}',
              isBold: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l.isArabic
                            ? 'سيتم إضافة خاصية الدفع قريباً!'
                            : 'Checkout coming soon!',
                        style: GoogleFonts.cairo(color: Colors.white),
                      ),
                      backgroundColor: AppColors.verifiedGreen,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                label: Text(
                  l.isArabic ? 'إتمام الطلب' : 'Checkout',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brown700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final bool isBold;
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: isBold ? AppColors.brown900 : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            color: isBold ? AppColors.brown700 : AppColors.brown900,
          ),
        ),
      ],
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyCart extends StatelessWidget {
  final AppLocalizations l;
  const _EmptyCart({required this.l});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.brown100,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brown900.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 52,
                color: AppColors.brown700,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              l.isArabic ? 'السلة فارغة' : 'Your cart is empty',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.brown900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l.isArabic
                  ? 'أضف منتجات من المتجر لتظهر هنا.'
                  : 'Add products from the market to see them here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                label: Text(
                  l.isArabic ? 'تسوق الآن' : 'Shop Now',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brown700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
