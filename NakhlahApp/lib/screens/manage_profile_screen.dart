import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

import '../theme/app_colors.dart';
import '../core/validators.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import '../repositories/user_repository.dart';
import '../domain/favorites_notifier.dart';
import '../domain/scan_history_notifier.dart';
import 'auth/otp_verification_screen.dart';
import 'sign_in_screen.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';
import 'seller_dashboard_screen.dart';

class ManageProfileScreen extends StatefulWidget {
  const ManageProfileScreen({super.key});

  @override
  State<ManageProfileScreen> createState() => _ManageProfileScreenState();
}

class _ManageProfileScreenState extends State<ManageProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  bool _isFetching = true;
  String? _photoUrl;
  String _originalPhone = '';
  bool _isSeller = false; // true when users/{uid}.role == "seller"

  final _auth = FirebaseAuth.instance;
  final _userRepo = UserRepository();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isFetching = false);
      return;
    }
    try {
      final appUser = await _userRepo.getUser(user.uid);
      if (appUser != null && mounted) {
        _nameCtrl.text = appUser.fullName;
        _emailCtrl.text = appUser.email.isNotEmpty
            ? appUser.email
            : user.email ?? '';
        _phoneCtrl.text = appUser.phone;
        _originalPhone = appUser.phone;
        _photoUrl = appUser.photoUrl.isNotEmpty
            ? appUser.photoUrl
            : user.photoURL ?? '';
        _isSeller = appUser.role == 'seller';
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

  // ── Photo Upload (FREE — base64 in Firestore, no Storage needed) ──────────

  Future<void> _pickAndUploadPhoto() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Request permission
    PermissionStatus status = await Permission.photos.request();
    if (!status.isGranted) status = await Permission.storage.request();
    if (!status.isGranted) {
      if (mounted) {
        _showSnackBar(
          localeProvider.isArabic
              ? 'يرجى منح إذن الوصول إلى المعرض'
              : 'Gallery permission is required.',
          isError: true,
        );
      }
      return;
    }

    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 300,
      maxHeight: 300,
    );
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      // Read the picked file
      final bytes = await File(picked.path).readAsBytes();

      // Decode, resize to 200×200, and re-encode as JPEG at 70% quality
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception('Could not decode image');
      final resized = img.copyResize(decoded, width: 200, height: 200);
      final jpegBytes = img.encodeJpg(resized, quality: 70);

      // Convert to base64 data URI
      final base64Str = base64Encode(jpegBytes);
      final dataUri = 'data:image/jpeg;base64,$base64Str';

      // Save to Firestore (FREE — no Firebase Storage needed)
      await _userRepo.updateUser(user.uid, {'photoUrl': dataUri});

      if (mounted) {
        setState(() => _photoUrl = dataUri);
        _showSnackBar(
          localeProvider.isArabic
              ? 'تم تحديث الصورة بنجاح!'
              : 'Photo updated successfully!',
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          localeProvider.isArabic
              ? 'فشل رفع الصورة. حاول مجدداً.'
              : 'Photo upload failed. Try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  // ── Save Changes ──────────────────────────────────────────────────────────

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _auth.currentUser;
    if (user == null) return;

    final newPhone = _phoneCtrl.text.trim();
    final phoneChanged = newPhone != _originalPhone && newPhone.isNotEmpty;

    setState(() => _isLoading = true);
    try {
      await _userRepo.updateUser(user.uid, {
        'fullName': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        if (!phoneChanged) 'phone': newPhone,
      });

      if (!mounted) return;

      if (phoneChanged) {
        final e164 = _toE164(newPhone);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              phoneNumber: e164,
              onVerified: () => _savePhoneAfterOtp(user.uid, newPhone),
            ),
          ),
        );
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (mounted) {
        _showSnackBar(AppLocalizations.of(context).profileUpdated);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(AppLocalizations.of(context).failedToSave, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePhoneAfterOtp(String uid, String phone) async {
    try {
      await _userRepo.updateUser(uid, {'phone': phone});
      _originalPhone = phone;
      if (mounted) {
        Navigator.of(context).pop();
        _showSnackBar(AppLocalizations.of(context).profileUpdated);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(AppLocalizations.of(context).failedToSave, isError: true);
      }
    }
  }

  String _toE164(String phone) {
    if (phone.startsWith('+')) return phone;
    if (phone.startsWith('05') && phone.length == 10) {
      return '+966${phone.substring(1)}';
    }
    return '+966$phone';
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
        backgroundColor: isError ? Colors.red.shade700 : AppColors.brown700,
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
        backgroundColor: AppColors.brown700,
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

  /// Builds the avatar image, supporting both base64 data URIs and network URLs.
  Widget _buildAvatarImage() {
    final url = _photoUrl!;
    final fallback = Center(
      child: Text(
        _userInitial,
        style: GoogleFonts.cairo(
          fontSize: 38,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );

    // Base64 data URI (free Firestore approach)
    if (url.startsWith('data:image')) {
      try {
        final base64Str = url.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        );
      } catch (_) {
        return fallback;
      }
    }

    // Legacy network URL (Firebase Storage or other)
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isAr = localeProvider.isArabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        body: _isFetching
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.brown700),
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
    final phone = _phoneCtrl.text.trim();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 32,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brown700, Color(0xFF6B4423)],
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
                if (Navigator.canPop(context))
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                else
                  const SizedBox(width: 48),
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

          // ── Avatar with upload overlay ─────────────────────────────────
          GestureDetector(
            onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
            child: Stack(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.goldenDate,
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
                    child: (_photoUrl != null && _photoUrl!.isNotEmpty)
                        ? _buildAvatarImage()
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
                // Upload indicator / camera icon overlay
                if (_isUploadingPhoto)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.goldenDate,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 14,
                        color: Colors.white,
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
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  phone,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditCard(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.brown700.withValues(alpha: 0.06),
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
              const Icon(
                Icons.edit_rounded,
                color: AppColors.goldenDate,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l.editInformation,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brown700,
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
            validator: AppValidators.fullName,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            validator: AppValidators.email,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l.phoneNumber,
              hintText: l.phoneHint,
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              return AppValidators.phoneNumber(v);
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brown700,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.brown700.withValues(
                  alpha: 0.4,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_isLoading ? l.saving : l.saveUpdates),
                  const SizedBox(width: 8),
                  _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 20,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(AppLocalizations l) {
    return Row(
      children: [
        // Scan count — live from scanHistoryNotifier
        Expanded(
          child: ValueListenableBuilder<List<ScanHistoryEntry>>(
            valueListenable: scanHistoryNotifier,
            builder: (_, scans, _) => _StatCard(
              icon: Icons.camera_alt_outlined,
              value: scans.length.toString(),
              label: l.datesScanned,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
            ),
          ),
        ),
        const SizedBox(width: 14),
        // Favorites count — live from favoritesNotifier
        Expanded(
          child: ValueListenableBuilder<Set<String>>(
            valueListenable: favoritesNotifier,
            builder: (_, favorites, _) => _StatCard(
              icon: Icons.favorite_outline_rounded,
              value: favorites.length.toString(),
              label: l.savedFavorites,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsList(AppLocalizations l) {
    final isAr = localeProvider.isArabic;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.brown700.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Seller dashboard entry — only shown when role == "seller"
          if (_isSeller) ...[
            _SettingsTile(
              icon: Icons.storefront_rounded,
              label: isAr ? 'لوحة تحكم البائع' : 'My Seller Dashboard',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.goldBadge.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isAr ? 'بائع' : 'Seller',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldDark,
                  ),
                ),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const SellerDashboardScreen()),
              ),
            ),
            const Divider(height: 1, indent: 56, endIndent: 16),
          ],
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
                      color: AppColors.brown700.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.brown700.withValues(alpha: 0.2),
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
                            color: AppColors.brown700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.swap_horiz_rounded,
                          size: 16,
                          color: AppColors.brown700,
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
            color: AppColors.goldenDate,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.cairo(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.brown700,
          ),
        ),
      ],
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final VoidCallback onTap;
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.brown700.withValues(alpha: 0.05),
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
                color: AppColors.goldenDate.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: AppColors.goldenDate, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.brown700,
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
    final color = isDestructive ? Colors.red.shade600 : AppColors.brown700;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isDestructive
              ? Colors.red.withValues(alpha: 0.08)
              : AppColors.brown700.withValues(alpha: 0.08),
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
