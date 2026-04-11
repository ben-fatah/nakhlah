import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../theme/app_colors.dart';
import '../models/product_model.dart';
import '../repositories/product_repository.dart';

// ── Screen ───────────────────────────────────────────────────────────────────
class MarketScreen extends StatefulWidget {
  /// Called when the screen wants to switch to another shell tab.
  /// Pass the nav-bar index: 0=Home, 1=Explore, 3=Market, 4=Profile.
  final ValueChanged<int>? onTabChange;

  const MarketScreen({super.key, this.onTabChange});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final Set<int> _cart = {};
  final _searchCtrl = TextEditingController();
  final _productRepo = ProductRepository();

  List<Map<String, dynamic>> _getFilters(AppLocalizations l) => [
    {'key': 'all', 'label': l.allVarieties},
    {'key': 'medjool', 'label': l.filterMedjool},
    {'key': 'ajwa', 'label': l.filterAjwa},
    {'key': 'sukkari', 'label': l.filterSukkari},
    {'key': 'khalas', 'label': l.filterKhalas},
  ];

  List<Product> _filtered(AppLocalizations l) {
    return _productRepo.getFiltered(
      l,
      tag: _selectedFilter,
      searchQuery: _searchQuery,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isAr = localeProvider.isArabic;
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.screenBg,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(l),
              _buildSearchBar(l, isAr),
              _buildFilterChips(l),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroBanner(l),
                      const SizedBox(height: 24),
                      _buildSectionHeader(l),
                      const SizedBox(height: 14),
                      _buildProductGrid(l),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            // Navigate back to Home tab via the shell callback.
            // Falls back to Navigator.pop() if used outside the shell.
            onTap: () {
              if (widget.onTabChange != null) {
                widget.onTabChange!(0);
              } else {
                Navigator.of(context).maybePop();
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.brown900.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.home_rounded,
                color: AppColors.brown900,
                size: 22,
              ),
            ),
          ),
          Text(
            l.market,
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.brown900,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.brown900.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: AppColors.brown900,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar(AppLocalizations l, bool isAr) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEDE8E0),
          borderRadius: BorderRadius.circular(50),
        ),
        child: TextField(
          controller: _searchCtrl,
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: GoogleFonts.cairo(fontSize: 14, color: AppColors.brown900),
          decoration: InputDecoration(
            hintText: l.searchHint,
            hintStyle: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            suffixIcon: Icon(
              Icons.search_rounded,
              color: Colors.grey.shade500,
              size: 22,
            ),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ── Filter Chips ───────────────────────────────────────────────────────────
  Widget _buildFilterChips(AppLocalizations l) {
    final filters = _getFilters(l);
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        itemBuilder: (context, i) {
          final f = filters[i];
          final isActive = _selectedFilter == f['key'];
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f['key']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                left: localeProvider.isArabic ? 10 : 0,
                right: localeProvider.isArabic ? 0 : 10,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? AppColors.chipActive : Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: isActive
                      ? AppColors.chipActive
                      : const Color(0xFFE0D8CE),
                ),
              ),
              child: Text(
                f['label']!,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : AppColors.brown900,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Hero Banner ────────────────────────────────────────────────────────────
  Widget _buildHeroBanner(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF1A0A00),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/sukari.png',
                fit: BoxFit.cover,
                colorBlendMode: BlendMode.darken,
                color: Colors.black.withValues(alpha: 0.45),
                errorBuilder: (_, _, _) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [AppColors.brown900, Color(0xFF6B3A1E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            // Text overlay
            Positioned(
              bottom: 20,
              right: localeProvider.isArabic ? 20 : null,
              left: localeProvider.isArabic ? null : 20,
              child: Column(
                crossAxisAlignment: localeProvider.isArabic
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l.isArabic ? 'عرض خاص' : 'Special Offer',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brown900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.sukkariMofatall,
                    style: GoogleFonts.cairo(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    l.isArabic
                        ? 'قطاف الموسم الجديد من مزارع القصيم'
                        : 'New season harvest from Qassim',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section Header ─────────────────────────────────────────────────────────
  Widget _buildSectionHeader(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l.isArabic ? 'أحدث المنتجات' : 'Newest Products',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.brown900,
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade500,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l.isArabic ? 'عرض الكل' : 'View All',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Product Grid ───────────────────────────────────────────────────────────
  Widget _buildProductGrid(AppLocalizations l) {
    final products = _filtered(l);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.85,
        ),
        itemCount: products.length,
        itemBuilder: (context, i) => _ProductCard(
          product: products[i],
          l: l,
          inCart: _cart.contains(i),
          onAddToCart: () => setState(() {
            if (_cart.contains(i)) {
              _cart.remove(i);
            } else {
              _cart.add(i);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l.isArabic ? 'تمت الإضافة إلى السلة' : 'Added to cart',
                    style: GoogleFonts.cairo(),
                  ),
                  backgroundColor: AppColors.brown700,
                  margin: const EdgeInsets.all(16),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          }),
        ),
      ),
    );
  }
}

// ── Product Card ──────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Product product;
  final AppLocalizations l;
  final bool inCart;
  final VoidCallback onAddToCart;

  const _ProductCard({
    required this.product,
    required this.l,
    required this.inCart,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.brown900.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + verified badge
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: Image.asset(
                    product.imagePath,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFF2A3A3A),
                      child: const Icon(
                        Icons.eco_rounded,
                        color: Colors.white54,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                // Verified badge
                if (product.isVerified)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.verifiedGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            l.isArabic ? 'بائع موثوق' : 'Verified',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Heart button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      color: Colors.grey,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product.nameGetter(l),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: localeProvider.isArabic
                        ? TextAlign.right
                        : TextAlign.left,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.brown900,
                    ),
                  ),
                  // Rating
                  Row(
                    mainAxisAlignment: localeProvider.isArabic
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      Text(
                        l.isArabic
                            ? '(${product.reviews} تقييم)'
                            : '(${product.reviews} reviews)',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        product.rating.toString(),
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brown900,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.gold,
                        size: 14,
                      ),
                    ],
                  ),
                  // Price + Cart
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: onAddToCart,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: inCart ? AppColors.gold : AppColors.brown900,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            inCart
                                ? Icons.check_rounded
                                : Icons.add_shopping_cart_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            l.isArabic
                                ? 'ر.س ${product.price.toStringAsFixed(0)}'
                                : 'SAR ${product.price.toStringAsFixed(0)}',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brown900,
                            ),
                          ),
                          Text(
                            product.unitGetter(l),
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
