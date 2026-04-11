import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

const Color _kBg = Color(0xFFF5F0EB);
const Color _kBrown = Color(0xFF3B1F13);
const Color _kBrown700 = Color(0xFF5C3A1E);
const Color _kGold = Color(0xFFE8B84B);
const Color _kCard = Color(0xFFFFFFFF);
const Color _kChipActive = Color(0xFF3B1F13);

// ── Data models ──────────────────────────────────────────────────────────────
class _Product {
  final String Function(AppLocalizations l) nameGetter;
  final double rating;
  final int reviews;
  final double price;
  final String Function(AppLocalizations l) unitGetter;
  final String imagePath;
  final String tag;
  final bool isVerified;

  const _Product({
    required this.nameGetter,
    required this.rating,
    required this.reviews,
    required this.price,
    required this.unitGetter,
    required this.imagePath,
    required this.tag,
    required this.isVerified,
  });
}

final List<_Product> _allProducts = [
  _Product(
    nameGetter: (l) => l.premiumMedjool,
    rating: 4.8,
    reviews: 85,
    price: 110,
    unitGetter: (l) => l.isArabic ? 'لكل كغ' : 'per kg',
    imagePath: 'assets/images/medjool.png',
    tag: 'medjool',
    isVerified: true,
  ),
  _Product(
    nameGetter: (l) => l.ajwaAlMadinah,
    rating: 4.9,
    reviews: 120,
    price: 85,
    unitGetter: (l) => l.isArabic ? 'لكل كغ' : 'per kg',
    imagePath: 'assets/images/ajwa.png',
    tag: 'ajwa',
    isVerified: true,
  ),
  _Product(
    nameGetter: (l) => l.khalasAlAhsa,
    rating: 4.5,
    reviews: 67,
    price: 130,
    unitGetter: (l) => l.isArabic ? 'لكل ٣ كغ' : 'per 3 kg',
    imagePath: 'assets/images/khalas.png',
    tag: 'khalas',
    isVerified: false,
  ),
  _Product(
    nameGetter: (l) => l.sukkariMofatall,
    rating: 4.7,
    reviews: 42,
    price: 45,
    unitGetter: (l) => l.isArabic ? 'لكل كغ' : 'per kg',
    imagePath: 'assets/images/sukari.png',
    tag: 'sukkari',
    isVerified: true,
  ),
  _Product(
    nameGetter: (l) => l.barhiGolden,
    rating: 4.6,
    reviews: 33,
    price: 60,
    unitGetter: (l) => l.isArabic ? 'لكل كغ' : 'per kg',
    imagePath: 'assets/images/barhi.png',
    tag: 'barhi',
    isVerified: false,
  ),
  _Product(
    nameGetter: (l) => l.sagaiDates,
    rating: 4.4,
    reviews: 28,
    price: 55,
    unitGetter: (l) => l.isArabic ? 'لكل كغ' : 'per kg',
    imagePath: 'assets/images/sagai.png',
    tag: 'sagai',
    isVerified: false,
  ),
];

// ── Screen ───────────────────────────────────────────────────────────────────
class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final Set<int> _cart = {};
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _getFilters(AppLocalizations l) => [
    {'key': 'all', 'label': l.allVarieties},
    {'key': 'medjool', 'label': l.filterMedjool},
    {'key': 'ajwa', 'label': l.filterAjwa},
    {'key': 'sukkari', 'label': l.filterSukkari},
    {'key': 'khalas', 'label': l.filterKhalas},
  ];

  List<_Product> _filtered(AppLocalizations l) {
    return _allProducts.where((p) {
      final matchFilter = _selectedFilter == 'all' || p.tag == _selectedFilter;
      final matchSearch =
          _searchQuery.isEmpty ||
          p.nameGetter(l).toLowerCase().contains(_searchQuery.toLowerCase());
      return matchFilter && matchSearch;
    }).toList();
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
        backgroundColor: _kBg,
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
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kBrown.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: _kBrown,
                size: 22,
              ),
            ),
          ),
          Text(
            l.market,
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _kBrown,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kBrown.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.menu_rounded, color: _kBrown, size: 22),
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
          style: GoogleFonts.cairo(fontSize: 14, color: _kBrown),
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
                color: isActive ? _kChipActive : Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: isActive ? _kChipActive : const Color(0xFFE0D8CE),
                ),
              ),
              child: Text(
                f['label']!,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : _kBrown,
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
                      colors: [Color(0xFF3B1F13), Color(0xFF6B3A1E)],
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
                      color: _kGold.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l.isArabic ? 'عرض خاص' : 'Special Offer',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _kBrown,
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
              color: _kBrown,
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
                  backgroundColor: _kBrown700,
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
  final _Product product;
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
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _kBrown.withValues(alpha: 0.07),
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
                        color: const Color(0xFF1B6B3A),
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
                      color: _kBrown,
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
                          color: _kBrown,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.star_rounded, color: _kGold, size: 14),
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
                            color: inCart ? _kGold : _kBrown,
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
                              color: _kBrown,
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
