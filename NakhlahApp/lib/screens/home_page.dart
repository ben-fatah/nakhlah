import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart'; // palette constants
import 'sign_in_screen.dart';
import 'manage_profile_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // ── Sign-Out ──────────────────────────────────────────────────────────────
  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'No email';

    return Scaffold(
      // ── App Bar ───────────────────────────────────────────────────────────
      appBar: AppBar(
        title: const Text('Nakhlah'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
        ],
      ),

      // ── Drawer ────────────────────────────────────────────────────────────
      drawer: Drawer(
        child: Column(
          children: [
            // Header with Palm Green background
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: kPalmGreen,
                image: DecorationImage(
                  image: AssetImage(''), // placeholder — won't render but won't crash
                  fit: BoxFit.cover,
                  opacity: 0,
                ),
              ),
              currentAccountPicture: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kGoldenDate, width: 2.5),
                  color: kCardWhite,
                ),
                child: const Icon(Icons.person_rounded,
                    size: 40, color: kPalmGreen),
              ),
              accountName: Text(
                'Nakhlah User',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
              accountEmail: Text(
                email,
                style: GoogleFonts.cairo(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),

            // ── Nav Items ───────────────────────────────────────────────────
            _DrawerTile(
              icon: Icons.home_outlined,
              label: 'Home',
              onTap: () => Navigator.of(context).pop(),
            ),
            _DrawerTile(
              icon: Icons.manage_accounts_outlined,
              label: 'Manage Profile',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ManageProfileScreen()),
                );
              },
            ),

            const Divider(indent: 16, endIndent: 16),

            // ── Log Out (red) ───────────────────────────────────────────────
            _DrawerTile(
              icon: Icons.logout_rounded,
              label: 'Log Out',
              isDestructive: true,
              onTap: () => _signOut(context),
            ),

            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'Nakhlah v1.0',
                style: GoogleFonts.cairo(
                    color: Colors.grey.shade400, fontSize: 12),
              ),
            ),
          ],
        ),
      ),

      // ── Dashboard Body ────────────────────────────────────────────────────
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting Card ─────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kPalmGreen, Color(0xFF3D7852)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: kPalmGreen.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.eco_rounded,
                          color: kGoldenDate, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'Welcome to Nakhlah!',
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your AI-powered date variety\nidentification assistant.',
                    style: GoogleFonts.cairo(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Section Label ─────────────────────────────────────────────
            Text(
              'Quick Actions',
              style: GoogleFonts.cairo(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: kPalmGreen,
              ),
            ),
            const SizedBox(height: 14),

            // ── Quick Action Grid ─────────────────────────────────────────
            _ActionCard(
              icon: Icons.camera_alt_outlined,
              title: 'Scan a Date',
              subtitle: 'Use the camera to identify date varieties.',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Scan feature coming soon!')),
                );
              },
            ),
            const SizedBox(height: 14),
            _ActionCard(
              icon: Icons.manage_accounts_outlined,
              title: 'Manage Profile',
              subtitle: 'View and update your account details.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const ManageProfileScreen()),
              ),
            ),
            const SizedBox(height: 14),
            _ActionCard(
              icon: Icons.history_rounded,
              title: 'Scan History',
              subtitle: 'Review your past identifications.',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History feature coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Private Widgets
// ═══════════════════════════════════════════════════════════════════════════════

/// A drawer navigation tile styled with the app palette.
class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red.shade600 : kPalmGreen;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}

/// A dashboard action card with a subtle shadow & golden accent arrow.
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(14),
      color: kCardWhite,
      elevation: 2,
      shadowColor: kPalmGreen.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        splashColor: kGoldenDate.withValues(alpha: 0.12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: kPalmGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: kPalmGreen, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: kPalmGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: kGoldenDate, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
