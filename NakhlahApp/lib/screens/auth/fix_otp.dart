import 'dart:io';

void main() async {
  final file = File('C:/444/nakhlah/NakhlahApp/lib/screens/auth/otp_verification_screen.dart');
  var content = await file.readAsString();

  final sendIdx = content.indexOf('  Future<void> _sendOtp');
  final handleIdx = content.indexOf('  Future<void> _handleSuccessfulVerification');

  if (sendIdx == -1 || handleIdx == -1) {
    print('Error finding indices. \$sendIdx, \$handleIdx');
    return;
  }

  final newMethods = """
  String _formatPhoneNumber(String phone) {
    String p = phone.trim();
    if (p.startsWith('+966')) {
      p = p.substring(4);
    } else if (p.startsWith('00966')) {
      p = p.substring(5);
    } else if (p.startsWith('966')) {
      p = p.substring(3);
    } else if (p.startsWith('0')) {
      p = p.substring(1);
    }
    return '+966\$p';
  }

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

    final formattedPhone = _formatPhoneNumber(widget.phoneNumber);
    AppLogger.d('[OTP] Sending Authentica OTP to \$formattedPhone');

    try {
      final response = await _dio.post(
        'https://api.authentica.sa/api/otp/send',
        options: Options(headers: {
          'Authorization': 'Bearer \$_authenticaApiKey',
          'Content-Type': 'application/json',
        }),
        data: {
          'phone': formattedPhone,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        setState(() {
          _isSending = false;
        });
        _startResendTimer();
      } else {
        throw Exception('Failed to send OTP code');
      }
    } catch (e) {
      AppLogger.e('[OTP] sendOtp error: \$e');
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMsg = _friendlyVerificationError('network-request-failed');
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (!_otpComplete) return;

    setState(() {
      _isVerifying = true;
      _errorMsg = null;
    });

    final formattedPhone = _formatPhoneNumber(widget.phoneNumber);

    try {
      final response = await _dio.post(
        'https://api.authentica.sa/api/otp/verify',
        options: Options(headers: {
          'Authorization': 'Bearer \$_authenticaApiKey',
          'Content-Type': 'application/json',
        }),
        data: {
          'phone': formattedPhone,
          'code': _enteredOtp,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
         AppLogger.d('[OTP] Authentica Verified!');
         await _handleSuccessfulVerification();
      } else {
         throw Exception('Invalid Verification Code');
      }
    } catch (e) {
      AppLogger.e('[OTP] verifyOtp error: \$e');
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMsg = 'Incorrect code. Please check and try again.';
      });
    }
  }

""";

  content = content.replaceRange(sendIdx, handleIdx, newMethods);
  
  // Also cleanup the '6 digits' comment
  content = content.replaceAll('Auto-verify when all 6 digits entered', 'Auto-verify when all 4 digits entered');

  await file.writeAsString(content);
  print('Success!');
}
