import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../core/logger.dart';
import '../core/validators.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../widgets/lang_toggle_button.dart';
import 'sign_up_screen.dart';
import 'reset_password_screen.dart';
import 'home_page.dart';
import 'auth/otp_verification_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  // ── Form ──────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isPhoneLoading = false;
  bool _obscure = true;
  bool _showPhoneSection = false;
  String? _errorMsg;

  final _auth = FirebaseAuth.instance;

  // ── Animation ─────────────────────────────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Sign-In Logic ─────────────────────────────────────────────────────────
  Future<void> _signIn() async {
    setState(() => _errorMsg = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      AppLogger.d('[SignIn] Starting email/password sign-in...');

      await _auth.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      AppLogger.d('[SignIn] Success');

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (_) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.e('[SignIn ERROR] Code: ${e.code}');
      if (mounted) {
        setState(() => _errorMsg = _friendlyError(e.code));
      }
    } catch (e, st) {
      AppLogger.e('[SignIn ERROR] $e', error: e, stackTrace: st);
      if (mounted) {
        setState(() => _errorMsg = 'Sign-in error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Sign-in failed ($code).';
    }
  }

  // ── Phone Sign-In Logic ───────────────────────────────────────────────────
  void _startPhoneSignIn() {
    setState(() => _errorMsg = null);
    final rawPhone = _phoneCtrl.text.trim();
    final err = AppValidators.phoneNumber(rawPhone);
    if (err != null) {
      setState(() => _errorMsg = err);
      return;
    }

    // Convert local Saudi format (05xxxxxxxx) to E.164 (+966xxxxxxxxx)
    final e164 = '+966${rawPhone.substring(1)}';

    setState(() => _isPhoneLoading = true);

    // Navigate to OTP screen — it handles sending & verifying
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(phoneNumber: e164),
          ),
        )
        .then((_) {
          if (mounted) setState(() => _isPhoneLoading = false);
        });
  }

  // ── Reusable field builder (matching sign-up style) ───────────────────────
  Widget _buildField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.labelColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: GoogleFonts.cairo(fontSize: 15, color: AppColors.titleColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.cairo(
              fontSize: 14,
              color: AppColors.hintColor,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(icon, size: 20, color: AppColors.fieldIcon),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 0,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.fieldBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.fieldBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.fieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.fieldIcon,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red.shade400,
                width: 1.5,
              ),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeProvider,
      builder: (context, locale, _) {
        final isAr = locale.languageCode == 'ar';
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: AppColors.bgCream,
            body: SafeArea(
              child: FadeTransition(
                opacity: _fadeIn,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 14),

                        // ── Language toggle ───────────────────────────────
                        const Align(
                          alignment: Alignment.centerRight,
                          child: LangToggleButton(),
                        ),
                        const SizedBox(height: 14),

                        // ── Logo ──────────────────────────────────────────
                        Center(
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.eco_rounded,
                              size: 56,
                              color: AppColors.palmGreen,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),


                  // ── Title ─────────────────────────────────────────────
                  Text(
                    AppLocalizations.of(context).welcomeBack,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.titleColor,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Email ─────────────────────────────────────────────
                  _buildField(
                    label: AppLocalizations.of(context).email,
                    hint: 'example@mail.com',
                    icon: Icons.email_outlined,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: AppValidators.email,
                  ),
                  const SizedBox(height: 18),

                  // ── Password ──────────────────────────────────────────
                  _buildField(
                    label: AppLocalizations.of(context).password,
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    controller: _passwordCtrl,
                    obscure: _obscure,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.hintColor,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Password is required.'
                        : null,
                  ),

                  // ── Forgot Password ───────────────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ResetPasswordScreen(),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.linkBrown,
                      ),
                      child: Text(
                        AppLocalizations.of(context).forgotPassword,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w600,
                          color: AppColors.linkBrown,
                        ),
                      ),
                    ),
                  ),

                  // ── Inline Error ──────────────────────────────────────
                  if (_errorMsg != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: Colors.red.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMsg!,
                              style: GoogleFonts.cairo(
                                color: Colors.red.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 8),

                  // ── Sign In Button ────────────────────────────────────
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonBg,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.buttonBg.withValues(
                          alpha: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                        textStyle: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
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
                          : Text(AppLocalizations.of(context).signIn),
                    ),
                  ),
                  const SizedBox(height: 20),



                  // ── OR Phone Divider ──────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: AppColors.fieldBorder,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.hintColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: AppColors.fieldBorder,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Phone Sign-In toggle ──────────────────────────────
                  GestureDetector(
                    onTap: () => setState(
                      () => _showPhoneSection = !_showPhoneSection,
                    ),
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.fieldBg,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: _showPhoneSection
                              ? AppColors.brown700
                              : AppColors.fieldBorder,
                          width: _showPhoneSection ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 20,
                            color: _showPhoneSection
                                ? AppColors.brown700
                                : AppColors.fieldIcon,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Continue with Phone',
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _showPhoneSection
                                  ? AppColors.brown700
                                  : AppColors.titleColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedRotation(
                            duration: const Duration(milliseconds: 200),
                            turns: _showPhoneSection ? 0.5 : 0,
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: _showPhoneSection
                                  ? AppColors.brown700
                                  : AppColors.fieldIcon,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Collapsible phone field + OTP button ──────────────
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _showPhoneSection
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 16),
                              _buildField(
                                label: 'Phone Number',
                                hint: '05XXXXXXXX',
                                icon: Icons.phone_outlined,
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                validator: AppValidators.phoneNumber,
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _isPhoneLoading
                                      ? null
                                      : _startPhoneSignIn,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.brown700,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        AppColors.brown700.withValues(
                                      alpha: 0.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    elevation: 0,
                                    textStyle: GoogleFonts.cairo(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  child: _isPhoneLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text('Send OTP'),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),

                  // ── Switch to Sign Up ─────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context).noAccount,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: AppColors.termsText,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const SignUpScreen(),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context).signUp,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.titleColor,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.titleColor,
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
              ),
            ),
          ),
        );
      },
    );
  }
}


