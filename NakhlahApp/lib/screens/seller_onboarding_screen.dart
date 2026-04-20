import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/locale_provider.dart';
import '../repositories/marketplace_seller_repository.dart';
import '../theme/app_colors.dart';
import 'seller_dashboard_screen.dart';

/// Onboarding screen shown when a user taps "Join as Seller".
///
/// Collects display name, bio, location, and an optional avatar image,
/// then calls [MarketplaceSellerRepository.registerSeller] to:
///   1. Upload avatar → Firebase Storage
///   2. Write `sellers/{uid}` document
///   3. Flip `users/{uid}.role` → "seller"
///
/// On success navigates to [SellerDashboardScreen], replacing itself.
class SellerOnboardingScreen extends StatefulWidget {
  const SellerOnboardingScreen({super.key});

  @override
  State<SellerOnboardingScreen> createState() => _SellerOnboardingScreenState();
}

class _SellerOnboardingScreenState extends State<SellerOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  File? _avatarFile;
  bool _isLoading = false;

  final _picker = ImagePicker();
  final _repo = MarketplaceSellerRepository.instance;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  // ── Avatar pick ────────────────────────────────────────────────────────────

  Future<void> _pickAvatar() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null) return;
    setState(() => _avatarFile = File(picked.path));
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _repo.registerSeller(
        displayName: _nameCtrl.text,
        bio: _bioCtrl.text,
        location: _locationCtrl.text,
        avatarFile: _avatarFile,
      );

      if (!mounted) return;
      // Replace this screen with the dashboard — user is now a seller.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SellerDashboardScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localeProvider.isArabic
                ? 'فشل التسجيل. حاول مجدداً.'
                : 'Registration failed. Please try again.',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isAr = localeProvider.isArabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        body: CustomScrollView(
          slivers: [
            _buildAppBar(context, isAr),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AvatarPicker(
                        file: _avatarFile,
                        onTap: _pickAvatar,
                        isAr: isAr,
                      ),
                      const SizedBox(height: 32),
                      _buildSectionLabel(
                        isAr ? 'معلومات المتجر' : 'Shop Information',
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _nameCtrl,
                        label: isAr ? 'اسم المتجر' : 'Shop Name',
                        hint: isAr ? 'مزرعة النخلة' : 'Al-Nakhlah Farm',
                        icon: Icons.storefront_outlined,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return isAr
                                ? 'يرجى إدخال اسم المتجر'
                                : 'Shop name is required';
                          }
                          if (v.trim().length < 3) {
                            return isAr
                                ? 'الاسم قصير جداً'
                                : 'Name is too short';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _locationCtrl,
                        label: isAr ? 'الموقع' : 'Location',
                        hint: isAr ? 'المدينة المنورة، KSA' : 'Riyadh, KSA',
                        icon: Icons.location_on_outlined,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return isAr
                                ? 'يرجى إدخال الموقع'
                                : 'Location is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _bioCtrl,
                        label: isAr ? 'نبذة عن المتجر' : 'About your shop',
                        hint: isAr
                            ? 'متخصصون في تمور الأجوة الطازجة...'
                            : 'We specialize in fresh Ajwa dates...',
                        icon: Icons.info_outline_rounded,
                        maxLines: 4,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return isAr ? 'يرجى إدخال نبذة' : 'Bio is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      _SubmitButton(isLoading: _isLoading, isAr: isAr, onTap: _submit),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, bool isAr) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.brown900,
      leading: IconButton(
        icon: Icon(
          isAr ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_rounded,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.brown900, AppColors.brown700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 36),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.goldBadge.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.goldBadge.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: AppColors.goldBadge,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isAr ? 'انضم كبائع' : 'Become a Seller',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  isAr
                      ? 'عرض تمورك لآلاف المشترين'
                      : 'List your dates to thousands of buyers',
                  style: GoogleFonts.cairo(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.goldBadge,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.brown700,
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.cairo(fontSize: 14, color: AppColors.brown900),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.fieldIcon, size: 20),
        filled: true,
        fillColor: AppColors.fieldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.brown700, width: 1.5),
        ),
        labelStyle: GoogleFonts.cairo(color: AppColors.labelColor, fontSize: 13),
        hintStyle: GoogleFonts.cairo(color: AppColors.hintColor, fontSize: 13),
      ),
    );
  }
}

// ── Avatar Picker ──────────────────────────────────────────────────────────────

class _AvatarPicker extends StatelessWidget {
  final File? file;
  final VoidCallback onTap;
  final bool isAr;

  const _AvatarPicker({
    required this.file,
    required this.onTap,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brown100,
                    border: Border.all(
                      color: AppColors.goldBadge.withValues(alpha: 0.5),
                      width: 2.5,
                    ),
                  ),
                  child: ClipOval(
                    child: file != null
                        ? Image.file(file!, fit: BoxFit.cover)
                        : const Icon(
                            Icons.storefront_outlined,
                            size: 44,
                            color: AppColors.brown700,
                          ),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brown700,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isAr ? 'إضافة صورة للمتجر (اختياري)' : 'Add shop photo (optional)',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Submit Button ──────────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  final bool isLoading;
  final bool isAr;
  final VoidCallback onTap;

  const _SubmitButton({
    required this.isLoading,
    required this.isAr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brown700,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.brown700.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.storefront_rounded, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    isAr ? 'إنشاء متجري' : 'Create My Shop',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
