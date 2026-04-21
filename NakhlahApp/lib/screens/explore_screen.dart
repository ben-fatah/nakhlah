import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../models/date_model.dart';
import '../repositories/date_repository.dart';
import '../repositories/product_repository.dart';
import 'product_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  bool _isGrid = true;

  final _searchCtrl = TextEditingController();
  final _dateRepo = DateRepository();

  List<Map<String, dynamic>> _getFilters(AppLocalizations l) => [
        {'key': 'all', 'label': l.allVarieties},
        {'key': 'ajwa', 'label': l.filterAjwa},
        {'key': 'allig', 'label': l.filterAllig},
        {'key': 'amber', 'label': l.filterAmber},
        {'key': 'aseel', 'label': l.filterAseel},
        {'key': 'deglet_nour', 'label': l.filterDegletNour},
        {'key': 'galaxy', 'label': l.filterGalaxy},
        {'key': 'kalmi', 'label': l.filterKalmi},
        {'key': 'khorma', 'label': l.filterKhorma},
        {'key': 'medjool', 'label': l.filterMedjool},
        {'key': 'meneifi', 'label': l.filterMeneifi},
        {'key': 'muzafati', 'label': l.filterMuzafati},
        {'key': 'nabtat_ali', 'label': l.filterNabtatAli},
        {'key': 'rutab', 'label': l.filterRutab},
        {'key': 'shaishe', 'label': l.filterShaishe},
        {'key': 'sokari', 'label': l.filterSokari},
        {'key': 'sugaey', 'label': l.filterSugaey},
        {'key': 'zahidi', 'label': l.filterZahidi},
      ];

  List<DateVariety> _filtered(AppLocalizations l) =>
      _dateRepo.getFiltered(l, tag: _selectedFilter, searchQuery: _searchQuery);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openDetail(BuildContext context, DateVariety variety, AppLocalizations l) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(variety: variety, l: l),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ExploreHeader(
            l: l,
            isGrid: _isGrid,
            onToggle: () => setState(() => _isGrid = !_isGrid),
          ),
          _buildSearchBar(l),
          _buildFilterChips(l),
          Expanded(child: _buildGrid(l)),
        ],
      ),
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEDE8E0),
          borderRadius: BorderRadius.circular(50),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: GoogleFonts.cairo(fontSize: 14, color: AppColors.brown900),
          decoration: InputDecoration(
            hintText: l.searchHint,
            hintStyle: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade500),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500, size: 22),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  // ── Filter Chips ───────────────────────────────────────────────────────────
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
          final isActive = _selectedFilter == f['key'];
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f['key']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.chipActive : Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: isActive ? AppColors.chipActive : const Color(0xFFE0D8CE),
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

  // ── Grid / List ────────────────────────────────────────────────────────────
  Widget _buildGrid(AppLocalizations l) {
    final items = _filtered(l);
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco_outlined, color: Colors.grey.shade300, size: 52),
            const SizedBox(height: 12),
            Text(
              l.noVarietiesFound,
              style: GoogleFonts.cairo(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _isGrid ? 2 : 1,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: _isGrid ? 0.62 : 3.4,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _isGrid
          ? _GridCard(
              variety: items[i],
              l: l,
              onTap: () => _openDetail(context, items[i], l),
            )
          : _ListCard(
              variety: items[i],
              l: l,
              onTap: () => _openDetail(context, items[i], l),
            ),
    );
  }
}

