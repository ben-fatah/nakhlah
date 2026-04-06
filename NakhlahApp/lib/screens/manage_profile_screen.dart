import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../main.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import 'sign_in_screen.dart';

class ManageProfileScreen extends StatefulWidget {
  const ManageProfileScreen({super.key});

  @override
  State<ManageProfileScreen> createState() => _ManageProfileScreenState();
}

class _ManageProfileScreenState extends State<ManageProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isFetching = true;
  bool _isUploadingPhoto = false;
  File? _pickedPhoto;
  String? _photoUrl;
  final _picker = ImagePicker();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

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
        _photoUrl = data['photoUrl'] ?? user.photoURL ?? '';
      } else if (mounted) {
        _emailCtrl.text = user.email ?? '';
        _photoUrl = user.photoURL ?? '';
      }
    } catch (e) {
      if (mounted) _showSnackBar('Could not load profile.', isError: true);
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  // ── Photo Picker ────────────────────────────────────────────────────────
  // We call image_picker DIRECTLY — it triggers the native OS permission
  // dialog on its own, exactly like WhatsApp, Instagram, etc.
  // We only call openAppSettings() if the user already permanently denied.
  Future<void> _pickAndUploadPhoto() async {
    // Check current status WITHOUT requesting — so we don't pre-block
    final currentStatus = await Permission.photos.status;
    final storageStatus = await Permission.storage.status;

    // If already permanently denied → send user to Settings
    if (currentStatus.isPermanentlyDenied &&
        storageStatus.isPermanentlyDenied) {
      if (mounted) _showSettingsDialog();
      return;
    }

    // Otherwise just open the picker — the OS will show the permission
    // dialog automatically on first use (Android & iOS both handle this)
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 512,
      );

      if (picked == null) return; // user cancelled

      final file = File(picked.path);
      setState(() {
        _pickedPhoto = file;
        _isUploadingPhoto = true;
      });

      await _uploadPhoto(file);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('permission') ||
          msg.contains('denied') ||
          msg.contains('access')) {
        if (mounted) _showSettingsDialog();
      } else {
        if (mounted) {
          _showSnackBar('Could not open gallery. Try again.', isError: true);
        }
      }
    }
  }

  Future<void> _uploadPhoto(File file) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final ref = FirebaseStorage.instance.ref().child(
        'profile_photos/${user.uid}.jpg',
      );
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      await _firestore.collection('users').doc(user.uid).set({
        'photoUrl': url,
      }, SetOptions(merge: true));
      await user.updatePhotoURL(url);
      if (mounted) {
        setState(() => _photoUrl = url);
        _showSnackBar('Profile photo updated!');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to upload photo. Try again.', isError: true);
        setState(() => _pickedPhoto = null);
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Permission Required',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Gallery access is blocked. Please open Settings → App Permissions → Photos and allow access.',
          style: GoogleFonts.cairo(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.cairo(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C3A1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(
              'Open Settings',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _auth.currentUser;
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'fullName': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) _showSnackBar(AppLocalizations.of(context).profileUpdated);
    } catch (e) {
      if (mounted) {
        _showSnackBar(AppLocalizations.of(context).failedToSave, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await AuthService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (_) => false,
      );
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? Colors.red.shade700
            : const Color(0xFF5C3A1E),
        margin: const EdgeInsets.all(16),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _toggleLanguage() {
    localeProvider.toggleLocale();
    final isNowArabic = localeProvider.isArabic;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isNowArabic ? 'تم التبديل إلى العربية 🌙' : 'Switched to English 🌍',
        ),
        backgroundColor: const Color(0xFF5C3A1E),
        margin: const EdgeInsets.all(16),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String get _userInitial {
    final name = _nameCtrl.text.trim();
    if (name.isNotEmpty) return name[0].toUpperCase();
    final email = _emailCtrl.text.trim();
    if (email.isNotEmpty) return email[0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isAr = localeProvider.isArabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: kOffWhite,
        body: _isFetching
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF5C3A1E)),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProfileHeader(context, l),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 28),
                            _buildEditCard(l),
                            const SizedBox(height: 28),
                            _buildSectionLabel(l.myJourney),
                            const SizedBox(height: 14),
                            _buildStatCards(l),
                            const SizedBox(height: 28),
                            _buildSectionLabel(l.settings),
                            const SizedBox(height: 14),
                            _buildSettingsList(l),
                            const SizedBox(height: 36),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AppLocalizations l) {
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
                  l.myProfile,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Tappable avatar ──────────────────────────────────────────
          GestureDetector(
            onTap: _pickAndUploadPhoto,
            child: Stack(
              children: [
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
                  child: ClipOval(
                    child: _isUploadingPhoto
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : _pickedPhoto != null
                        ? Image.file(_pickedPhoto!, fit: BoxFit.cover)
                        : (_photoUrl != null && _photoUrl!.isNotEmpty)
                        ? Image.network(
                            _photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Center(
                              child: Text(
                                _userInitial,
                                style: GoogleFonts.cairo(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : Center(
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
                ),
                // Gold camera badge
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: kGoldenDate,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          Text(
            name,
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
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

  Widget _buildEditCard(AppLocalizations l) {
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
          Row(
            children: [
              const Icon(Icons.edit_rounded, color: kGoldenDate, size: 20),
              const SizedBox(width: 8),
              Text(
                l.editInformation,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5C3A1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l.fullName,
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required.' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
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
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C3A1E),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(
                  0xFF5C3A1E,
                ).withValues(alpha: 0.4),
              ),
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
              label: Text(_isLoading ? l.saving : l.saveUpdates),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(AppLocalizations l) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.camera_alt_outlined,
            value: '0',
            label: l.datesScanned,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            icon: Icons.favorite_outline_rounded,
            value: '0',
            label: l.savedFavorites,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsList(AppLocalizations l) {
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
            label: l.changeLanguage,
            trailing: ValueListenableBuilder<Locale>(
              valueListenable: localeProvider,
              builder: (_, locale, _) {
                final isAr = locale.languageCode == 'ar';
                return GestureDetector(
                  onTap: _toggleLanguage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C3A1E).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF5C3A1E).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isAr ? 'عربي' : 'EN',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF5C3A1E),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.swap_horiz_rounded,
                          size: 16,
                          color: Color(0xFF5C3A1E),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAr ? 'EN' : 'عربي',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            onTap: _toggleLanguage,
          ),
          const Divider(height: 1, indent: 56, endIndent: 16),
          _SettingsTile(
            icon: Icons.restaurant_rounded,
            label: l.dietaryGoals,
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
            label: l.logOut,
            isDestructive: true,
            trailing: const SizedBox.shrink(),
            onTap: _signOut,
          ),
        ],
      ),
    );
  }

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

// ── Stat Card ─────────────────────────────────────────────────────────────────
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
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF5C3A1E),
            ),
          ),
          const SizedBox(height: 2),
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

// ── Settings Tile ─────────────────────────────────────────────────────────────
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
