import 'dart:io';

void main() async {
  final file = File('C:/444/nakhlah/NakhlahApp/lib/screens/sign_up_screen.dart');
  var content = await file.readAsString();

  // Normalize line endings for regex and search
  content = content.replaceAll('\\r\\n', '\\n');

  final homePageNav = '''
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomePage()),
                  (_) => false,
                );
              }''';
  if (content.contains(homePageNav)) {
    content = content.replaceFirst(homePageNav, '');
    print('homePageNav removed.');
  }

  // Remove _signUp logic block
  final signUpIdx = content.indexOf('  Future<void> _signUp() async {');
  final phoneSignUpIdx = content.indexOf('  Future<void> _signUpWithPhone() async {');
  if (signUpIdx != -1 && phoneSignUpIdx != -1) {
    // Find previous comment
    final startIdx = content.lastIndexOf('//', signUpIdx);
    content = content.replaceRange(startIdx == -1 ? signUpIdx : startIdx, phoneSignUpIdx, '');
    print('_signUp method removed.');
  }

  // Remove skip phone verification button
  final skipRegex = RegExp(r'\s*//[^\n]+Skip phone verification[^\n]+\n.*?const SizedBox\(height: 20\),', dotAll: true);
  if (skipRegex.hasMatch(content)) {
    content = content.replaceFirst(skipRegex, '');
    print('Skip button logic removed.');
  }

  await file.writeAsString(content);
}
