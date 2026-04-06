import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart'; // kGoldenDate, kOffWhite, kCardWhite, kBorderLight
import '../services/auth_service.dart';
import 'sign_in_screen.dart';

class ManageProfileScreen extends StatefulWidget {
  const ManageProfileScreen({super.key});

  @override
  State<ManageProfileScreen> createState() => _ManageProfileScreenState();
}

class _ManageProfileScreenState extends State<ManageProfileScreen> {
  // ── Form ──────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isFetching = true;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // ── Fetch Profile from Firestore ──────────────────────────────────────────
  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isFetching = false);
      return;
    }

    try {
      final snap = await _firestore.collection('users').doc(user.uid).get();

      if (snap.exists && mounted) {
        final data = snap.data()!;
        _nameCtrl.text = data['fullName'] ?? '';
        _emailCtrl.text = data['email'] ?? user.email ?? '';
      } else if (mounted) {
        _emailCtrl.text = user.email ?? '';
      }
    } catch (e) {
      debugPrint('Fetch profile error: $e');
      if (mounted) _showSnackBar('Could not load profile.', isError: true);
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  // ── Save Profile to Firestore ─────────────────────────────────────────────
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) {
      _showSnackBar('Not authenticated. Please sign in again.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firestore.collection('users').doc(user.uid).set(
        {
          'fullName': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true), // preserve scan history, favorites, etc.
      );

      if (mounted) _showSnackBar('Profile updated successfully!');
    } catch (e) {
      debugPrint('Save profile error: $e');
      if (mounted) _showSnackBar('Failed to save. Try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> _signOut() async {
    await AuthService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (_) => false,
      );
    }
  }

  // ── SnackBar Helper ───────────────────────────────────────────────────────
  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? Colors.red.shade700
            : const Color(0xFF5C3A1E),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Computed initial for the avatar ────────────────────────────────────────
  String get _userInitial {
    final name = _nameCtrl.text.trim();
    if (name.isNotEmpty) return name[0].toUpperCase();
    final email = _emailCtrl.text.trim();
    if (email.isNotEmpty) return email[0].toUpperCase();
    return '?';
  }

  // ═════════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kOffWhite,
      // No AppBar — we build a custom header instead
      body: _isFetching
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5C3A1E)),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // ─── 1. Profile Header Card ─────────────────────────────
                  _buildProfileHeader(context),

                  // ─── Scrollable content below the header ────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 28),

                          // ─── 2. Edit Information Card ───────────────────
                          _buildEditCard(),

                          const SizedBox(height: 28),

                          // ─── 3. My Journey Stats ────────────────────────
                          _buildSectionLabel('My Journey'),
                          const SizedBox(height: 14),
                          _buildStatCards(),

                          const SizedBox(height: 28),

                          // ─── 4. Settings List ───────────────────────────
                          _buildSectionLabel('Settings'),
                          const SizedBox(height: 14),
                          _buildSettingsList(),

                          const SizedBox(height: 36),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  //  1. PROFILE HEADER
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildProfileHeader(BuildContext context) {
    final name = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim()
        : 'Nakhlah User';
    final email = _emailCtrl.text.trim().isNotEmpty
        ? _emailCtrl.text.trim()
        : _auth.currentUser?.email ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 32,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5C3A1E), Color(0xFF6B4423)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Back button row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                Text(
                  'My Profile',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                // Invisible icon to keep title centered
                const SizedBox(width: 48),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Avatar with user initial
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kGoldenDate,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _userInitial,
                style: GoogleFonts.cairo(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Name
          Text(
            name,
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),

          // Email
          Text(
            email,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  //  2. EDIT INFORMATION CARD
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildEditCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: kCardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C3A1E).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section heading
          Row(
            children: [
              const Icon(Icons.edit_rounded, color: kGoldenDate, size: 20),
              const SizedBox(width: 8),
              Text(
                'Edit Information',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5C3A1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Full Name field
          TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required.' : null,
          ),
          const SizedBox(height: 16),

          // Email field
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required.';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                return 'Enter a valid email address.';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveChanges,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded, size: 20),
              label: Text(_isLoading ? 'Saving...' : 'Save Updates'),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  //  3. MY JOURNEY — STAT CARDS
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.camera_alt_outlined,
            value: '0',
            label: 'Dates Scanned',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            icon: Icons.favorite_outline_rounded,
            value: '0',
            label: 'Saved Favorites',
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  //  4. SETTINGS LIST
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildSettingsList() {
    return Container(
      decoration: BoxDecoration(
        color: kCardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C3A1E).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.language_rounded,
            label: 'Change Language',
            trailing: Text(
              'English',
              style: GoogleFonts.cairo(
                color: Colors.grey.shade500,
                fontSize: 13,
              ),
            ),
            onTap: () => _showSnackBar('Language settings coming soon!'),
          ),
          const Divider(height: 1, indent: 56, endIndent: 16),
          _SettingsTile(
            icon: Icons.restaurant_rounded,
            label: 'Dietary Goals',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: kGoldenDate,
              size: 22,
            ),
            onTap: () => _showSnackBar('Dietary goals coming soon!'),
          ),
          const Divider(height: 1, indent: 56, endIndent: 16),
          _SettingsTile(
            icon: Icons.logout_rounded,
            label: 'Log Out',
            isDestructive: true,
            trailing: const SizedBox.shrink(),
            onTap: _signOut,
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: kGoldenDate,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.cairo(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5C3A1E),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PRIVATE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

/// A stat card showing an icon, a big number, and a label.
/// Uses a subtle gradient background with Golden Date accent icons.
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: kCardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorderLight),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C3A1E).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon inside a subtle circle
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kGoldenDate.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: kGoldenDate, size: 24),
          ),
          const SizedBox(height: 14),
          // Big number
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF5C3A1E),
            ),
          ),
          const SizedBox(height: 2),
          // Label
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single row in the settings list.
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red.shade600 : const Color(0xFF5C3A1E);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isDestructive
              ? Colors.red.withValues(alpha: 0.08)
              : const Color(0xFF5C3A1E).withValues(alpha: 0.08),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.w600,
          color: color,
          fontSize: 14,
        ),
      ),
      trailing: trailing,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onTap: onTap,
    );
  }
}
