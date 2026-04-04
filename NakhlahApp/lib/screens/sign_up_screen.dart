import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart'; // palette constants
import '../services/auth_service.dart';
import 'sign_in_screen.dart';
import 'home_page.dart';

// ── Design tokens for the sign-up screen ────────────────────────────────────
const Color _kBgCream = Color(0xFFFAF6F1);
const Color _kFieldBg = Color(0xFFFFFDFA);
const Color _kFieldBorder = Color(0xFFE8E0D6);
const Color _kFieldIcon = Color(0xFF8B7355);
const Color _kLabelColor = Color(0xFF5C4A3A);
const Color _kHintColor = Color(0xFFBDB0A3);
const Color _kTitleColor = Color(0xFF3E2C1F);
const Color _kButtonBg = Color(0xFF4A3728);
const Color _kLinkBrown = Color(0xFF6B4F3A);
const Color _kTermsText = Color(0xFF9E8E7E);

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
  bool _obscureConfirm = true;

  // ── Password-strength tracking ───────────────────────────────────────────
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _passwordTouched = false;

  // ── Firebase ──────────────────────────────────────────────────────────────
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

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

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'fullName': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (_) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'FirebaseAuthException — code: ${e.code} | message: ${e.message}',
      );
      if (mounted) _showSnackBar(e.message ?? 'Sign-up failed (${e.code}).');
    } catch (e, st) {
      debugPrint('Unexpected sign-up error: $e\n$st');
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
            color: _kLabelColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: GoogleFonts.cairo(fontSize: 15, color: _kTitleColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.cairo(fontSize: 14, color: _kHintColor),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(icon, size: 20, color: _kFieldIcon),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 0,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: _kFieldBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _kFieldBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _kFieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _kFieldIcon, width: 1.5),
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
      backgroundColor: _kBgCream,
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
                        color: _kTitleColor,
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
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.eco_rounded,
                        size: 56,
                        color: kPalmGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ── Title ───────────────────────────────────────────────
                  Text(
                    'CREATE ACCOUNT',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _kTitleColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Full Name ───────────────────────────────────────────
                  _buildField(
                    label: 'Full Name',
                    hint: 'Ali Al-Otaibi',
                    icon: Icons.person_outline_rounded,
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required.'
                        : null,
                  ),
                  const SizedBox(height: 18),

                  // ── Email ───────────────────────────────────────────────
                  _buildField(
                    label: 'Email',
                    hint: 'example@mail.com',
                    icon: Icons.email_outlined,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email is required.';
                      }
                      if (!RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(v.trim())) {
                        return 'Enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // ── Password ────────────────────────────────────────────
                  _buildField(
                    label: 'Password',
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    controller: _passwordCtrl,
                    obscure: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: _kHintColor,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Password is required.';
                      }
                      if (v.length < 8) {
                        return 'Must be at least 8 characters.';
                      }
                      if (!v.contains(RegExp(r'[A-Z]'))) {
                        return 'Must contain at least one capital letter.';
                      }
                      if (!v.contains(RegExp(r'[0-9]'))) {
                        return 'Must contain at least one number.';
                      }
                      return null;
                    },
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
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Please confirm your password.';
                      }
                      if (v != _passwordCtrl.text) {
                        return 'Passwords do not match.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // ── Sign Up Button ──────────────────────────────────────
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kButtonBg,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _kButtonBg.withValues(
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
                          : const Text('Sign Up'),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── OR Divider ───────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: _kFieldBorder, thickness: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kHintColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: _kFieldBorder, thickness: 1),
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
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (_) => const HomePage(),
                                    ),
                                    (_) => false,
                                  );
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
                        side: BorderSide(color: _kFieldBorder, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        backgroundColor: _kFieldBg,
                        foregroundColor: _kTitleColor,
                        elevation: 0,
                      ),
                      child: _isGoogleLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: _kFieldIcon,
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
                                  'Continue with Google',
                                  style: GoogleFonts.cairo(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _kTitleColor,
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
                          color: _kTermsText,
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
                              color: _kLinkBrown,
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
                              color: _kLinkBrown,
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
                        'Already have an account? ',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: _kTermsText,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const SignInScreen(),
                          ),
                        ),
                        child: Text(
                          'Sign In',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _kTitleColor,
                            decoration: TextDecoration.underline,
                            decorationColor: _kTitleColor,
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
