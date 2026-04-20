import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../theme/app_colors.dart';
import '../models/market_item.dart';
import '../repositories/item_repository.dart';
import 'item_detail_screen.dart';

class MarketScreen extends StatefulWidget {
  final ValueChanged<int>? onTabChange;
  const MarketScreen({super.key, this.onTabChange});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  String _selectedVariety = '';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  final _itemRepo = ItemRepository.instance;

  List<Map<String, String>> _getFilters(AppLocalizations l) => [
    {'key': '', 'label': l.allVarieties},
    {'key': 'ajwa', 'label': l.filterAjwa},
    {'key': 'medjool', 'label': l.filterMedjool},
    {'key': 'sukkari', 'label': l.filterSukkari},
    {'key': 'khalas', 'label': l.filterKhalas},
    {'key': 'barhi', 'label': l.filterBarhi},
    {'key': 'sagai', 'label': l.filterSagai},
  ];

  List<MarketItem> _applyFilters(List<MarketItem> items) {
    return items.where((item) {
      final matchVariety =
          _selectedVariety.isEmpty || item.variety == _selectedVariety;
      final q = _searchQuery.trim().toLowerCase();
      final matchSearch = q.isEmpty ||
          item.title.toLowerCase().contains(q) ||
          item.sellerName.toLowerCase().contains(q) ||
          item.variety.toLowerCase().contains(q);
      return matchVariety && matchSearch;
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
        backgroundColor: AppColors.screenBg,
        body: Column(
          children: [
            _MarketHeader(l: l, isAr: isAr),
            _buildSearchBar(isAr),
            _buildFilterChips(l),
            Expanded(
              child: StreamBuilder<List<MarketItem>>(
                stream: _itemRepo.watchActiveItems(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.brown700,
                      ),
                    );
                  }
                  final all = snap.data ?? [];
                  final items = _applyFilters(all);
                  return _buildGrid(items, isAr);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isAr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
            hintText: localeProvider.isArabic ? 'ابحث عن منتج...' : 'Search items...',
            hintStyle: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            prefixIcon: Icon(
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

  Widget _buildFilterChips(AppLocalizations l) {
    final filters = _getFilters(l);
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        itemCount: filters.length,
        itemBuilder: (context, i) {
          final f = filters[i];
          final isActive = _selectedVariety == f['key'];
          return GestureDetector(
            onTap: () => setState(() => _selectedVariety = f['key']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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

  Widget _buildGrid(List<MarketItem> items, bool isAr) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco_outlined, color: Colors.grey.shade300, size: 52),
            const SizedBox(height: 12),
            Text(
              isAr ? 'لا توجد منتجات متاحة' : 'No items available yet',
              style: GoogleFonts.cairo(
                color: Colors.grey.shade400,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isAr ? 'كن أول بائع!' : 'Be the first seller!',
              style: GoogleFonts.cairo(
                color: Colors.grey.shade400,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeroBanner(isAr)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.72,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ItemDetailScreen(item: items[i]),
                  ),
                ),
                child: _ItemCard(item: items[i], isAr: isAr),
              ),
              childCount: items.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner(bool isAr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [AppColors.brown900, Color(0xFF6B3A1E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/sukari.png',
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.45),
                colorBlendMode: BlendMode.darken,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
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
                        isAr ? 'السوق الطازج' : 'Fresh Market',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brown900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isAr ? 'أجود تمور المملكة' : 'Saudi Arabia\'s finest dates',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
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
}

// ── Market Header ──────────────────────────────────────────────────────────────

class _MarketHeader extends StatelessWidget {
  final AppLocalizations l;
  final bool isAr;

  const _MarketHeader({required this.l, required this.isAr});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.market,
            style: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isAr
                ? 'اكتشف أجود أصناف التمور من أفضل المزارع'
                : 'Discover premium dates from the finest farms',
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Item Card ──────────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  final MarketItem item;
  final bool isAr;

  const _ItemCard({required this.item, required this.isAr});

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
          // ── Image ──────────────────────────────────────────────────────
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _imageFallback(),
                    )
                  : _imageFallback(),
            ),
          ),
          // ── Info ───────────────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.brown900,
                    ),
                  ),
                  Text(
                    item.sellerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  // Price row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          item.priceLabel(isAr),
                          style: GoogleFonts.cairo(
                            fontSize: item.price != null ? 15 : 12,
                            fontWeight: FontWeight.w800,
                            color: item.price != null
                                ? AppColors.brown900
                                : AppColors.verifiedGreen,
                          ),
                        ),
                      ),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.brown900,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
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

  Widget _imageFallback() => Container(
        color: const Color(0xFF2A3A3A),
        child: const Center(
          child: Icon(Icons.eco_rounded, color: Colors.white38, size: 36),
        ),
      );
}
