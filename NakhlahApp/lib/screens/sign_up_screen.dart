import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../core/logger.dart';
import '../core/validators.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import 'sign_in_screen.dart';
import 'home_page.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  // ── Form ─────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  final bool _obscureConfirm = true;

  // ── Password-strength tracking ───────────────────────────────────────────
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _passwordTouched = false;

  // ── Firebase ──────────────────────────────────────────────────────────────
  final _auth = FirebaseAuth.instance;
  final _userRepo = UserRepository();

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

    // Live password-requirement tracking
    _passwordCtrl.addListener(_evaluatePassword);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _evaluatePassword() {
    final pwd = _passwordCtrl.text;
    setState(() {
      _passwordTouched = pwd.isNotEmpty;
      _hasMinLength = pwd.length >= 8;
      _hasUppercase = pwd.contains(RegExp(r'[A-Z]'));
      _hasNumber = pwd.contains(RegExp(r'[0-9]'));
    });
  }

  // ── Sign-Up Logic ─────────────────────────────────────────────────────────
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      // Set the display name on the Firebase Auth profile
      await credential.user!.updateDisplayName(_nameCtrl.text.trim());
      await credential.user!.reload();

      // Save user to Firestore via repository
      await _userRepo.saveUser(
        AppUser(
          uid: credential.user!.uid,
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
        ),
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (_) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.e('FirebaseAuthException — code: ${e.code}');
      if (mounted) _showSnackBar(e.message ?? 'Sign-up failed (${e.code}).');
    } catch (e, st) {
      AppLogger.e('Unexpected sign-up error: $e', error: e, stackTrace: st);
      if (mounted) _showSnackBar('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Reusable field builder ────────────────────────────────────────────────
  Widget _buildField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
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
          textCapitalization: textCapitalization,
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
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  // ── Password requirement row ──────────────────────────────────────────────
  Widget _buildRequirement(String text, bool met) {
    return Row(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Icon(
            met ? Icons.check_circle_rounded : Icons.cancel_rounded,
            key: ValueKey(met),
            size: 16,
            color: met ? const Color(0xFF4CAF50) : const Color(0xFFD32F2F),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: met ? const Color(0xFF4CAF50) : const Color(0xFFD32F2F),
          ),
        ),
      ],
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  const SizedBox(height: 8),

                  // ── Back Arrow ──────────────────────────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const SignInScreen()),
                      ),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.titleColor,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Logo ────────────────────────────────────────────────
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

                  // ── Title ───────────────────────────────────────────────
                  Text(
                    AppLocalizations.of(context).createAccount,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.titleColor,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Full Name ───────────────────────────────────────────
                  _buildField(
                    label: AppLocalizations.of(context).fullName,
                    hint: 'Ali Al-Otaibi',
                    icon: Icons.person_outline_rounded,
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    validator: AppValidators.fullName,
                  ),
                  const SizedBox(height: 18),

                  // ── Email ───────────────────────────────────────────────
                  _buildField(
                    label: AppLocalizations.of(context).email,
                    hint: 'example@mail.com',
                    icon: Icons.email_outlined,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: AppValidators.email,
                  ),
                  const SizedBox(height: 18),

                  // ── Password ────────────────────────────────────────────
                  _buildField(
                    label: AppLocalizations.of(context).password,
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    controller: _passwordCtrl,
                    obscure: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.hintColor,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: AppValidators.password,
                  ),

                  // ── Password requirements checklist ─────────────────────
                  if (_passwordTouched) ...[
                    const SizedBox(height: 10),
                    _buildRequirement('At least 8 characters', _hasMinLength),
                    const SizedBox(height: 4),
                    _buildRequirement(
                      'At least one capital letter',
                      _hasUppercase,
                    ),
                    const SizedBox(height: 4),
                    _buildRequirement('At least one number', _hasNumber),
                  ],
                  const SizedBox(height: 18),

                  // ── Confirm Password ────────────────────────────────────
                  _buildField(
                    label: 'Confirm Password',
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    controller: _confirmPasswordCtrl,
                    obscure: _obscureConfirm,
                    validator: (v) =>
                        AppValidators.confirmPassword(v, _passwordCtrl.text),
                  ),
                  const SizedBox(height: 32),

                  // ── Sign Up Button ──────────────────────────────────────
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
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
                          : Text(AppLocalizations.of(context).signUp),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── OR Divider ───────────────────────────────────────────
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

                  // ── Google Sign-In Button ────────────────────────────────
                  SizedBox(
                    height: 54,
                    child: OutlinedButton(
                      onPressed: _isGoogleLoading
                          ? null
                          : () async {
                              setState(() => _isGoogleLoading = true);
                              try {
                                final result =
                                    await AuthService.signInWithGoogle();
                                if (result != null && mounted) {
                                  if (context.mounted) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (_) => const HomePage(),
                                      ),
                                      (_) => false,
                                    );
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  _showSnackBar(
                                    'Google sign-in failed. Please try again.',
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isGoogleLoading = false);
                                }
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.fieldBorder,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        backgroundColor: AppColors.fieldBg,
                        foregroundColor: AppColors.titleColor,
                        elevation: 0,
                      ),
                      child: _isGoogleLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.fieldIcon,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Google "G" logo
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CustomPaint(
                                    painter: _GoogleLogoPainter(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  ).continueWithGoogle,
                                  style: GoogleFonts.cairo(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.titleColor,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Terms & Privacy ─────────────────────────────────────
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.termsText,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(
                            text: 'By signing up, you agree to our ',
                          ),
                          TextSpan(
                            text: 'Terms of Service',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.linkBrown,
                              decoration: TextDecoration.none,
                            ),
                            recognizer: TapGestureRecognizer()..onTap = () {},
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy\nPolicy',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.linkBrown,
                              decoration: TextDecoration.none,
                            ),
                            recognizer: TapGestureRecognizer()..onTap = () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Already have an account? ────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context).alreadyAccount,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: AppColors.termsText,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const SignInScreen(),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context).signIn,
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
    );
  }
}

/// Custom painter that draws the official multi-colour Google "G" logo.
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final greenPaint = Paint()..color = const Color(0xFF34A853);

    final center = Offset(w / 2, h / 2);
    final radius = w / 2;
    final strokeWidth = w * 0.2;

    // Blue – right arc (top-right to bottom-right)
    final blueArc = Paint()
      ..color = bluePaint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -0.6, // ~-34 degrees
      1.15, // ~66 degrees sweep
      false,
      blueArc,
    );

    // Green – bottom-right arc
    final greenArc = Paint()
      ..color = greenPaint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      0.55,
      1.0,
      false,
      greenArc,
    );

    // Yellow – bottom-left arc
    final yellowArc = Paint()
      ..color = yellowPaint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      1.55,
      1.0,
      false,
      yellowArc,
    );

    // Red – top-left arc
    final redArc = Paint()
      ..color = redPaint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      2.55,
      1.0,
      false,
      redArc,
    );

    // Blue horizontal bar (the crossbar of the G)
    canvas.drawRect(
      Rect.fromLTWH(w * 0.5, h * 0.4, w * 0.5, strokeWidth),
      bluePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
