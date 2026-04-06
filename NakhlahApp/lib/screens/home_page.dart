import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'manage_profile_screen.dart';
import 'scan_screen.dart';
import 'explore_screen.dart';
import 'market_screen.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';

//  Colour tokens matching the screenshot
const Color kBrown900 = Color(0xFF3B1F13); // dark header background
const Color kBrown700 = Color(0xFF5C3A1E); // buttons, accents
const Color kBrown100 = Color(0xFFF2EDE8); // page background
const Color kGoldBadge = Color(0xFFE8B84B); // match badge, TOP badge
const Color kCardBg = Color(0xFFEAE4DE); // scan card background

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  //  mock recent scans data
  final List<_ScanItem> _recentScans = const [
    _ScanItem(name: 'Ajwa', match: 98, imageAsset: 'assets/images/ajwa.png'),
    _ScanItem(
      name: 'Medjool',
      match: 92,
      imageAsset: 'assets/images/medjool.png',
    ),
    _ScanItem(
      name: 'Sukari',
      match: 85,
      imageAsset: 'assets/images/sukari.png',
    ),
  ];

  final List<_SellerItem> _sellers = const [
    _SellerItem(
      name: 'Al-Madina Farms',
      rating: 4.9,
      reviews: '1.2k',
      isTop: true,
    ),
    _SellerItem(name: 'Royal Oasis', rating: 4.8, reviews: '850', isTop: true),
  ];

  String get _firstName {
    final name =
        FirebaseAuth.instance.currentUser?.displayName ??
        FirebaseAuth.instance.currentUser?.email ??
        'User';
    return name.split(' ').first.split('@').first;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: kBrown100,
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        homeLabel: l10n.home,
        exploreLabel: l10n.explore,
        scanLabel: l10n.scan,
        marketLabel: l10n.market,
        profileLabel: l10n.profile,
        onTap: (i) {
          if (i == 1) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ExploreScreen()));
            return;
          }
          if (i == 2) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ScanScreen()));
            return;
          }
          if (i == 3) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MarketScreen()));
            return;
          }
          if (i == 4) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ManageProfileScreen()),
            );
            return;
          }
          setState(() => _selectedIndex = i);
        },
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          child: Builder(
            builder: (context) {
              final l = AppLocalizations.of(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //  Dark header
                  _Header(
                    firstName: _firstName,
                    onNotification: () {},
                    onLanguage: () => localeProvider.toggleLocale(),
                  ),

                  //  Scan card
                  _ScanCard(
                    label: l.scanDates,
                    subtitle: l.identifyInSeconds,
                    buttonLabel: l.scanNow,
                    onScan: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ScanScreen()),
                    ),
                  ),

                  const SizedBox(height: 28),

                  //  Quick actions row
                  _QuickActions(
                    scanLabel: l.scan,
                    exploreLabel: l.explore,
                    marketLabel: l.market,
                    historyLabel: l.history,
                    onScan: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ScanScreen()),
                    ),
                    onExplore: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ExploreScreen()),
                    ),
                    onMarket: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MarketScreen()),
                    ),
                    onProfile: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ManageProfileScreen(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  //  Recent scans
                  _SectionHeader(
                    title: l.recentScans,
                    actionLabel: l.viewAll,
                    onAction: () {},
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 190,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _recentScans.length,
                      itemBuilder: (context, i) =>
                          _ScanCard2(item: _recentScans[i]),
                    ),
                  ),

                  const SizedBox(height: 28),

                  //  Featured sellers
                  _SectionHeader(
                    title: l.featuredSellers,
                    actionLabel: l.exploreAll,
                    onAction: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MarketScreen()),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _sellers.length,
                      itemBuilder: (context, i) =>
                          _SellerCard(item: _sellers[i]),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

//
//  Header
//

class _Header extends StatelessWidget {
  final String firstName;
  final VoidCallback onNotification;
  final VoidCallback onLanguage;

