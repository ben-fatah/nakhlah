import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/app_colors.dart';
import '../../core/logger.dart';
import '../../services/auth_service.dart';
import '../home_page.dart';

/// Screen that handles Firebase Phone Auth OTP verification.
///
/// Usage:
/// ```dart
/// Navigator.of(context).push(MaterialPageRoute(
///   builder: (_) => OtpVerificationScreen(phoneNumber: '+966501234567'),
/// ));
/// ```
///
/// [phoneNumber] must be in E.164 format (e.g. +966501234567).
/// [onVerified] optional callback invoked after successful Firebase verification
/// instead of the default push-to-HomePage behaviour (useful when called
/// from sign-up to continue profile creation).
class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  /// Called instead of pushing [HomePage] when verification succeeds.
  final VoidCallback? onVerified;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.onVerified,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  // ── Firebase Phone Auth ───────────────────────────────────────────────────
  final _auth = FirebaseAuth.instance;

  /// Verification ID received in [FirebaseAuth.verifyPhoneNumber] codeSent callback.
  String? _verificationId;

  /// Resend token to avoid duplicate SMS charges on retry.
  int? _resendToken;

  // ── OTP boxes — Firebase always sends 6-digit codes ───────────────────────
  static const int _otpLength = 6;
  final List<TextEditingController> _otpControllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  // ── State ─────────────────────────────────────────────────────────────────
  bool _isSending = true;    // true while Firebase initiates the phone auth
  bool _isVerifying = false;
  String? _errorMsg;

  // ── Resend countdown ──────────────────────────────────────────────────────
  static const int _resendSeconds = 60;
  int _secondsLeft = _resendSeconds;
  Timer? _resendTimer;

  // ── Animation ─────────────────────────────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeIn;

  // ── Helpers ───────────────────────────────────────────────────────────────
  String get _enteredOtp => _otpControllers.map((c) => c.text).join();
  bool get _otpComplete => _enteredOtp.length == _otpLength;

  // =========================================================================
  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    _sendOtp();
  }

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _resendTimer?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Firebase: send OTP ────────────────────────────────────────────────────

  Future<void> _sendOtp({bool isResend = false}) async {
    if (mounted) {
      setState(() {
        _isSending = true;
        _errorMsg = null;
      });
    }

    if (isResend) {
      for (final c in _otpControllers) {
        c.clear();
      }
      if (mounted) _focusNodes.first.requestFocus();
    }

    AppLogger.d('[OTP] Sending Firebase OTP to ${widget.phoneNumber}');

    await _auth.verifyPhoneNumber(
      phoneNumber: widget.phoneNumber,

      // ── Resend token: prevents duplicate SMS charges on retry ────────────
      forceResendingToken: isResend ? _resendToken : null,

      // ── Timeout: how long Firebase waits for auto-retrieval ──────────────
      timeout: const Duration(seconds: 60),

      // ── Android: SMS auto-retrieved, sign in immediately ─────────────────
      verificationCompleted: (PhoneAuthCredential credential) async {
        AppLogger.d('[OTP] Auto-verified (Android SMS retrieval)');
        await _signInWithCredential(credential);
      },

      // ── Verification failed (wrong number, quota, etc.) ───────────────────
      verificationFailed: (FirebaseAuthException e) {
        AppLogger.e('[OTP] verificationFailed: ${e.code} — ${e.message}');
        if (!mounted) return;
        setState(() {
          _isSending = false;
          _errorMsg = _friendlyVerificationError(e.code);
        });
      },

      // ── SMS sent — store verificationId + resendToken ────────────────────
      codeSent: (String verificationId, int? resendToken) {
        AppLogger.d('[OTP] codeSent — verificationId received');
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _isSending = false;
        });
        _startResendTimer();
        if (!isResend) _focusNodes.first.requestFocus();
      },

      // ── Auto-retrieval timeout (not an error; user enters manually) ───────
      codeAutoRetrievalTimeout: (String verificationId) {
        AppLogger.d('[OTP] codeAutoRetrievalTimeout');
        _verificationId ??= verificationId;
      },
    );
  }

  // ── Firebase: verify OTP ─────────────────────────────────────────────────

  Future<void> _verifyOtp() async {
    if (!_otpComplete || _verificationId == null) return;

    setState(() {
      _isVerifying = true;
      _errorMsg = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _enteredOtp,
      );
      await _signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      AppLogger.e('[OTP] verifyOtp FirebaseAuthException: ${e.code}');
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMsg = _friendlyVerifyError(e.code);
      });
    } catch (e, st) {
      AppLogger.e('[OTP] verifyOtp unexpected error', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMsg = 'Verification failed. Please try again.';
      });
    }
  }

  /// Signs into Firebase with [credential] and navigates on success.
  ///
  /// Handles both auto-verified (Android) and manual code entry paths.
  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      // If a user is already signed in (email/password created account first
      // during sign-up with phone), link the phone credential instead of
      // creating a new account.
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        AppLogger.d('[OTP] Linking phone credential to existing account');
        await currentUser.linkWithCredential(credential);
      } else {
        AppLogger.d('[OTP] Signing in with phone credential');
        await _auth.signInWithCredential(credential);
      }

      // Ensure Firestore user document is created / updated
      await AuthService.ensureUserDocument();

      AppLogger.d('[OTP] Firebase phone auth succeeded.');

      if (!mounted) return;

      if (widget.onVerified != null) {
        widget.onVerified!();
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (_) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.e('[OTP] signInWithCredential failed: ${e.code}');
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMsg = _friendlyVerifyError(e.code);
      });
    }
  }

  // ── Resend timer ──────────────────────────────────────────────────────────
  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          t.cancel();
        }
      });
    });
  }

  // ── Error helpers ─────────────────────────────────────────────────────────

  String _friendlyVerificationError(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'The phone number is invalid. Please go back and re-enter it.';
      case 'too-many-requests':
        return 'Too many OTP requests. Please wait a few minutes and try again.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Could not send OTP ($code). Please try again.';
    }
  }

  String _friendlyVerifyError(String code) {
    switch (code) {
      case 'invalid-verification-code':
        return 'Incorrect code. Please check and try again.';
      case 'session-expired':
        return 'The code has expired. Tap "Resend" to get a new one.';
      case 'credential-already-in-use':
        return 'This phone number is already linked to another account.';
      case 'provider-already-linked':
        return 'Phone number already linked to this account.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Verification failed ($code). Please try again.';
    }
  }

  // =========================================================================
  // UI
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.titleColor),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                // ── Icon ───────────────────────────────────────────────────
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.brown900.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sms_rounded,
                    size: 44,
                    color: AppColors.brown700,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Title ──────────────────────────────────────────────────
                Text(
                  'Enter Verification Code',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.titleColor,
                  ),
                ),
                const SizedBox(height: 10),

                // ── Subtitle ───────────────────────────────────────────────
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: AppColors.hintColor,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'A 6-digit code was sent to\n'),
                      TextSpan(
                        text: widget.phoneNumber,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w700,
                          color: AppColors.titleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // ── OTP Boxes or sending indicator ─────────────────────────
                if (_isSending)
                  Column(
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.brown700,
                        strokeWidth: 2.5,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sending verification code…',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: AppColors.hintColor,
                        ),
                      ),
                    ],
                  )
                else
                  _buildOtpBoxes(),

                const SizedBox(height: 32),

                // ── Error message ──────────────────────────────────────────
                if (_errorMsg != null) ...[
                  Container(
                    width: double.infinity,
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
                  const SizedBox(height: 20),
                ],

                // ── Verify Button ──────────────────────────────────────────
                if (!_isSending) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: (_otpComplete && !_isVerifying)
                          ? _verifyOtp
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonBg,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.buttonBg.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                        textStyle: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: _isVerifying
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('Verify'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Resend ─────────────────────────────────────────────
                  _buildResendRow(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── OTP digit boxes — 6 digits for Firebase ────────────────────────────────
  Widget _buildOtpBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_otpLength, (i) {
        return Container(
          width: 44,
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: TextFormField(
            controller: _otpControllers[i],
            focusNode: _focusNodes[i],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.titleColor,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: AppColors.fieldBg,
              contentPadding: EdgeInsets.zero,
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
                  color: AppColors.brown700,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade400),
              ),
            ),
            onChanged: (val) {
              if (val.length == 1 && i < _otpLength - 1) {
                _focusNodes[i + 1].requestFocus();
              } else if (val.isEmpty && i > 0) {
                _focusNodes[i - 1].requestFocus();
              }
              // Auto-verify when all 6 digits entered
              if (_otpComplete && !_isVerifying) {
                _verifyOtp();
              }
              setState(() {}); // refresh button state
            },
          ),
        );
      }),
    );
  }

  // ── Resend row ─────────────────────────────────────────────────────────────
  Widget _buildResendRow() {
    final canResend = _secondsLeft == 0 && !_isSending;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive a code? ",
          style: GoogleFonts.cairo(fontSize: 14, color: AppColors.hintColor),
        ),
        GestureDetector(
          onTap: canResend ? () => _sendOtp(isResend: true) : null,
          child: Text(
            canResend ? 'Resend' : 'Resend in ${_secondsLeft}s',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: canResend ? AppColors.linkBrown : AppColors.hintColor,
              decoration:
                  canResend ? TextDecoration.underline : TextDecoration.none,
              decorationColor: AppColors.linkBrown,
            ),
          ),
        ),
      ],
    );
  }
}
