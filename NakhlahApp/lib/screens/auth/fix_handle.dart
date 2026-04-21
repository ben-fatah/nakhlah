import 'dart:io';

void main() async {
  final file = File('C:/444/nakhlah/NakhlahApp/lib/screens/auth/otp_verification_screen.dart');
  var content = await file.readAsString();

  final handleIdx = content.indexOf('  Future<void> _handleSuccessfulVerification');
  final resendIdx = content.indexOf('  void _startResendTimer');

  if (handleIdx == -1 || resendIdx == -1) {
    print('Error finding indices. \$handleIdx, \$resendIdx');
    return;
  }

  final newMethods = """
  Future<void> _handleSuccessfulVerification() async {
    try {
      if (widget.onVerified != null) {
        await widget.onVerified!();
      } else {
        AppLogger.d('Finding user by phone: \${widget.phoneNumber}');
        
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      AppLogger.e('Error handling successful verification: \$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: \$e')),
        );
      }
    }
  }

""";

  final replacement = newMethods + "  // Resend timer\\n";
  content = content.replaceRange(handleIdx, resendIdx, replacement);

  // Clean trailing garbage after _startResendTimer
  content = content.replaceAll(RegExp(r'\}[\u0080-\uFFFF]+\s*String _friendly'), '}\\n\\n  String _friendly');

  await file.writeAsString(content);
  print('Success!');
}
