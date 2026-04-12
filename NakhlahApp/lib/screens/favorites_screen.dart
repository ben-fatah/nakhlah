import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../domain/favorites_notifier.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../theme/app_colors.dart';
import '../repositories/product_repository.dart';
import 'product_detail_screen.dart';
import '../models/product_model.dart';


class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isAr = localeProvider.isArabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2EDE8),
        appBar: AppBar(
          backgroundColor: AppColors.brown900,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              isAr
                  ? Icons.arrow_forward_ios_rounded
                  : Icons.arrow_back_ios_rounded,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            l.savedFavorites,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ValueListenableBuilder<Set<String>>(
            valueListenable: favoritesNotifier,
            builder: (context, favorites, _) {
              if (favorites.isEmpty) {
                return _EmptyFavorites(l: l);
              }

              final products = ProductRepository().getByIds(favorites.toList());

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: products.length,
                separatorBuilder: (context, separatorIndex) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _FavoriteCard(product: product, l: l);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  final AppLocalizations l;
  const _EmptyFavorites({required this.l});

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
                Icons.favorite_border_rounded,
                size: 52,
                color: AppColors.brown700,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              l.savedFavorites, // title reusing
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.brown900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l.isArabic
                  ? 'لم تقم بإضافة أي منتجات إلى المفضلة بعد. استكشف المنتجات وأضف ما يعجبك هنا!'
                  : 'You haven\'t added any products to your favorites yet. Explore and save them here!',
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
                  Icons.explore_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                label: Text(
                  l.exploreDates,
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

class _FavoriteCard extends StatelessWidget {
  final Product product;
  final AppLocalizations l;

  const _FavoriteCard({required this.product, required this.l});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.brown900.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                product.imagePath,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 70,
                  height: 70,
                  color: AppColors.brown100,
                  child: const Icon(Icons.eco_rounded, color: AppColors.brown700),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nameGetter(l),
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brown900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.gold, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brown700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.favorite_rounded, color: Colors.red),
              onPressed: () {
                favoritesNotifier.toggle(product.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l.removedFromFavorites,
                      style: GoogleFonts.cairo(color: Colors.white),
                    ),
                    backgroundColor: AppColors.brown700,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
