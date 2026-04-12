import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../models/product_model.dart';
import '../models/seller_model.dart';
import '../providers/locale_provider.dart';
import '../repositories/product_repository.dart';
import '../repositories/seller_repository.dart';
import '../theme/app_colors.dart';
import 'product_detail_screen.dart';

/// Full seller profile page with a gradient header and 3-tab body.
///
/// Receives a fully-populated [Seller] object â€” no network calls happen here.
/// When Firestore is live, the caller simply passes a [Seller.fromFirestore].
///
/// Tabs:
///  â€¢ **About** â€” seller description and key stats
///  â€¢ **Products** â€” grid of date products this seller offers
///  â€¢ **Contact** â€” phone number and call CTA
class SellerScreen extends StatefulWidget {
  final Seller seller;
  const SellerScreen({super.key, required this.seller});

  @override
  State<SellerScreen> createState() => _SellerScreenState();
}

class _SellerScreenState extends State<SellerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Resolved once to avoid repeated repository lookups on every rebuild.
  late final List<Product> _sellerProducts;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _sellerProducts = SellerRepository()
        .getProductsForSeller(widget.seller, ProductRepository());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isAr = localeProvider.isArabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F0EB),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _SellerHeader(
              seller: widget.seller,
              l: l,
              tabController: _tabController,
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _AboutTab(seller: widget.seller, l: l),
              _ProductsTab(products: _sellerProducts, l: l),
              _ContactTab(seller: widget.seller, l: l),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Seller header (SliverAppBar + gradient + TabBar) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SellerHeader extends StatelessWidget {
  final Seller seller;
  final AppLocalizations l;
  final TabController tabController;

  const _SellerHeader({
    required this.seller,
    required this.l,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppColors.brown700,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: _SellerHeaderBackground(seller: seller, l: l),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: AppColors.brown700,
          child: TabBar(
            controller: tabController,
            indicatorColor: AppColors.gold,
            indicatorWeight: 3,
            labelColor: AppColors.gold,
            unselectedLabelColor: Colors.white60,
            labelStyle: GoogleFonts.cairo(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            unselectedLabelStyle: GoogleFonts.cairo(fontSize: 13),
            tabs: [
              Tab(text: l.aboutSeller),
              Tab(text: l.sellerProducts),
              Tab(text: l.contactSeller),
            ],
          ),
        ),
      ),
    );
  }
}

class _SellerHeaderBackground extends StatelessWidget {
  final Seller seller;
  final AppLocalizations l;

  const _SellerHeaderBackground({required this.seller, required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brown900, AppColors.brown700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // â”€â”€ Logo / avatar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.cardWhite.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: seller.logoPath.isNotEmpty
                    ? ClipOval(
                        child: Image.asset(
                          seller.logoPath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) =>
                              _LogoFallback(name: seller.name),
                        ),
                      )
                    : _LogoFallback(name: seller.name),
              ),
              const SizedBox(width: 16),

              // â”€â”€ Info â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Name + badge row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            seller.name,
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (seller.isTop) ...[
                          const SizedBox(width: 6),
                          _GoldBadge(label: l.topSeller),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Location
                    if (seller.location.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 13,
                              color: Colors.white.withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              seller.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),

                    // Rating row
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.gold, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          seller.rating.toStringAsFixed(1),
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${seller.reviews} ${l.reviewsLabel})',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
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
}

