import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'manage_profile_screen.dart';
import 'scan_screen.dart';
import 'scan_result_screen.dart';
import 'explore_screen.dart';
import 'history_screen.dart';
import 'market_screen.dart' as market;
import 'notifications_panel.dart';
import 'seller_screen.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../repositories/user_repository.dart';
import '../repositories/seller_repository.dart';
import '../domain/scan_history_notifier.dart';
import '../models/scan_result.dart';
import '../models/seller_model.dart';
import '../models/user_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const Map<int, int> _navToStackIndex = {0: 0, 1: 1, 3: 2, 4: 3};

  late final List<Widget> _stackScreens;

  @override
  void initState() {
    super.initState();
    _stackScreens = [
      const _HomeContent(),
      const ExploreScreen(),
      market.MarketScreen(onTabChange: _onNavTap),
      const ManageProfileScreen(),
    ];
  }

  void _onNavTap(int navIndex) {
    if (navIndex == 2) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ScanScreen()));
      return;
    }
    final stackIdx = _navToStackIndex[navIndex];
    if (stackIdx != null) setState(() => _selectedIndex = navIndex);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stackIndex = _navToStackIndex[_selectedIndex] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.brown100,
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: _selectedIndex,
        homeLabel: l10n.home,
        exploreLabel: l10n.explore,
        marketLabel: l10n.market,
        profileLabel: l10n.profile,
        onTap: _onNavTap,
      ),
      body: IndexedStack(index: stackIndex, children: _stackScreens),
    );
  }
}

// ── Home Tab Content ───────────────────────────────────────────────────────────
class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _userRepo = UserRepository();
  final _sellerRepo = SellerRepository();

  late final List<Seller> _sellers;
  String _firstName = '';
  StreamSubscription<AppUser?>? _userSub;

  @override
  void initState() {
    super.initState();
    _sellers = _sellerRepo.getFeatured();
    _subscribeToUser();
  }

  void _subscribeToUser() {
    _userSub = _userRepo.watchCurrentUser().listen((appUser) {
      if (!mounted) return;
      String name = '';

      final fullName = appUser?.fullName.trim() ?? '';
      if (fullName.isNotEmpty) name = fullName.split(' ').first;

      if (name.isEmpty) {
        final displayName =
            FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
        if (displayName.isNotEmpty) name = displayName.split(' ').first;
      }

      if (name.isEmpty) {
        final email =
            appUser?.email.trim() ??
            FirebaseAuth.instance.currentUser?.email ??
            '';
        if (email.isNotEmpty) name = email.split('@').first;
      }

      setState(() => _firstName = name);
    });
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context);

    return SafeArea(
      top: false,
      bottom: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              firstName: _firstName,
              l: l,
              onNotification: () => NotificationsPanel.show(context),
              onLanguage: () => localeProvider.toggleLocale(),
            ),
            const SizedBox(height: 20),
            _ScanCard(
              label: l.scanDates,
              subtitle: l.identifyInSeconds,
              buttonLabel: l.scanNow,
              onScan: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ScanScreen())),
            ),
            const SizedBox(height: 28),
            _SectionHeader(
              title: l.recentScans,
              actionLabel: l.viewAll,
              onAction: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
            ),
            const SizedBox(height: 14),
            // ── Recent scans from scanHistoryNotifier (live) ──────────────
            ValueListenableBuilder<List<ScanHistoryEntry>>(
              valueListenable: scanHistoryNotifier,
              builder: (_, scans, __) {
                final recent = scans.take(5).toList();
                if (recent.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Center(
                        child: Text(
                          l.isArabic
                              ? 'لا توجد عمليات مسح بعد'
                              : 'No scans yet — try scanning a date!',
                          style: GoogleFonts.cairo(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return SizedBox(
                  height: 190,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: recent.length,
                    itemBuilder: (context, i) =>
                        _ScanHistoryCard(entry: recent[i]),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            _SellerAdvertisementCard(l: l),
            const SizedBox(height: 28),
            _SectionHeader(
              title: l.featuredSellers,
              actionLabel: l.exploreAll,
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const market.MarketScreen()),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _sellers.length,
                itemBuilder: (context, i) => _SellerCard(item: _sellers[i]),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String firstName;
  final AppLocalizations l;
  final VoidCallback onNotification, onLanguage;

  const _Header({
    required this.firstName,
    required this.l,
    required this.onNotification,
    required this.onLanguage,
  });

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
      padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onLanguage,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.language_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        l.isArabic ? 'EN' : 'ع',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: onNotification,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${l.greeting}, $firstName 👋',
            style: GoogleFonts.cairo(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.identifyInSeconds,
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

// ── Scan Promo Card ────────────────────────────────────────────────────────────
class _ScanCard extends StatelessWidget {
  final VoidCallback onScan;
  final String label, subtitle, buttonLabel;
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
            color: AppColors.brown900.withValues(alpha: 0.08),
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
                    color: AppColors.brown900,
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
                      color: AppColors.brown700,
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

// ── Section Header ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title, actionLabel;
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
              color: AppColors.brown900,
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

// ── Recent Scan History Card (live data) ──────────────────────────────────────
class _ScanHistoryCard extends StatelessWidget {
  final ScanHistoryEntry entry;
  const _ScanHistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isAr = localeProvider.isArabic;
    return GestureDetector(
      onTap: () {
        final result = ScanResult(
          nameEn: entry.nameEn,
          nameAr: entry.nameAr,
          originEn: entry.originEn,
          originAr: entry.originAr,
          confidence: entry.confidence,
          calories: entry.calories,
          carbs: entry.carbs,
          fiber: entry.fiber,
          potassium: entry.potassium,
          imageUrl: entry.imageUrl,
        );
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ScanResultScreen(result: result)),
        );
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: entry.imagePath.isNotEmpty
                  ? Image.asset(
                      entry.imagePath,
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
                    )
                  : Container(
                      height: 110,
                      color: const Color(0xFF2A3A3A),
                      child: const Icon(
                        Icons.eco_rounded,
                        color: Colors.white54,
                        size: 40,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? entry.nameAr : entry.nameEn,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.brown900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldBadge.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${entry.matchPercent}% Match',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldDark,
                      ),
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
}

// ── Seller Card ────────────────────────────────────────────────────────────────
class _SellerCard extends StatelessWidget {
  final Seller item;
  const _SellerCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => SellerScreen(seller: item))),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: AppColors.brown100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: AppColors.brown700,
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
                      color: AppColors.goldBadge.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.goldBadge,
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'TOP',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.goldDark,
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
                color: AppColors.brown900,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.goldBadge,
                  size: 15,
                ),
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
      ),
    );
  }
}

// ── Seller Advertisement Card ──────────────────────────────────────────────────
class _SellerAdvertisementCard extends StatelessWidget {
  final AppLocalizations l;
  const _SellerAdvertisementCard({required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.brown900,
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: AssetImage('assets/images/seller_banner.png'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brown900.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.black.withValues(alpha: 0.3),
              Colors.transparent,
            ],
            begin: l.isArabic ? Alignment.centerRight : Alignment.centerLeft,
            end: l.isArabic ? Alignment.centerLeft : Alignment.centerRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l.sellerAdTitle,
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  l.sellerAdSubtitle,
                  style: GoogleFonts.cairo(
                    color: AppColors.goldBadge,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  l.isArabic
                      ? Icons.arrow_back_rounded
                      : Icons.arrow_forward_rounded,
                  color: AppColors.goldBadge,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
