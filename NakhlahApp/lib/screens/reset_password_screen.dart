import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../core/logger.dart';
import '../core/validators.dart';

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
      await _auth.sendPasswordResetEmail(
        email: _emailCtrl.text.trim(),
        actionCodeSettings: ActionCodeSettings(
          url: 'https://nakhlah-c5a65.firebaseapp.com',
          handleCodeInApp: true,
          androidPackageName: 'com.example.nakhlah',
          androidInstallApp: true,
          androidMinimumVersion: '1',
        ),
      );

      if (mounted) {
        setState(() {
          _emailSent = true;
          _cooldown = 60;
        });
        _startCooldown();
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.e('ResetPassword error — ${e.code}');
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
      backgroundColor: AppColors.bgCream,
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
                      color: AppColors.titleColor,
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
                      color: AppColors.fieldBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.fieldBorder,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      size: 40,
                      color: AppColors.fieldIcon,
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
                    color: AppColors.titleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter your email and we'll send a reset link.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: AppColors.termsText,
                  ),
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
                        color: AppColors.labelColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        color: AppColors.titleColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'example@mail.com',
                        hintStyle: GoogleFonts.cairo(
                          fontSize: 14,
                          color: AppColors.hintColor,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 14, right: 10),
                          child: Icon(
                            Icons.email_outlined,
                            size: 20,
                            color: AppColors.fieldIcon,
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 0,
                        ),
                        filled: true,
                        fillColor: AppColors.fieldBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.fieldBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.fieldBorder,
                          ),
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
                      validator: AppValidators.email,
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
                          AppColors.fieldIcon.withValues(alpha: 0.07),
                          AppColors.linkBrown.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.fieldIcon.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.mark_email_read_outlined,
                          color: AppColors.fieldIcon,
                          size: 36,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Reset link sent!',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.titleColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Check your inbox at ${_emailCtrl.text.trim()}.\nClick the link to set your new password.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: AppColors.termsText,
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
                        color: AppColors.termsText,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Text(
                        'Sign In',
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
    );
  }
}
