import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../domain/favorites_notifier.dart';
import '../l10n/app_localizations.dart';
import '../models/product_model.dart';
import '../models/seller_model.dart';
import '../providers/locale_provider.dart';
import '../repositories/seller_repository.dart';
import '../theme/app_colors.dart';
import 'seller_screen.dart';

/// Full-page view for a single date product.
///
/// Displays the hero image, name, rating, price, bilingual description,
/// a list of sellers carrying this product, and an Add-to-Cart CTA.
/// Favorites are toggled via the heart icon in the app bar and persisted
/// through [favoritesNotifier].
///
/// Navigation into this screen:
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
/// );
/// ```
class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _toggleFavorite(BuildContext context, AppLocalizations l) {
    final wasFav = favoritesNotifier.isFavorite(product.id);
    favoritesNotifier.toggle(product.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasFav ? l.removedFromFavorites : l.addedToFavorites,
          style: GoogleFonts.cairo(color: Colors.white),
        ),
        backgroundColor:
            wasFav ? AppColors.brown700 : AppColors.verifiedGreen,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _goToSeller(BuildContext context, Seller seller) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SellerScreen(seller: seller)),
    );
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isAr = localeProvider.isArabic;
    final theme = Theme.of(context);

    // Resolve sellers for this product once.
    final sellers = SellerRepository().getSellersByProduct(product.id);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF9F6),
        // â”€â”€ Custom SliverAppBar with transparent overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        body: CustomScrollView(
          slivers: [
            _HeroAppBar(product: product, l: l, onToggleFavorite: _toggleFavorite),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // â”€â”€ Name & verified badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.nameGetter(l),
                            style: GoogleFonts.cairo(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppColors.brown900,
                              height: 1.15,
                            ),
                          ),
                        ),
                        if (product.isVerified) ...[
                          const SizedBox(width: 8),
                          _VerifiedBadge(label: l.verifiedSeller),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),

                    // â”€â”€ Rating & price row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.gold,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.brown900,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${product.reviews} ${l.reviewsLabel})',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const Spacer(),
                        // Price chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brown900,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            l.isArabic
                                ? 'Ø±.Ø³ ${product.price.toStringAsFixed(0)} / ${product.unitGetter(l)}'
                                : 'SAR ${product.price.toStringAsFixed(0)} / ${product.unitGetter(l)}',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // â”€â”€ Description â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    _SectionTitle(title: l.description, theme: theme),
                    const SizedBox(height: 10),
                    Text(
                      product.descriptionGetter(l),
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // â”€â”€ Sellers section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Row(
                      children: [
                        _SectionTitle(title: l.sellers, theme: theme),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brown100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${sellers.length}',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brown700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    sellers.isEmpty
                        ? _EmptySellerState(label: l.noSellersFound)
                        : _SellerList(
                            sellers: sellers,
                            l: l,
                            onTap: (s) => _goToSeller(context, s),
                          ),
                    const SizedBox(height: 100), // breathing room above FAB
                  ],
                ),
              ),
            ),
          ],
        ),

        // â”€â”€ Sticky bottom CTA â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        bottomNavigationBar: _BottomCta(
          label: l.addToCart,
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l.isArabic ? 'ØªÙ…Øª Ø§Ù„Ø¥Ø¶Ø§ÙØ© Ø¥Ù„Ù‰ Ø§Ù„Ø³Ù„Ø© âœ“' : 'Added to cart âœ“',
                style: GoogleFonts.cairo(color: Colors.white),
              ),
              backgroundColor: AppColors.brown700,
              duration: const Duration(seconds: 1),
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Hero SliverAppBar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _HeroAppBar extends StatelessWidget {
  final Product product;
  final AppLocalizations l;
  final void Function(BuildContext, AppLocalizations) onToggleFavorite;

  const _HeroAppBar({
    required this.product,
    required this.l,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.brown900,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        // Reactive favorite button â€” rebuilds only the icon
        ValueListenableBuilder<Set<String>>(
          valueListenable: favoritesNotifier,
          builder: (context, favorites, child) {
            final isFav = favorites.contains(product.id);
            return IconButton(
              icon: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? Colors.red.shade300 : Colors.white,
              ),
              tooltip: isFav ? l.removedFromFavorites : l.addedToFavorites,
              onPressed: () => onToggleFavorite(context, l),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Product image
            product.imagePath.isNotEmpty
                ? Image.asset(
                    product.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => _imageFallback(),
                  )
                : _imageFallback(),
            // Gradient scrim so the title stays readable when pinned
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xCC3B1F13)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() => Container(
        color: AppColors.brown900,
        child: const Icon(Icons.eco_rounded, color: Colors.white24, size: 80),
      );
}

// â”€â”€ Seller list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SellerList extends StatelessWidget {
  final List<Seller> sellers;
  final AppLocalizations l;
  final ValueChanged<Seller> onTap;

  const _SellerList({
    required this.sellers,
    required this.l,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: sellers.map((s) => _SellerRow(seller: s, l: l, onTap: onTap)).toList(),
    );
  }
}

class _SellerRow extends StatelessWidget {
  final Seller seller;
  final AppLocalizations l;
  final ValueChanged<Seller> onTap;

  const _SellerRow({required this.seller, required this.l, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(seller),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.brown900.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // â”€â”€ Logo / avatar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.brown100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.store_rounded,
                color: AppColors.brown700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // â”€â”€ Info â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          seller.name,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.brown900,
                          ),
                        ),
                      ),
                      if (seller.isTop) _TopBadge(label: l.topSeller),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (seller.location.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            seller.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.gold, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        '${seller.rating.toStringAsFixed(1)} '
                        '(${seller.reviews} ${l.reviewsLabel})',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // â”€â”€ Chevron â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.brown700,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Small reusable widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SectionTitle extends StatelessWidget {
  final String title;
  final ThemeData theme;
  const _SectionTitle({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.cairo(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Colors.grey.shade500,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  final String label;
  const _VerifiedBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.verifiedGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded,
              size: 13, color: AppColors.verifiedGreen),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.verifiedGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBadge extends StatelessWidget {
  final String label;
  const _TopBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.goldDark,
        ),
      ),
    );
  }
}

class _EmptySellerState extends StatelessWidget {
  final String label;
  const _EmptySellerState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.store_outlined, color: Colors.grey.shade300, size: 40),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomCta extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _BottomCta({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.add_shopping_cart_rounded,
                color: Colors.white, size: 20),
            label: Text(
              label,
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brown700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 3,
            ),
          ),
        ),
      ),
    );
  }
}