class _LogoFallback extends StatelessWidget {
  final String name;
  const _LogoFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.cairo(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

// â”€â”€ Tab 1: About â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AboutTab extends StatelessWidget {
  final Seller seller;
  final AppLocalizations l;
  const _AboutTab({required this.seller, required this.l});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Stats row
        Row(
          children: [
            _StatChip(
              icon: Icons.star_rounded,
              value: seller.rating.toStringAsFixed(1),
              label: l.reviewsLabel,
              color: AppColors.gold,
            ),
            const SizedBox(width: 12),
            _StatChip(
              icon: Icons.people_outline_rounded,
              value: seller.reviews,
              label: l.reviewsLabel,
              color: AppColors.brown700,
            ),
            const SizedBox(width: 12),
            _StatChip(
              icon: Icons.inventory_2_outlined,
              value: '${seller.productIds.length}',
              label: l.sellerProducts,
              color: AppColors.verifiedGreen,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Description
        if (seller.description.isNotEmpty) ...[
          Text(
            l.aboutSeller.toUpperCase(),
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade500,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              seller.description,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.7,
              ),
            ),
          ),
        ],

        // Verified badge
        if (seller.isTop) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.verified_rounded,
                  color: AppColors.verifiedGreen, size: 18),
              const SizedBox(width: 8),
              Text(
                l.verifiedSeller,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w700,
                  color: AppColors.verifiedGreen,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// â”€â”€ Tab 2: Products â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ProductsTab extends StatelessWidget {
  final List<Product> products;
  final AppLocalizations l;
  const _ProductsTab({required this.products, required this.l});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                color: Colors.grey.shade300, size: 48),
            const SizedBox(height: 12),
            Text(
              l.noProductsForSeller,
              style: GoogleFonts.cairo(
                  color: Colors.grey.shade400, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.88,
      ),
      itemCount: products.length,
      itemBuilder: (context, i) {
        final product = products[i];
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          ),
          child: _SellerProductCard(product: product, l: l),
        );
      },
    );
  }
}

class _SellerProductCard extends StatelessWidget {
  final Product product;
  final AppLocalizations l;
  const _SellerProductCard({required this.product, required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.brown900.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: product.imagePath.isNotEmpty
                  ? Image.asset(
                      product.imagePath,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        color: AppColors.brown100,
                        child: const Icon(Icons.eco_rounded,
                            color: AppColors.brown700, size: 36),
                      ),
                    )
                  : Container(
                      color: AppColors.brown100,
                      child: const Icon(Icons.eco_rounded,
                          color: AppColors.brown700, size: 36),
                    ),
            ),
          ),
          // Info
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product.nameGetter(l),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.brown900,
                    ),
                  ),
                  Text(
                    l.isArabic
                        ? 'Ø±.Ø³ ${product.price.toStringAsFixed(0)}'
                        : 'SAR ${product.price.toStringAsFixed(0)}',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.brown700,
                    ),
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

// â”€â”€ Tab 3: Contact â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ContactTab extends StatelessWidget {
  final Seller seller;
  final AppLocalizations l;
  const _ContactTab({required this.seller, required this.l});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Phone card
        if (seller.phoneNumber.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.brown100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.phone_outlined,
                      color: AppColors.brown700, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.callSeller,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        seller.phoneNumber,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brown900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Call button
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l.isArabic
                        ? 'Ø¬Ø§Ø±Ù ÙØªØ­ ØªØ·Ø¨ÙŠÙ‚ Ø§Ù„Ù‡Ø§ØªÙâ€¦'
                        : 'Opening diallerâ€¦',
                    style: GoogleFonts.cairo(color: Colors.white),
                  ),
                  backgroundColor: AppColors.brown700,
                  duration: const Duration(seconds: 1),
                ),
              ),
              icon:
                  const Icon(Icons.call_rounded, color: Colors.white, size: 20),
              label: Text(
                l.callSeller,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.verifiedGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
            ),
          ),
        ] else ...[
          // Fallback when no phone is available
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Column(
                children: [
                  Icon(Icons.phone_disabled_outlined,
                      color: Colors.grey.shade300, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    l.isArabic
                        ? 'Ù„Ø§ ØªØªÙˆÙØ± Ù…Ø¹Ù„ÙˆÙ…Ø§Øª ØªÙˆØ§ØµÙ„'
                        : 'No contact info available',
                    style: GoogleFonts.cairo(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// â”€â”€ Stat chip â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.brown900,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _GoldBadge extends StatelessWidget {
  final String label;
  const _GoldBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_rounded,
              color: AppColors.gold, size: 12),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.goldDark,
            ),
          ),
        ],
      ),
    );
  }
}
