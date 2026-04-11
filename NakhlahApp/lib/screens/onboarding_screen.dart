import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../repositories/onboarding_repository.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import 'home_page.dart';
import 'sign_in_screen.dart';

class OnboardingScreen extends StatefulWidget {
  /// Optionally inject a pre-built repository (useful in tests).
  final OnboardingRepository? repository;
  const OnboardingScreen({super.key, this.repository});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final OnboardingRepository _repo;
  final PageController _controller = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      title: 'Scan Any Date',
      description:
          'Point your camera at any date fruit and our AI instantly identifies the variety.',
      imagePath:
          'assets/images/dates_closeup.png', // swap with your illustration
    ),
    _OnboardingData(
      title: 'Get Nutritional Info',
      description:
          'Instantly view detailed nutritional data for every date variety you scan.',
      imagePath: 'assets/images/nutritional.png',
    ),
    _OnboardingData(
      title: 'Explore Varieties',
      description:
          'Discover 8 unique date varieties from across the region with Nakhlah AI.',
      imagePath: 'assets/images/nakhlah_hero.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Use injected repo (for testing) or create a synchronous-safe one.
    // At runtime OnboardingRepository is pre-created in main() and passed in.
    _repo = widget.repository ?? OnboardingRepository();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      // Delegate ALL SharedPreferences + Firebase logic to the repository
      final goHome = await _repo.finishOnboarding();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => goHome ? const HomePage() : const SignInScreen(),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top row: skip button ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : _finishOnboarding,
                    child: Text(
                      l.skip,
                      style: GoogleFonts.cairo(
                        color: AppColors.brown700,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Pages ────────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, index) =>
                    _OnboardingPage(data: _pages[index]),
              ),
            ),

            // ── Dots ─────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _currentPage ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? const Color(0xFF5C3D1E)
                        : const Color(0xFFD4B896),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Button ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brown700,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.brown700.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _currentPage == _pages.length - 1
                              ? l.getStarted
                              : l.next,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // ── Illustration card ──────────────────────────────────────────
          Container(
            width: double.infinity,
            height: size.height * 0.42,
            margin: const EdgeInsets.only(bottom: 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5C3D1E).withValues(alpha: 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Warm gradient background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFFBF5), Color(0xFFF5EDE0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // Page illustration (falls back to logo if image missing)
                  Center(
                    child: Image.asset(
                      data.imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Padding(
                          padding: const EdgeInsets.all(48),
                          child: Image.asset(
                            'assets/images/icon.png',
                            fit: BoxFit.contain,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Title ──────────────────────────────────────────────────────
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),

          // ── Description ────────────────────────────────────────────────
          Text(
            data.description,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final String title;
  final String description;
  final String imagePath;

  _OnboardingData({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}
