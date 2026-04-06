import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart'; // palette constants
import '../services/auth_service.dart';
import 'sign_up_screen.dart';
import 'reset_password_screen.dart';
import 'home_page.dart';

// ── Design tokens matching the sign-up screen ───────────────────────────────
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

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscure = true;
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
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Sign-In Logic ─────────────────────────────────────────────────────────
  Future<void> _signIn() async {
    setState(() => _errorMsg = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

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
      if (mounted) {
        setState(() => _errorMsg = _friendlyError(e.code));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMsg = 'An unexpected error occurred.');
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
            color: _kLabelColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
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
                  const SizedBox(height: 40),

                  // ── Logo ──────────────────────────────────────────────
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.eco_rounded,
                        size: 56,
                        color: kPalmGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ── Title ─────────────────────────────────────────────
                  Text(
                    'WELCOME BACK',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _kTitleColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Email ─────────────────────────────────────────────
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

                  // ── Password ──────────────────────────────────────────
                  _buildField(
                    label: 'Password',
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    controller: _passwordCtrl,
                    obscure: _obscure,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: _kHintColor,
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
                      style: TextButton.styleFrom(foregroundColor: _kLinkBrown),
                      child: Text(
                        'Forgot Password?',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w600,
                          color: _kLinkBrown,
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
                          : const Text('Sign In'),
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
                                  setState(
                                    () => _errorMsg =
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
                  const SizedBox(height: 24),

                  // ── Switch to Sign Up ─────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: _kTermsText,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const SignUpScreen(),
                          ),
                        ),
                        child: Text(
                          'Sign Up',
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

    // Blue – right arc
    final blueArc = Paint()
      ..color = bluePaint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -0.6,
      1.15,
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
