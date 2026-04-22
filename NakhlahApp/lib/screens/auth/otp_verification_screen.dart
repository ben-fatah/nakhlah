import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_colors.dart';
import '../../core/logger.dart';
import '../home_page.dart';
import '../../repositories/user_repository.dart';
import '../../providers/user_provider.dart';

// =============================================================================
// AUTHENTICA API — CONFIRMED CONFIGURATION
//
// Authentica support confirmed:
//   • The $2y$10$... string IS your real API key (bcrypt-style tokens).
//   • Header: X-Authorization: <raw_key>   (no "Bearer" prefix)
//   • Base:   https://api.authentica.sa/api/v2/
//
// Send OTP   → POST /api/v2/send-otp
//   body: { "method": "sms", "phone": "+966XXXXXXXXX", "template_id": 1 }
//
// Verify OTP → POST /api/v2/verify-otp
//   body: { "phone": "+966XXXXXXXXX", "otp": "<user-entered-code>" }
//
// Template IDs (Authentica default sender):
//   1 = Arabic OTP message
//   2 = English OTP message
//   Templates 1 & 2 send a 4-digit OTP.
// =============================================================================

/// Your Authentica API key — confirmed by support that $2y$10$... IS the key.
/// Raw string literal (r'...') prevents Dart from interpreting the $ signs.
const String _kApiKey =
    r'$2y$10$kRb06pu7yKhrIp2xgFDKDuZSa.2bOoalH8XbGcuMde2YVRJVhJ1si';

const String _kSendUrl   = 'https://api.authentica.sa/api/v2/send-otp';
const String _kVerifyUrl = 'https://api.authentica.sa/api/v2/verify-otp';

/// Template 1 = Arabic SMS (4-digit OTP, Authentica default sender)
const int _kTemplateId = 1;

/// Authentica templates 1 & 2 send 4-digit OTPs
const int _kOtpLength = 4;

// =============================================================================

