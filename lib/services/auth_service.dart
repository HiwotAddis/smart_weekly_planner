import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase Auth with validation helpers and readable errors.
class AuthService {
  AuthService({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  /// Lazily resolves the client so validators/UI can be tested without init.
  SupabaseClient get client =>
      _clientOverride ?? Supabase.instance.client;

  User? get currentUser => client.auth.currentUser;

  Session? get currentSession => client.auth.currentSession;

  bool get isSignedIn => currentSession != null;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Please enter your email.';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  static String? validatePassword(String? value, {bool isNewPassword = false}) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Please enter your password.';
    }
    if (isNewPassword && password.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!isNewPassword && password.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  static String? validateDisplayName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return 'Please enter a display name.';
    }
    if (name.length < 2) {
      return 'Display name must be at least 2 characters.';
    }
    return null;
  }

  static String? validateConfirmPassword(String? password, String? confirm) {
    if (confirm == null || confirm.isEmpty) {
      return 'Please confirm your password.';
    }
    if (password != confirm) {
      return 'Passwords do not match.';
    }
    return null;
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'display_name': displayName.trim()},
      );
      return response;
    } on AuthException catch (error) {
      throw AuthFailure(_mapAuthMessage(error.message));
    } catch (_) {
      throw const AuthFailure(
        'Unable to create your account. Check your connection and try again.',
      );
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (error) {
      throw AuthFailure(_mapAuthMessage(error.message));
    } catch (_) {
      throw const AuthFailure(
        'Unable to sign in. Check your connection and try again.',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } on AuthException catch (error) {
      throw AuthFailure(_mapAuthMessage(error.message));
    } catch (_) {
      throw const AuthFailure(
        'Unable to sign out. Check your connection and try again.',
      );
    }
  }

  Future<void> resetPassword({required String email}) async {
    try {
      await client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (error) {
      throw AuthFailure(_mapAuthMessage(error.message));
    } catch (_) {
      throw const AuthFailure(
        'Unable to send reset email. Check your connection and try again.',
      );
    }
  }

  String _mapAuthMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Please confirm your email before signing in.';
    }
    if (lower.contains('user already registered')) {
      return 'An account with this email already exists.';
    }
    if (lower.contains('password')) {
      return message;
    }
    if (lower.contains('rate limit') || lower.contains('too many')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return message.isEmpty ? 'Authentication failed. Please try again.' : message;
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
