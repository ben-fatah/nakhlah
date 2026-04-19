import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../core/logger.dart';

/// Screen shown when the user taps the password-reset link from their email.
///
/// Accepts the Firebase `oobCode` extracted from the deep link.
/// Before rendering the form, it verifies the code is still valid via
/// [FirebaseAuth.verifyPasswordResetCode]. If the code is expired or already
/// used the screen shows an error state instead of the form.
class NewPasswordScreen extends StatefulWidget {
  /// The out-of-band code from the Firebase password-reset email.
  final String oobCode;

  const NewPasswordScreen({super.key, required this.oobCode});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen>
    with SingleTickerProviderStateMixin {
  // ── Form ──────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isVerifying = true; // shows spinner while verifying oobCode
  bool _codeValid = false; // true once verifyPasswordResetCode succeeds
  bool _resetDone = false; // true after confirmPasswordReset succeeds
  String? _verifyError; // non-null when oobCode verification fails
  String? _resetError; // non-null when confirmPasswordReset fails
  String? _verifiedEmail; // email associated with the reset code

  // ── Password strength tracking ────────────────────────────────────────────
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _passwordTouched = false;

  final _auth = FirebaseAuth.instance;

  // ── Animation ─────────────────────────────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _passwordCtrl.addListener(_evaluatePassword);
    _verifyCode();
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Step 1: Verify the oobCode before showing the form ────────────────────
  Future<void> _verifyCode() async {
    try {
      final email = await _auth.verifyPasswordResetCode(widget.oobCode);
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _codeValid = true;
          _verifiedEmail = email;
        });
        _fadeCtrl.forward();
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.e('[NewPassword] verifyPasswordResetCode failed: ${e.code}');
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _codeValid = false;
          _verifyError = _friendlyVerifyError(e.code);
        });
      }
    } catch (e) {
      AppLogger.e('[NewPassword] verifyPasswordResetCode error: $e');
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _codeValid = false;
          _verifyError = 'Something went wrong. Please try again.';
        });
      }
    }
  }

  // ── Step 2: Confirm the new password ──────────────────────────────────────
  Future<void> _confirmReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _resetError = null;
    });

    try {
      await _auth.confirmPasswordReset(
        code: widget.oobCode,
        newPassword: _passwordCtrl.text.trim(),
      );

      AppLogger.d('[NewPassword] Password reset successful');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _resetDone = true;
        });
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.e('[NewPassword] confirmPasswordReset failed: ${e.code}');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _resetError = _friendlyResetError(e.code);
        });
      }
    } catch (e) {
      AppLogger.e('[NewPassword] confirmPasswordReset error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _resetError = 'Something went wrong. Please try again.';
        });
      }
    }
  }

  // ── Password evaluation ───────────────────────────────────────────────────
  void _evaluatePassword() {
    final pwd = _passwordCtrl.text;
    setState(() {
      _passwordTouched = pwd.isNotEmpty;
      _hasMinLength = pwd.length >= 8;
      _hasUppercase = pwd.contains(RegExp(r'[A-Z]'));
      _hasNumber = pwd.contains(RegExp(r'[0-9]'));
    });
  }

  /// Whether all password requirements are met (used to enable/disable submit).
  bool get _allRequirementsMet =>
      _hasMinLength &&
      _hasUppercase &&
      _hasNumber &&
      _confirmCtrl.text == _passwordCtrl.text &&
      _confirmCtrl.text.isNotEmpty;

  // ── Error mappers ─────────────────────────────────────────────────────────
  String _friendlyVerifyError(String code) {
    switch (code) {
      case 'expired-action-code':
        return 'This reset link has expired.\nPlease request a new one.';
      case 'invalid-action-code':
        return 'This reset link is invalid or has already been used.\nPlease request a new one.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found for this link.';
      default:
        return 'Could not verify the reset link ($code).';
    }
  }

  String _friendlyResetError(String code) {
    switch (code) {
      case 'expired-action-code':
        return 'This reset link has expired. Please request a new one.';
      case 'invalid-action-code':
        return 'This reset link has already been used.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      default:
        return 'Could not reset password ($code).';
    }
  }

  // ── Reusable widgets ──────────────────────────────────────────────────────
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

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
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
          style: GoogleFonts.cairo(fontSize: 15, color: AppColors.titleColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.cairo(
              fontSize: 14,
              color: AppColors.hintColor,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 20,
                color: AppColors.fieldIcon,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 0,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.hintColor,
                size: 20,
              ),
              onPressed: onToggle,
            ),
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
        ),
      ],
    );
  }

  // ── UI Variants ───────────────────────────────────────────────────────────

  /// Loading spinner while verifying oobCode.
  Widget _buildVerifyingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.fieldBg,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.fieldBorder, width: 1.5),
            ),
            child: const Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  color: AppColors.fieldIcon,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Verifying reset link...',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.titleColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Error state when oobCode is expired / invalid.
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red.shade200, width: 1.5),
            ),
            child: Icon(
              Icons.link_off_rounded,
              size: 40,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Link Invalid',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.titleColor,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _verifyError!,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppColors.termsText,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonBg,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
                textStyle: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Back to Sign In'),
            ),
          ),
        ],
      ),
    );
  }

  /// Success state after password has been changed.
  Widget _buildSuccessState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 44,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Password Changed!',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.titleColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your password has been updated successfully.\nYou can now sign in with your new password.',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: AppColors.termsText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Pop everything back to sign-in
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonBg,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
                textStyle: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Go to Sign In'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Main UI ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // ── Back Arrow ──────────────────────────────────────────────
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
              const SizedBox(height: 40),

              // ── Dynamic content based on state ──────────────────────────
              if (_isVerifying)
                _buildVerifyingState()
              else if (!_codeValid)
                _buildErrorState()
              else if (_resetDone)
                _buildSuccessState()
              else
                _buildFormState(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// The new-password form (shown only when oobCode is valid).
  Widget _buildFormState() {
    return FadeTransition(
      opacity: _fadeIn,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header Icon ─────────────────────────────────────────────
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.fieldBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.fieldBorder, width: 1.5),
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  size: 40,
                  color: AppColors.fieldIcon,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Title ───────────────────────────────────────────────────
            Text(
              'NEW PASSWORD',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a new password for\n${_verifiedEmail ?? 'your account'}',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppColors.termsText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // ── New Password Field ──────────────────────────────────────
            _buildPasswordField(
              label: 'New Password',
              hint: '••••••••',
              controller: _passwordCtrl,
              obscure: _obscurePassword,
              onToggle: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),

            // ── Password requirements checklist ─────────────────────────
            if (_passwordTouched) ...[
              const SizedBox(height: 12),
              _buildRequirement('At least 8 characters', _hasMinLength),
              const SizedBox(height: 4),
              _buildRequirement('At least one capital letter', _hasUppercase),
              const SizedBox(height: 4),
              _buildRequirement('At least one number', _hasNumber),
            ],
            const SizedBox(height: 20),

            // ── Confirm Password Field ──────────────────────────────────
            _buildPasswordField(
              label: 'Confirm Password',
              hint: '••••••••',
              controller: _confirmCtrl,
              obscure: _obscureConfirm,
              onToggle: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            const SizedBox(height: 28),

            // ── Inline Error ────────────────────────────────────────────
            if (_resetError != null) ...[
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
                        _resetError!,
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

            // ── Submit Button ───────────────────────────────────────────
            SizedBox(
              height: 54,
              child: AnimatedBuilder(
                animation: Listenable.merge([_passwordCtrl, _confirmCtrl]),
                builder: (context, child) {
                  final enabled = !_isLoading && _allRequirementsMet;
                  return ElevatedButton(
                    onPressed: enabled ? _confirmReset : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonBg,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.buttonBg.withValues(
                        alpha: 0.4,
                      ),
                      disabledForegroundColor: Colors.white.withValues(
                        alpha: 0.6,
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
                        : const Text('Confirm New Password'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
