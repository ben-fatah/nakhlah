/// Centralized form validators for the Nakhlah application.
///
/// Each method returns `null` when valid or an error message `String` when
/// invalid — matching the Flutter [FormField.validator] signature.
abstract final class AppValidators {
  /// Validates an email address.
  ///
  /// Returns an error if the value is empty or does not match a basic
  /// email format (anything@anything.anything).
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return 'Invalid email format';
    }
    return null;
  }

  /// Validates a password.
  ///
  /// Requirements:
  /// - At least 8 characters
  /// - At least one uppercase letter
  /// - At least one number
  /// - At least one special character
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 8) {
      return 'Must be at least 8 characters.';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Must contain at least one capital letter.';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Must contain at least one number.';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Must contain at least one special character.';
    }
    return null;
  }

  /// Validates a full name.
  ///
  /// Requires at least 3 characters.
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required.';
    }
    if (value.trim().length < 3) {
      return 'Name must be at least 3 characters.';
    }
    return null;
  }

  /// Validates a Saudi phone number.
  ///
  /// Accepts formats like `05xxxxxxxx` (10 digits starting with 05).
  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required.';
    }
    if (!RegExp(r'^05\d{8}$').hasMatch(value.trim())) {
      return 'Enter a valid Saudi phone number (05xxxxxxxx).';
    }
    return null;
  }

  /// Validates a store name.
  static String? storeName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Store name is required.';
    }
    return null;
  }

  /// Validates that a confirmation password matches the original.
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != password) {
      return 'Passwords do not match.';
    }
    return null;
  }
}