// ── Gradient Header ────────────────────────────────────────────────────────────
class _ExploreHeader extends StatelessWidget {
  final AppLocalizations l;
  final bool isGrid;
  final VoidCallback onToggle;
  const _ExploreHeader({required this.l, required this.isGrid, required this.onToggle});

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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.exploreDates,
                  style: GoogleFonts.cairo(
                    fontSize: 28, fontWeight: FontWeight.w900,
                    color: Colors.white, height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.isArabic
                      ? 'اكتشف أجود 17 صنفاً من التمور مع قيمها الغذائية الكاملة'
                      : 'Discover all 17 varieties with full nutritional data',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                color: Colors.white, size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Compact Nutrition Strip (4 stats in a row) ─────────────────────────────────
class _NutritionStrip extends StatelessWidget {
  final DateVariety variety;
  final AppLocalizations l;
  const _NutritionStrip({required this.variety, required this.l});

  @override
  Widget build(BuildContext context) {
    final stats = [
      {'val': '${variety.kcal}', 'unit': 'kcal', 'label': l.caloriesLabel},
      {'val': '${variety.carbs}', 'unit': 'g', 'label': l.carbsLabel},
      {'val': '${variety.fiber}', 'unit': 'g', 'label': l.fiberLabel},
      {'val': '${variety.potassium}', 'unit': 'mg', 'label': 'K⁺'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F2EE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: stats.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          return Expanded(
            child: Container(
              decoration: i < stats.length - 1
                  ? const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Color(0xFFE0D8CE), width: 0.5),
                      ),
                    )
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            s['val']!,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brown900,
                            ),
                          ),
                          const SizedBox(width: 1),
                          Text(
                            s['unit']!,
                            style: const TextStyle(fontSize: 8, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        s['label']!,
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Grid Card ──────────────────────────────────────────────────────────────────
class _GridCard extends StatelessWidget {
  final DateVariety variety;
  final AppLocalizations l;
  final VoidCallback onTap;
  const _GridCard({required this.variety, required this.l, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.brown900.withValues(alpha: 0.07),
              blurRadius: 12, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ────────────────────────────────────────────────────
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      variety.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => Container(
                        color: const Color(0xFF2A3A3A),
                        child: const Icon(Icons.eco_rounded, color: Colors.white54, size: 40),
                      ),
                    ),
                    // Gradient overlay
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withValues(alpha: 0.45), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    // Price badge bottom-left
                    Positioned(
                      bottom: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'SAR ${variety.price.toStringAsFixed(0)}',
                          style: GoogleFonts.cairo(
                            fontSize: 10, fontWeight: FontWeight.w800,
                            color: AppColors.brown900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Info ─────────────────────────────────────────────────────
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Name + origin
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          variety.nameGetter(l),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w700, fontSize: 13,
                            color: AppColors.brown900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 11, color: Colors.grey),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                variety.originGetter(l),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey.shade500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        // Description
                        Text(
                          variety.descriptionGetter(l),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 9.5, color: Colors.grey.shade600, height: 1.4,
                          ),
                        ),
                      ],
                    ),
                    // Nutrition strip
                    _NutritionStrip(variety: variety, l: l),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── List Card ──────────────────────────────────────────────────────────────────
class _ListCard extends StatelessWidget {
  final DateVariety variety;
  final AppLocalizations l;
  final VoidCallback onTap;
  const _ListCard({required this.variety, required this.l, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.brown900.withValues(alpha: 0.06),
              blurRadius: 10, offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Thumbnail ────────────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: Image.asset(
                variety.imagePath,
                width: 110,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => Container(
                  width: 110,
                  color: const Color(0xFF2A3A3A),
                  child: const Icon(Icons.eco_rounded, color: Colors.white54, size: 36),
                ),
              ),
            ),
            // ── Details ──────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Name + price row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            variety.nameGetter(l),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w700, fontSize: 13.5,
                              color: AppColors.brown900,
                            ),
                          ),
                        ),
                        Text(
                          'SAR ${variety.price.toStringAsFixed(0)}',
                          style: GoogleFonts.cairo(
                            fontSize: 13, fontWeight: FontWeight.w800,
                            color: AppColors.brown900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Origin
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            variety.originGetter(l),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(fontSize: 10.5, color: Colors.grey.shade500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Nutrition strip
                    _NutritionStrip(variety: variety, l: l),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Full-detail bottom sheet (scan-result style) ───────────────────────────────
class _DetailSheet extends StatelessWidget {
  final DateVariety variety;
  final AppLocalizations l;
  const _DetailSheet({required this.variety, required this.l});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFBF9F6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // ── Hero image ─────────────────────────────────────
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        variety.imagePath,
                        height: 260,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, s) => Container(
                          height: 260,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              colors: [AppColors.brown900, AppColors.brown700],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.eco_rounded, color: Colors.white38, size: 72),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // ── Name ────────────────────────────────────────────
                    Text(
                      variety.nameGetter(l),
                      style: GoogleFonts.cairo(
                        fontSize: 28, fontWeight: FontWeight.w900,
                        color: AppColors.brown700, height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // ── Origin row ──────────────────────────────────────
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppColors.brown700, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          variety.originGetter(l),
                          style: GoogleFonts.cairo(
                            fontSize: 14, color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // ── Description ─────────────────────────────────────
                    Text(
                      variety.descriptionGetter(l),
                      style: GoogleFonts.cairo(
                        fontSize: 14, color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // ── Nutrition header ────────────────────────────────
                    Text(
                      l.nutritionPer100g,
                      style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold,
                        color: Colors.grey, letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ── 2×2 nutrition grid ──────────────────────────────
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 2.2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        _NutrientTile(
                          label: l.caloriesLabel,
                          value: '${variety.kcal}',
                          unit: 'kcal',
                        ),
                        _NutrientTile(
                          label: l.carbsLabel,
                          value: '${variety.carbs}',
                          unit: 'g',
                        ),
                        _NutrientTile(
                          label: l.fiberLabel,
                          value: '${variety.fiber}',
                          unit: 'g',
                        ),
                        _NutrientTile(
                          label: l.potassiumLabel,
                          value: '${variety.potassium}',
                          unit: 'mg',
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    // ── Price + action button ────────────────────────────
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.isArabic ? 'السعر لكل كيلو' : 'Price per kg',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            Text(
                              'SAR ${variety.price.toStringAsFixed(2)}',
                              style: GoogleFonts.cairo(
                                fontSize: 22, fontWeight: FontWeight.w900,
                                color: AppColors.brown900,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              final product = ProductRepository().getById(variety.tag);
                              if (product != null) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(product: product),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.shopping_bag_outlined,
                                color: Colors.white, size: 18),
                            label: Text(
                              l.isArabic ? 'ابحث عن بائعين' : 'Find Sellers',
                              style: GoogleFonts.cairo(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brown700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Nutrient tile (matches scan result style exactly) ─────────────────────────
class _NutrientTile extends StatelessWidget {
  final String label, value, unit;
  const _NutrientTile({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F2EE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10, color: Colors.grey,
              fontWeight: FontWeight.bold, letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: AppColors.brown900,
                ),
              ),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
