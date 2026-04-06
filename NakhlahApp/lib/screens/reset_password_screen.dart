import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart'; // palette constants

// ── Design tokens matching sign-up / sign-in ────────────────────────────────
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

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // ── Form ──────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;

  // 60-second resend cooldown
  int _cooldown = 0;
  Timer? _timer;

  final _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ── Reset Logic ───────────────────────────────────────────────────────────
  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(email: _emailCtrl.text.trim());

      if (mounted) {
        setState(() {
          _emailSent = true;
          _cooldown = 60;
        });
        _startCooldown();
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('ResetPassword error — ${e.code}: ${e.message}');
      if (mounted) _showSnackBar(_friendlyError(e.code));
    } catch (e) {
      if (mounted) _showSnackBar('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startCooldown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_cooldown > 0) {
          _cooldown--;
        } else {
          t.cancel();
        }
      });
    });
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'invalid-email':
        return 'If this email is registered, a reset link has been sent.';
      case 'too-many-requests':
        return 'Too many requests. Please wait before trying again.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Could not send reset email ($code).';
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

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgCream,
      body: SafeArea(
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
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: _kTitleColor,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Header Icon ─────────────────────────────────────────
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _kFieldBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: _kFieldBorder, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      size: 40,
                      color: _kFieldIcon,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Title ───────────────────────────────────────────────
                Text(
                  'RESET PASSWORD',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _kTitleColor,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter your email and we'll send a reset link.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 14, color: _kTermsText),
                ),
                const SizedBox(height: 36),

                // ── Email Field ─────────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kLabelColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        color: _kTitleColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'example@mail.com',
                        hintStyle: GoogleFonts.cairo(
                          fontSize: 14,
                          color: _kHintColor,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 14, right: 10),
                          child: Icon(
                            Icons.email_outlined,
                            size: 20,
                            color: _kFieldIcon,
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 0,
                        ),
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
                          borderSide: BorderSide(
                            color: _kFieldIcon,
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
                  ],
                ),
                const SizedBox(height: 28),

                // ── Send Button ─────────────────────────────────────────
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _cooldown > 0)
                        ? null
                        : _sendResetEmail,
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
                        : Text(
                            _cooldown > 0
                                ? 'Resend in ${_cooldown}s'
                                : 'Send Reset Link',
                          ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Confirmation Banner ─────────────────────────────────
                if (_emailSent)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _kFieldIcon.withValues(alpha: 0.07),
                          _kLinkBrown.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _kFieldIcon.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.mark_email_read_outlined,
                          color: _kFieldIcon,
                          size: 36,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Reset link sent!',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: _kTitleColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Check your inbox at ${_emailCtrl.text.trim()}.\nThe link expires after 1 hour.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: _kTermsText,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // ── Back to Sign In ─────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Remember your password? ',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: _kTermsText,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
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
    );
  }
}
