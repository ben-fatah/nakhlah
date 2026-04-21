import 'dart:io';

void main() async {
  final file = File('C:/444/nakhlah/NakhlahApp/lib/screens/auth/otp_verification_screen.dart');
  var content = await file.readAsString();

  content = content.replaceAll('\\r\\n', '\\n');

  // Add shared_preferences import if missing
  if (!content.contains('package:shared_preferences/shared_preferences.dart')) {
    content = content.replaceFirst('import \\'dart:async\\';', 'import \\'dart:async\\';\\nimport \\'package:shared_preferences/shared_preferences.dart\\';');
  }

  final handleIdx = content.indexOf('  Future<void> _handleSuccessfulVerification');
  final resendIdx = content.indexOf('  // Resend timer');

  if (handleIdx == -1 || resendIdx == -1) {
    print('Error finding indices. \$handleIdx, \$resendIdx');
    return;
  }

  final newMethods = """
  Future<void> _handleSuccessfulVerification() async {
    try {
      final formattedPhone = _formatPhoneNumber(widget.phoneNumber);

      // Execute onVerified first if we have one (SignUp uses this to write the user doc)
      if (widget.onVerified != null) {
        await widget.onVerified!();
      }

      // Ensure Firebase Session. If standalone phone sign-in, login anonymously to read DB
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }

      // Query Firestore
      final userRepo = UserRepository();
      final appUser = await userRepo.getUserByPhone(formattedPhone);

      if (appUser != null) {
        // Prevent Mixups - update user provider directly
        userProvider.setCurrentUser(appUser);
        userProvider.setOtpVerified(true);

        // Session persistence
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isOtpVerified', true);
        await prefs.setString('verifiedPhone', formattedPhone);

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      } else {
        // User not found in DB! Show error. Cannot enter app.
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Account not found. Please sign up to create a profile.')),
           );
        }
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

  content = content.replaceRange(handleIdx, resendIdx, newMethods);
  await file.writeAsString(content);
  print('Success _handleSuccessfulVerification replaced.');
}
