/// Form-field validators shared across the app.
///
/// Each returns `null` when valid or a friendly error string otherwise, matching
/// the `FormFieldValidator<String>` contract.
abstract final class Validators {
  const Validators._();

  /// Jamaican mobile numbers in E.164: +1876XXXXXXX or +1658XXXXXXX (11 digits
  /// after the +1). We accept common human formats and normalise before checking.
  static String? jamaicanPhone(String? raw) {
    final String value = (raw ?? '').trim();
    if (value.isEmpty) return 'Enter yuh phone number';
    final String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final String national = digits.startsWith('1') ? digits.substring(1) : digits;
    if (national.length != 10) return 'Use a valid 10-digit number';
    if (!RegExp(r'^(876|658)').hasMatch(national)) {
      return 'Use a Jamaican number (876 or 658)';
    }
    return null;
  }

  /// Delivery address typed by hand — needs enough detail for a driver.
  static String? deliveryAddress(String? raw) {
    final String value = (raw ?? '').trim();
    if (value.isEmpty) return 'Enter a delivery address';
    if (value.length < 10) return 'Add more detail — street, town, parish';
    return null;
  }

  static String? email(String? raw) {
    final String value = (raw ?? '').trim();
    if (value.isEmpty) return 'Enter your email';
    final bool looksValid = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(value);
    return looksValid ? null : 'Enter a valid email';
  }

  /// Admin username — a non-empty handle (not an email address).
  static String? username(String? raw) {
    final String value = (raw ?? '').trim();
    if (value.isEmpty) return 'Enter your username';
    return null;
  }

  static String? password(String? raw) {
    final String value = raw ?? '';
    if (value.isEmpty) return 'Enter your password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }
}
