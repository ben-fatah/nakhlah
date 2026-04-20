import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/market_item.dart';
import '../models/seller_profile.dart';
import '../providers/locale_provider.dart';
import '../repositories/item_repository.dart';
import '../theme/app_colors.dart';
import 'add_edit_item_screen.dart';

/// Lists all of the seller's own items and provides Add / Edit / Delete actions.
///
/// Accessible from [SellerDashboardScreen] → "My Items" tile.
class ItemsManagementScreen extends StatelessWidget {
  final SellerProfile seller;

  const ItemsManagementScreen({super.key, required this.seller});

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
            isAr ? 'منتجاتي' : 'My Items',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: isAr ? 'إضافة منتج' : 'Add item',
              onPressed: () => _openAddItem(context),
            ),
          ],
        ),
        body: StreamBuilder<List<MarketItem>>(
          stream: ItemRepository.instance.watchSellerItems(uid),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.brown700),
              );
            }

            final items = snap.data ?? [];

            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 56,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isAr ? 'لا توجد منتجات بعد' : 'No items yet',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _openAddItem(context),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(
                        isAr ? 'أضف أول منتج' : 'Add your first item',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brown700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, i) =>
                  _ItemTile(item: items[i], seller: seller, isAr: isAr),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openAddItem(context),
          backgroundColor: AppColors.brown700,
          foregroundColor: Colors.white,
          tooltip: isAr ? 'إضافة منتج' : 'Add item',
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  void _openAddItem(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditItemScreen(seller: seller),
      ),
    );
  }
}

// ── Item Tile ──────────────────────────────────────────────────────────────────

class _ItemTile extends StatelessWidget {
  final MarketItem item;
  final SellerProfile seller;
  final bool isAr;

  const _ItemTile({
    required this.item,
    required this.seller,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddEditItemScreen(item: item, seller: seller),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              // Image thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: item.imageUrl.isNotEmpty
                      ? Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _imgFallback(),
                        )
                      : _imgFallback(),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.brown900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.priceLabel(isAr),
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: item.price != null
                            ? AppColors.brown700
                            : AppColors.verifiedGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Active / inactive badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: item.isActive
                            ? AppColors.verifiedGreen.withValues(alpha: 0.12)
                            : Colors.grey.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.isActive
                            ? (isAr ? 'نشط' : 'Active')
                            : (isAr ? 'مخفي' : 'Hidden'),
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: item.isActive
                              ? AppColors.verifiedGreen
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.edit_outlined,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imgFallback() => Container(
        color: AppColors.brown100,
        child: const Center(
          child: Icon(Icons.eco_rounded, color: AppColors.brown700, size: 28),
        ),
      );
}
