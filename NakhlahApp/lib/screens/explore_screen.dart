import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import 'scan_screen.dart';
import 'market_screen.dart';
import 'manage_profile_screen.dart';

const Color _kBg = Color(0xFFF5F0EB);
const Color _kBrown = Color(0xFF3B1F13);
const Color _kBrown700 = Color(0xFF5C3A1E);
const Color _kGold = Color(0xFFE8B84B);
const Color _kCard = Color(0xFFFFFFFF);
const Color _kChipActive = Color(0xFF3B1F13);

// ── Data model ───────────────────────────────────────────────────────────────
class _DateVariety {
  final String name;
  final String origin;
  final int kcal;
  final double price;
  final String imagePath;
  final String tag; // matches filter chip key

  const _DateVariety({
    required this.name,
    required this.origin,
    required this.kcal,
    required this.price,
    required this.imagePath,
    required this.tag,
  });
}

const List<_DateVariety> _allVarieties = [
  _DateVariety(
    name: 'Ajwa Al-Madinah',
    origin: 'Madinah, KSA',
    kcal: 280,
    price: 24.00,
    imagePath: 'assets/images/ajwa.png',
    tag: 'ajwa',
  ),
  _DateVariety(
    name: 'Premium Medjool',
    origin: 'Jericho, Palestine',
    kcal: 277,
    price: 18.50,
    imagePath: 'assets/images/medjool.png',
    tag: 'medjool',
  ),
  _DateVariety(
    name: 'Sukkari Mofatall',
    origin: 'Al-Qassim, KSA',
    kcal: 320,
    price: 15.00,
    imagePath: 'assets/images/sukari.png',
    tag: 'sukkari',
  ),
  _DateVariety(
    name: 'Khalas Al-Ahsa',
    origin: 'Al-Ahsa, KSA',
    kcal: 300,
    price: 12.90,
    imagePath: 'assets/images/khalas.png',
    tag: 'khalas',
  ),
  _DateVariety(
    name: 'Barhi Golden',
    origin: 'Al-Qassim, KSA',
    kcal: 265,
    price: 20.00,
    imagePath: 'assets/images/barhi.png',
    tag: 'barhi',
  ),
  _DateVariety(
    name: 'Sagai Dates',
    origin: 'Riyadh, KSA',
    kcal: 290,
    price: 14.50,
    imagePath: 'assets/images/sagai.png',
    tag: 'sagai',
  ),
];

// ── Screen ───────────────────────────────────────────────────────────────────
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  bool _isGrid = true;
  int _navIndex = 1;

  final _searchCtrl = TextEditingController();

  final List<Map<String, String>> _filters = const [
    {'key': 'all', 'label': 'All Varieties'},
    {'key': 'ajwa', 'label': 'Ajwa'},
    {'key': 'medjool', 'label': 'Medjool'},
    {'key': 'sukkari', 'label': 'Sukkari'},
    {'key': 'khalas', 'label': 'Khalas'},
  ];

  List<_DateVariety> get _filtered {
    return _allVarieties.where((v) {
      final matchFilter = _selectedFilter == 'all' || v.tag == _selectedFilter;
      final matchSearch =
          _searchQuery.isEmpty ||
          v.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.origin.toLowerCase().contains(_searchQuery.toLowerCase());
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
    return Scaffold(
      backgroundColor: _kBg,
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        bottom: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(child: _buildGrid()),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Explore Dates',
            style: GoogleFonts.cairo(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: _kBrown,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _isGrid = !_isGrid),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kBrown.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _isGrid ? Icons.grid_view_rounded : Icons.view_list_rounded,
                color: _kBrown,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEDE8E0),
          borderRadius: BorderRadius.circular(50),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: GoogleFonts.cairo(fontSize: 14, color: _kBrown),
          decoration: InputDecoration(
            hintText: 'Search variety, origin or flavor...',
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
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ── Filter Chips ───────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        itemBuilder: (context, i) {
          final f = _filters[i];
          final isActive = _selectedFilter == f['key'];
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f['key']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
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

  // ── Grid ───────────────────────────────────────────────────────────────────
  Widget _buildGrid() {
    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No varieties found',
          style: GoogleFonts.cairo(color: Colors.grey.shade500, fontSize: 15),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _isGrid ? 2 : 1,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: _isGrid ? 0.72 : 2.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) =>
          _isGrid ? _GridCard(variety: items[i]) : _ListCard(variety: items[i]),
    );
  }

  // ── Bottom Nav ─────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.explore_outlined, 'label': 'Explore'},
      {'icon': Icons.filter_center_focus_rounded, 'label': 'Scan'},
      {'icon': Icons.shopping_bag_outlined, 'label': 'Market'},
      {'icon': Icons.person_outline_rounded, 'label': 'Profile'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _kBrown.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final isCenter = i == 2;
              final isSelected = i == _navIndex;
              final color = isSelected ? _kBrown700 : Colors.grey.shade400;

              if (isCenter) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const ScanScreen()),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: _kBrown,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _kBrown.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.filter_center_focus_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (i == 0) {
                      Navigator.of(context).pop();
                    } else if (i == 3) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const MarketScreen()),
                      );
                    } else if (i == 4) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ManageProfileScreen(),
                        ),
                      );
                    } else {
                      setState(() => _navIndex = i);
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[i]['icon'] as IconData,
                        color: color,
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[i]['label'] as String,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Grid Card ─────────────────────────────────────────────────────────────────
class _GridCard extends StatelessWidget {
  final _DateVariety variety;
  const _GridCard({required this.variety});

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
          // Image
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Image.asset(
                variety.imagePath,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF2A3A3A),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: Colors.white54,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          // Info
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    variety.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _kBrown,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          variety.origin,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _kGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${variety.kcal} kcal',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8B6914),
                          ),
                        ),
                      ),
                      Text(
                        '\$${variety.price.toStringAsFixed(2)}',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _kBrown,
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
}

// ── List Card ─────────────────────────────────────────────────────────────────
class _ListCard extends StatelessWidget {
  final _DateVariety variety;
  const _ListCard({required this.variety});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _kBrown.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
            ),
            child: Image.asset(
              variety.imagePath,
              width: 100,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 100,
                color: const Color(0xFF2A3A3A),
                child: const Icon(
                  Icons.eco_rounded,
                  color: Colors.white54,
                  size: 36,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    variety.name,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: _kBrown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        variety.origin,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _kGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${variety.kcal} kcal',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8B6914),
                          ),
                        ),
                      ),
                      Text(
                        '\$${variety.price.toStringAsFixed(2)}',
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _kBrown,
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
}
