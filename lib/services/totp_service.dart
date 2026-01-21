import 'package:otp/otp.dart';

class TotpService {
  /// Generate TOTP code from secret
  static String generateCode(String secret) {
    try {
      final cleanSecret = secret.replaceAll(' ', '').toUpperCase();
      return OTP.generateTOTPCodeString(
        cleanSecret,
        DateTime.now().millisecondsSinceEpoch,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
    } catch (e) {
      return '------';
    }
  }

  /// Get remaining seconds until next code
  static int getRemainingSeconds() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return 30 - (now % 30);
  }

  /// Get progress (0.0 to 1.0) for the current period
  static double getProgress() {
    return getRemainingSeconds() / 30.0;
  }

  /// Validate if a secret is valid base32
  static bool isValidSecret(String secret) {
    try {
      final cleanSecret = secret.replaceAll(' ', '').toUpperCase();
      if (cleanSecret.isEmpty) return false;
      // Try to generate a code to validate
      OTP.generateTOTPCodeString(
        cleanSecret,
        DateTime.now().millisecondsSinceEpoch,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}