/// OTP Verification Screen — Authentica SMS API v2
///
/// [phoneNumber] : Saudi format (05XXXXXXXX) or E.164 (+966XXXXXXXXX)
/// [onVerified]  : optional async callback fired right after OTP succeeds
///                 (used by sign-up to write the Firestore user doc first)
class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final Future<void> Function()? onVerified;

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
  // ── OTP digit controllers & focus nodes ────────────────────────────────────
  final List<TextEditingController> _controllers =
      List.generate(_kOtpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_kOtpLength, (_) => FocusNode());

  // ── Screen state ───────────────────────────────────────────────────────────
  bool    _isSending   = true;   // true while waiting for send-otp response
  bool    _isVerifying = false;  // true while waiting for verify-otp response
  String? _errorMsg;             // shown in red banner when non-null

  // ── Resend countdown ───────────────────────────────────────────────────────
  static const int _cooldownSec = 60;
  int    _secondsLeft = _cooldownSec;
  Timer? _countdownTimer;

  // ── Fade-in animation for OTP boxes ───────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  // ── Dio client (headers set once in initState) ────────────────────────────
  late final Dio _dio;

  // ── Computed helpers ───────────────────────────────────────────────────────
  String get _enteredOtp  => _controllers.map((c) => c.text).join();
  bool   get _otpComplete => _enteredOtp.length == _kOtpLength;

  /// Convert any Saudi phone format → E.164: +966XXXXXXXXX
  String _e164(String raw) {
    final p = raw.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (p.startsWith('+966'))  return p;
    if (p.startsWith('00966')) return '+966${p.substring(5)}';
    if (p.startsWith('966'))   return '+966${p.substring(3)}';
    if (p.startsWith('0'))     return '+966${p.substring(1)}';
    return '+966$p';
  }

  // ==========================================================================
  @override
  void initState() {
    super.initState();

    // Build Dio with Authentica-required headers set globally
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'X-Authorization': _kApiKey,        // confirmed correct header name
          'Accept'         : 'application/json',
          'Content-Type'   : 'application/json',
        },
      ),
    );

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    // Send the OTP immediately when the screen opens
    _sendOtp();
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes)  f.dispose();
    _countdownTimer?.cancel();
    _fadeCtrl.dispose();
    _dio.close(force: false);
    super.dispose();
  }

  // ==========================================================================
  // SEND OTP  →  POST /api/v2/send-otp
  // ==========================================================================
  Future<void> _sendOtp({bool isResend = false}) async {
    if (!mounted) return;

    setState(() {
      _isSending = true;
      _errorMsg  = null;
    });

    if (isResend) {
      for (final c in _controllers) c.clear();
      // Move focus to first box after the frame is drawn
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNodes.first.requestFocus();
      });
    }

    final phone = _e164(widget.phoneNumber);
    AppLogger.d('[Authentica] Sending OTP to $phone (template_id=$_kTemplateId)');

    try {
      final response = await _dio.post(
        _kSendUrl,
        data: jsonEncode({
          'method'     : 'sms',
          'phone'      : phone,
          'template_id': _kTemplateId,
        }),
      );

      AppLogger.d('[Authentica] send-otp → ${response.statusCode} ${response.data}');

      if ((response.statusCode ?? 0) ~/ 100 == 2) {
        // Any 2xx = success
        if (!mounted) return;
        setState(() => _isSending = false);
        _fadeCtrl.forward();
        _startCountdown();
      } else {
        _showSendError(
          'Unexpected status ${response.statusCode}',
          response.data,
        );
      }
    } on DioException catch (e) {
      AppLogger.e('[Authentica] send-otp DioException: '
          '${e.type} status=${e.response?.statusCode} '
          'body=${e.response?.data}');
      _showSendError(_humanError(e), e.response?.data);
    } catch (e, st) {
      AppLogger.e('[Authentica] send-otp unknown error', error: e, stackTrace: st);
      _showSendError('Unexpected error: $e', null);
    }
  }

  void _showSendError(String base, dynamic body) {
    if (!mounted) return;
    final extra = _serverMsg(body);
    setState(() {
      _isSending = false;
      _errorMsg  = extra.isNotEmpty ? '$base\nServer said: $extra' : base;
    });
  }

  // ==========================================================================
  // VERIFY OTP  →  POST /api/v2/verify-otp
  // ==========================================================================
  Future<void> _verifyOtp() async {
    if (!_otpComplete || _isVerifying || !mounted) return;

    setState(() {
      _isVerifying = true;
      _errorMsg    = null;
    });

    final phone = _e164(widget.phoneNumber);
    final otp   = _enteredOtp;
    AppLogger.d('[Authentica] Verifying OTP "$otp" for $phone');

    try {
      final response = await _dio.post(
        _kVerifyUrl,
        data: jsonEncode({
          'phone': phone,
          'otp'  : otp,
        }),
      );

      AppLogger.d('[Authentica] verify-otp → ${response.statusCode} ${response.data}');

      if ((response.statusCode ?? 0) ~/ 100 == 2) {
        // Any 2xx = OTP correct
        await _postVerifyFlow();
      } else {
        if (!mounted) return;
        setState(() {
          _isVerifying = false;
          _errorMsg    = 'Incorrect code. Please try again.';
        });
      }
    } on DioException catch (e) {
      AppLogger.e('[Authentica] verify-otp DioException: '
          '${e.type} status=${e.response?.statusCode} '
          'body=${e.response?.data}');
      final code = e.response?.statusCode ?? 0;
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        // 4xx for wrong code, network errors get a friendly message
        _errorMsg = (code >= 400 && code < 500)
            ? 'Incorrect code. Please try again.'
            : _humanError(e);
      });
    } catch (e, st) {
      AppLogger.e('[Authentica] verify-otp unknown error', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMsg    = 'Unexpected error: $e';
      });
    }
  }

  // ==========================================================================
  // POST-VERIFICATION FLOW
  // ==========================================================================
  Future<void> _postVerifyFlow() async {
    AppLogger.d('[OTP] Verified ✓ — running post-verify flow');

    try {
      // 1. Sign-up callback: write Firestore user doc before we look it up
      if (widget.onVerified != null) {
        AppLogger.d('[OTP] Calling onVerified callback...');
        await widget.onVerified!();
      }

      // 2. Ensure a Firebase session exists (needed for Firestore rules)
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
        AppLogger.d('[OTP] Anonymous Firebase session created');
      }

      // 3. Look up user Firestore document by phone
      final phone   = _e164(widget.phoneNumber);
      final appUser = await UserRepository().getUserByPhone(phone);

      if (appUser != null) {
        AppLogger.d('[OTP] Firestore user found: ${appUser.uid}');

        // Update in-memory state
        userProvider.setCurrentUser(appUser);
        userProvider.setOtpVerified(true);

        // Persist session so cold restarts don't require re-login
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isOtpVerified', true);
        await prefs.setString('verifiedPhone', phone);

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (_) => false,
        );
      } else {
        AppLogger.w('[OTP] No Firestore user for $phone');
        if (!mounted) return;
        setState(() {
          _isVerifying = false;
          _errorMsg    =
              'Account not found. Please sign up first or try again.';
        });
      }
    } catch (e, st) {
      AppLogger.e('[OTP] Post-verify error', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMsg    = 'Sign-in error: $e';
      });
    }
  }

  // ==========================================================================
  // UTILITY HELPERS
  // ==========================================================================

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _secondsLeft = _cooldownSec);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _secondsLeft > 0 ? _secondsLeft-- : t.cancel();
      });
    });
  }

  /// Extract the most useful text from an Authentica error response body.
  String _serverMsg(dynamic body) {
    if (body == null) return '';
    if (body is String) {
      try {
        return _serverMsg(jsonDecode(body));
      } catch (_) {
        return body.isNotEmpty ? body : '';
      }
    }
    if (body is Map) {
      final v = body['message'] ?? body['error'] ??
                body['msg']     ?? body['errors'];
      if (v is List) return v.join(', ');
      return v?.toString() ?? '';
    }
    return '';
  }

  /// Map Dio network errors → friendly user-facing strings.
  String _humanError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Please check your internet and try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode ?? 0;
        final hint = _serverMsg(e.response?.data);
        if (code == 401 || code == 403) {
          return 'API authentication failed ($code).'
              '${hint.isNotEmpty ? "\nServer: $hint" : ""}';
        }
        if (code == 429) {
          return 'Too many OTP requests. Please wait a few minutes.';
        }
        return 'Server error ($code). Please try again.'
            '${hint.isNotEmpty ? "\nServer: $hint" : ""}';
      default:
        return 'Network error. Please check your connection.';
    }
  }

  // ==========================================================================
  // UI
  // ==========================================================================
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // ── Phone icon ───────────────────────────────────────────────
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

              // ── Title ────────────────────────────────────────────────────
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

              // ── Subtitle ─────────────────────────────────────────────────
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: AppColors.hintColor,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'A 4-digit code was sent to\n'),
                    TextSpan(
                      text: _e164(widget.phoneNumber),
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                        color: AppColors.titleColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // ── Spinner OR OTP boxes ─────────────────────────────────────
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
                FadeTransition(opacity: _fadeAnim, child: _otpRow()),

              const SizedBox(height: 32),

              // ── Error banner ─────────────────────────────────────────────
              if (_errorMsg != null) ...[
                _errorBanner(),
                const SizedBox(height: 16),
              ],

              // ── Verify button + resend ───────────────────────────────────
              if (!_isSending) ...[
                _verifyButton(),
                const SizedBox(height: 24),
                _resendRow(),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── 4 OTP digit boxes ──────────────────────────────────────────────────────
  Widget _otpRow() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_kOtpLength, _otpBox),
      );

  Widget _otpBox(int i) => Container(
        width: 62,
        height: 72,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Focus(
          onKeyEvent: (_, event) {
            // Backspace on empty box → go to previous box
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.backspace &&
                _controllers[i].text.isEmpty &&
                i > 0) {
              _controllers[i - 1].clear();
              _focusNodes[i - 1].requestFocus();
              setState(() {});
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: TextFormField(
            controller:     _controllers[i],
            focusNode:      _focusNodes[i],
            textAlign:      TextAlign.center,
            keyboardType:   TextInputType.number,
            maxLength:      1,
            style: GoogleFonts.cairo(
              fontSize:   26,
              fontWeight: FontWeight.w800,
              color:      AppColors.titleColor,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText:    '',
              filled:         true,
              fillColor:      AppColors.fieldBg,
              contentPadding: EdgeInsets.zero,
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
                borderSide: const BorderSide(color: AppColors.brown700, width: 2.5),
              ),
            ),
            onChanged: (val) {
              if (val.length == 1 && i < _kOtpLength - 1) {
                _focusNodes[i + 1].requestFocus();
              }
              setState(() {}); // refresh button enabled/disabled state

              // Auto-verify once all boxes are filled
              if (_otpComplete && !_isVerifying) {
                Future.delayed(const Duration(milliseconds: 150), _verifyOtp);
              }
            },
          ),
        ),
      );

  // ── Error banner ───────────────────────────────────────────────────────────
  Widget _errorBanner() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:        Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded,
                color: Colors.red.shade700, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _errorMsg!,
                style: GoogleFonts.cairo(
                  color:  Colors.red.shade700,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      );

  // ── Verify button ──────────────────────────────────────────────────────────
  Widget _verifyButton() => SizedBox(
        width:  double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: (_otpComplete && !_isVerifying) ? _verifyOtp : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.buttonBg,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.buttonBg.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 0,
          ),
          child: _isVerifying
              ? const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'Verify',
                  style: GoogleFonts.cairo(
                    fontSize: 16, fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      );

  // ── Resend row ─────────────────────────────────────────────────────────────
  Widget _resendRow() {
    final canResend = _secondsLeft == 0 && !_isSending && !_isVerifying;
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
              fontSize:   14,
              fontWeight: FontWeight.w700,
              color:      canResend ? AppColors.linkBrown : AppColors.hintColor,
              decoration: canResend
                  ? TextDecoration.underline
                  : TextDecoration.none,
              decorationColor: AppColors.linkBrown,
            ),
          ),
        ),
      ],
    );
  }
}