  const _Header({
    required this.firstName,
    required this.onNotification,
    required this.onLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBrown900,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // icons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.language_rounded,
                  color: Colors.white70,
                  size: 22,
                ),
                onPressed: onLanguage,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: onNotification,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

//
//  Scan Card (Main Card)
//

class _ScanCard extends StatelessWidget {
  final VoidCallback onScan;
  final String label;
  final String subtitle;
  final String buttonLabel;

  const _ScanCard({
    required this.onScan,
    required this.label,
    required this.subtitle,
    required this.buttonLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: kBrown900.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kBrown900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: onScan,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: kBrown700,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.filter_center_focus_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          buttonLabel,
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Camera icon placeholder
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.camera_alt_rounded,
              color: Colors.grey.shade400,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }
}

//
//  Quick Actions
//

class _QuickActions extends StatelessWidget {
  final VoidCallback onScan;
  final VoidCallback onExplore;
  final VoidCallback onMarket;
  final VoidCallback onProfile;
  final String scanLabel;
  final String exploreLabel;
  final String marketLabel;
  final String historyLabel;

  const _QuickActions({
    required this.onScan,
    required this.onExplore,
    required this.onMarket,
    required this.onProfile,
    required this.scanLabel,
    required this.exploreLabel,
    required this.marketLabel,
    required this.historyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.qr_code_scanner_rounded,
        label: scanLabel,
        onTap: onScan,
      ),
      _QuickAction(
        icon: Icons.explore_outlined,
        label: exploreLabel,
        onTap: onExplore,
      ),
      _QuickAction(
        icon: Icons.storefront_outlined,
        label: marketLabel,
        onTap: onMarket,
      ),
      _QuickAction(
        icon: Icons.history_rounded,
        label: historyLabel,
        onTap: () {},
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: actions.map((a) => _QuickActionTile(action: a)).toList(),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: kBrown900.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(action.icon, color: kBrown900, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            action.label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kBrown900,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

//
//  Section Header
//

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: kBrown900,
            ),
          ),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade500,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel,
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
}

//
//  Recent Scan Card
//

class _ScanCard2 extends StatelessWidget {
  final _ScanItem item;
  const _ScanCard2({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kBrown900.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.asset(
              item.imageAsset,
              height: 110,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 110,
                color: const Color(0xFF2A3A3A),
                child: const Icon(
                  Icons.eco_rounded,
                  color: Colors.white54,
                  size: 40,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: kBrown900,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: kGoldBadge.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${item.match}% Match',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8B6914),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanItem {
  final String name;
  final int match;
  final String imageAsset;
  const _ScanItem({
    required this.name,
    required this.match,
    required this.imageAsset,
  });
}

//
//  Seller Card
//

class _SellerCard extends StatelessWidget {
  final _SellerItem item;
  const _SellerCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kBrown900.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: kBrown100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: kBrown700,
                  size: 22,
                ),
              ),
              const Spacer(),
              if (item.isTop)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kGoldBadge.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, color: kGoldBadge, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        'TOP',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF8B6914),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.name,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: kBrown900,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: kGoldBadge, size: 15),
              const SizedBox(width: 3),
              Text(
                '${item.rating} (${item.reviews})',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SellerItem {
  final String name;
  final double rating;
  final String reviews;
  final bool isTop;
  const _SellerItem({
    required this.name,
    required this.rating,
    required this.reviews,
    required this.isTop,
  });
}

//
//  Bottom Navigation Bar
//

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final String homeLabel;
  final String exploreLabel;
  final String scanLabel;
  final String marketLabel;
  final String profileLabel;

  const _BottomNav({
    required this.selectedIndex,
    required this.onTap,
    required this.homeLabel,
    required this.exploreLabel,
    required this.scanLabel,
    required this.marketLabel,
    required this.profileLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: kBrown900.withValues(alpha: 0.08),
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
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: homeLabel,
                index: 0,
                selected: selectedIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.explore_outlined,
                label: exploreLabel,
                index: 1,
                selected: selectedIndex,
                onTap: onTap,
              ),

              // Centre FAB
              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: kBrown900,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: kBrown900.withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.filter_center_focus_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        scanLabel,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              _NavItem(
                icon: Icons.shopping_bag_outlined,
                label: marketLabel,
                index: 3,
                selected: selectedIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: profileLabel,
                index: 4,
                selected: selectedIndex,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int selected;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selected;
    final color = isSelected ? kBrown700 : Colors.grey.shade400;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
