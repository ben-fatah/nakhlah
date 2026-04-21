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

// ─────────────────────────────────────────────────────────────────────────────
// IMPORTANT: Replace these with your REAL Authentica credentials.
//
// How to get them:
//   1. Go to https://authentica.sa → Dashboard → API Keys
//   2. Copy your Bearer token (it looks like a long hash, NOT starting with $2y$)
//   3. Paste it below as _kApiKey
//
// The $2y$10$... string in the old code was a bcrypt HASH of a password,
// NOT an API key — that is why you were getting 404 / auth errors.
// ─────────────────────────────────────────────────────────────────────────────
const String _kAuthenticaApiKey =
    'YOUR_AUTHENTICA_API_KEY_HERE'; // ← Replace this!

const String _kSendEndpoint = 'https://api.authentica.sa/api/otp/send';
const String _kVerifyEndpoint = 'https://api.authentica.sa/api/otp/verify';

/// OTP Verification Screen — uses Authentica.sa SMS API only.
///
/// Firebase Phone Auth has been removed entirely.
/// Firebase is only used AFTER verification to look up the user in Firestore.
///
/// Usage:
/// ```dart
/// Navigator.of(context).push(MaterialPageRoute(
///   builder: (_) => OtpVerificationScreen(phoneNumber: '+966501234567'),
/// ));
/// ```
///
/// [phoneNumber] should be in E.164 format (+966XXXXXXXXX) or local
/// Saudi format (05XXXXXXXX) — both are normalised internally.
///
/// [onVerified] is an optional callback used by sign-up flow. When provided
/// it is called BEFORE the Firestore lookup so the sign-up screen can write
/// the new user document first. After it completes, the screen does the
/// normal Firestore lookup and navigates to HomePage.
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
  // ── OTP boxes (4-digit Authentica code) ───────────────────────────────────
  static const int _otpLength = 4;
  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  // ── State ─────────────────────────────────────────────────────────────────
  bool _isSending = true;
  bool _isVerifying = false;
  String? _errorMsg;

  // ── Resend countdown ──────────────────────────────────────────────────────
  static const int _resendCooldown = 60;
  int _secondsLeft = _resendCooldown;
  Timer? _resendTimer;

  // ── Fade animation ────────────────────────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeIn;

  // ── Dio ───────────────────────────────────────────────────────────────────
  late final Dio _dio;

  // ── Helpers ───────────────────────────────────────────────────────────────
  String get _enteredOtp => _controllers.map((c) => c.text).join();
  bool get _otpComplete => _enteredOtp.length == _otpLength;

  // ── Phone normalisation ───────────────────────────────────────────────────
  /// Always returns E.164 format: +966XXXXXXXXX
  String _normalisePhone(String raw) {
    String p = raw.trim().replaceAll(' ', '').replaceAll('-', '');
    if (p.startsWith('+966')) return p;
    if (p.startsWith('00966')) return '+966${p.substring(5)}';
    if (p.startsWith('966')) return '+966${p.substring(3)}';
    if (p.startsWith('0')) return '+966${p.substring(1)}';
    return '+966$p';
  }

  // =========================================================================
  @override
  void initState() {
    super.initState();

    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_kAuthenticaApiKey',
      },
    ));

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _sendOtp();
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _resendTimer?.cancel();
    _fadeCtrl.dispose();
    _dio.close();
    super.dispose();
  }

  // ── Send OTP ───────────────────────────────────────────────────────────────
  Future<void> _sendOtp({bool isResend = false}) async {
    if (!mounted) return;

    setState(() {
      _isSending = true;
      _errorMsg = null;
    });

    if (isResend) {
      for (final c in _controllers) c.clear();
      if (mounted) _focusNodes.first.requestFocus();
    }

    final phone = _normalisePhone(widget.phoneNumber);
    AppLogger.d('[OTP] Sending to $phone via Authentica...');

    // ── Guard: API key not set yet ────────────────────────────────────────
    if (_kAuthenticaApiKey == ''$2y$10$msQf48nCdkmu7pU9n0W9VOgw0pSrwSe7vD09ioaxTepB7i1A5AGte') {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMsg =
            'API key not configured.\n'
            'Open otp_verification_screen.dart and replace\n'
            '_kAuthenticaApiKey with your real Authentica token.';
      });
      AppLogger.e('[OTP] API key is still the placeholder — update _kAuthenticaApiKey');
      return;
    }

    try {
      final response = await _dio.post(
        _kSendEndpoint,
        data: jsonEncode({'phone': phone}),
      );

      AppLogger.d('[OTP] Send response: ${response.statusCode} ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        setState(() => _isSending = false);
        _fadeCtrl.forward();
        _startResendTimer();
      } else {
        _handleSendError(
          'Unexpected status ${response.statusCode}',
          response.data,
        );
      }
    } on DioException catch (e) {
      AppLogger.e('[OTP] DioException sending OTP: ${e.type} | ${e.response?.statusCode} | ${e.response?.data}');
      _handleSendError(_dioPrettyError(e), e.response?.data);
    } catch (e) {
      AppLogger.e('[OTP] Unknown error sending OTP: $e');
      _handleSendError('Unexpected error: $e', null);
    }
  }

  void _handleSendError(String msg, dynamic responseData) {
    if (!mounted) return;
    String display = msg;

    // Try to extract a human-readable message from the JSON response body
    if (responseData is Map) {
      final serverMsg =
          responseData['message'] ??
          responseData['error'] ??
          responseData['msg'];
      if (serverMsg != null) {
        display = '$msg\n(Server: $serverMsg)';
      }
    }

    setState(() {
      _isSending = false;
      _errorMsg = display;
    });
  }

  // ── Verify OTP ─────────────────────────────────────────────────────────────
  Future<void> _verifyOtp() async {
    if (!_otpComplete || _isVerifying) return;

    setState(() {
      _isVerifying = true;
      _errorMsg = null;
    });

    final phone = _normalisePhone(widget.phoneNumber);
    final code = _enteredOtp;

    AppLogger.d('[OTP] Verifying code $code for $phone...');

    try {
      final response = await _dio.post(
        _kVerifyEndpoint,
        data: jsonEncode({'phone': phone, 'code': code}),
      );

      AppLogger.d('[OTP] Verify response: ${response.statusCode} ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _onVerificationSuccess();
      } else {
        if (!mounted) return;
        setState(() {
          _isVerifying = false;
          _errorMsg = 'Incorrect code. Please try again.';
        });
      }
    } on DioException catch (e) {
      AppLogger.e('[OTP] DioException verifying OTP: ${e.type} | ${e.response?.statusCode} | ${e.response?.data}');
      final statusCode = e.response?.statusCode;
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMsg = statusCode == 400 || statusCode == 401 || statusCode == 422
            ? 'Incorrect code. Please try again.'
            : _dioPrettyError(e);
      });
    } catch (e) {
      AppLogger.e('[OTP] Unknown error verifying OTP: $e');
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMsg = 'Unexpected error: $e';
      });
    }
  }

  // ── After successful verification ──────────────────────────────────────────
  Future<void> _onVerificationSuccess() async {
    AppLogger.d('[OTP] Verification successful!');

    try {
      // Step 1: Run sign-up callback if provided (writes Firestore user doc)
      if (widget.onVerified != null) {
        AppLogger.d('[OTP] Running onVerified callback...');
        await widget.onVerified!();
      }

      // Step 2: Ensure a Firebase anonymous session exists so we can read
      // Firestore (Security Rules require auth). Uses existing session if any.
      if (FirebaseAuth.instance.currentUser == null) {
        AppLogger.d('[OTP] No Firebase session — signing in anonymously...');
        await FirebaseAuth.instance.signInAnonymously();
      }

      // Step 3: Look up the user document in Firestore by phone
      final phone = _normalisePhone(widget.phoneNumber);
      final userRepo = UserRepository();
      final appUser = await userRepo.getUserByPhone(phone);

      if (appUser != null) {
        AppLogger.d('[OTP] Found user: ${appUser.uid}');

        // Update in-memory state
        userProvider.setCurrentUser(appUser);
        userProvider.setOtpVerified(true);

        // Persist session so the app can restore it on cold start
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isOtpVerified', true);
        await prefs.setString('verifiedPhone', phone);

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (_) => false,
        );
      } else {
        // User completed OTP but has no Firestore document yet.
        // This can happen if the sign-up Firestore write failed.
        AppLogger.w('[OTP] No user found in Firestore for $phone');
        if (!mounted) return;
        setState(() {
          _isVerifying = false;
          _errorMsg =
              'Account not found. Please sign up first or try again.';
        });
      }
    } catch (e, st) {
      AppLogger.e('[OTP] Error in _onVerificationSuccess', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMsg = 'Sign-in error: $e';
      });
    }
  }

  // ── Resend timer ───────────────────────────────────────────────────────────
  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = _resendCooldown);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          t.cancel();
        }
      });
    });
  }

  // ── Dio error → human string ───────────────────────────────────────────────
  String _dioPrettyError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Check your internet connection.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401 || code == 403) {
          return 'API authentication failed (${code}). Check the API key in the app.';
        }
        if (code == 404) {
          return 'API endpoint not found (404). Check the Authentica API URL.';
        }
        if (code == 422) {
          return 'Invalid phone number format sent to server.';
        }
        if (code == 429) {
          return 'Too many requests. Please wait a few minutes.';
        }
        return 'Server error ($code). Please try again.';
      default:
        return 'Network error. Please check your connection.';
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // ── Icon ──────────────────────────────────────────────────────
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

              // ── Title ─────────────────────────────────────────────────────
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

              // ── Subtitle ──────────────────────────────────────────────────
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
                      text: _normalisePhone(widget.phoneNumber),
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                        color: AppColors.titleColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // ── Sending indicator or OTP boxes ────────────────────────────
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
                FadeTransition(
                  opacity: _fadeIn,
                  child: _buildOtpBoxes(),
                ),

              const SizedBox(height: 32),

              // ── Error message ─────────────────────────────────────────────
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Verify button & resend ─────────────────────────────────────
              if (!_isSending) ...[
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: (_otpComplete && !_isVerifying) ? _verifyOtp : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonBg,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.buttonBg.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
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
                        : Text(
                            'Verify',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildResendRow(),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── OTP digit boxes ────────────────────────────────────────────────────────
  Widget _buildOtpBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_otpLength, (i) {
        return Container(
          width: 56,
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: TextFormField(
            controller: _controllers[i],
            focusNode: _focusNodes[i],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: GoogleFonts.cairo(
              fontSize: 24,
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
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.fieldBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.fieldBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.brown700,
                  width: 2,
                ),
              ),
            ),
            onChanged: (val) {
              if (val.length == 1 && i < _otpLength - 1) {
                _focusNodes[i + 1].requestFocus();
              } else if (val.isEmpty && i > 0) {
                _focusNodes[i - 1].requestFocus();
              }
              setState(() {}); // refresh button state
              // Auto-verify when all 4 digits entered
              if (_otpComplete && !_isVerifying) {
                // Small delay so the last digit renders first
                Future.delayed(const Duration(milliseconds: 100), _verifyOtp);
              }
            },
          ),
        );
      }),
    );
  }

  // ── Resend row ─────────────────────────────────────────────────────────────
  Widget _buildResendRow() {
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