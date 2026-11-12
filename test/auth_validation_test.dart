import 'package:flutter_test/flutter_test.dart';
import 'package:smart_weekly_planner/services/auth_service.dart';

void main() {
  group('AuthService validators', () {
    test('email validation', () {
      expect(AuthService.validateEmail(null), isNotNull);
      expect(AuthService.validateEmail(''), isNotNull);
      expect(AuthService.validateEmail('not-an-email'), isNotNull);
      expect(AuthService.validateEmail('user@example.com'), isNull);
    });

    test('password validation', () {
      expect(AuthService.validatePassword(null), isNotNull);
      expect(AuthService.validatePassword('123'), isNotNull);
      expect(AuthService.validatePassword('123456'), isNull);
      expect(
        AuthService.validatePassword('short', isNewPassword: true),
        isNotNull,
      );
      expect(
        AuthService.validatePassword('longenough', isNewPassword: true),
        isNull,
      );
    });

    test('display name validation', () {
      expect(AuthService.validateDisplayName(''), isNotNull);
      expect(AuthService.validateDisplayName('A'), isNotNull);
      expect(AuthService.validateDisplayName('Ada'), isNull);
    });

    test('confirm password validation', () {
      expect(AuthService.validateConfirmPassword('abc', null), isNotNull);
      expect(AuthService.validateConfirmPassword('abc', 'xyz'), isNotNull);
      expect(AuthService.validateConfirmPassword('abc', 'abc'), isNull);
    });
  });

  }
