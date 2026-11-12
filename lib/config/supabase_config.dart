import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Client-side Supabase configuration loaded from `.env`.
///
/// Only the anon / publishable key is used in this app.
///
/// Expected keys in `.env`:
/// - `SUPABASE_URL`
/// - `SUPABASE_PUBLISHABLE_KEY` (or `SUPABASE_ANON_KEY`)
class SupabaseConfig {
  SupabaseConfig._();

  static String get url => _env('SUPABASE_URL');

  /// Publishable (anon) key from `.env`.
  static String get anonKey {
    final publishable = _env('SUPABASE_PUBLISHABLE_KEY');
    if (publishable.isNotEmpty) {
      return publishable;
    }
    return _env('SUPABASE_ANON_KEY');
  }

  static String _env(String key) {
    if (!dotenv.isInitialized) {
      return '';
    }
    return dotenv.env[key]?.trim() ?? '';
  }

  static bool get isConfigured =>
      url.isNotEmpty && anonKey.isNotEmpty;

  static void assertConfigured() {
    if (!isConfigured) {
      throw StateError(
        'Supabase is not configured. Add SUPABASE_URL and '
        'SUPABASE_PUBLISHABLE_KEY (or SUPABASE_ANON_KEY) to your .env file. '
        'Use only the anon/publishable key in the Flutter app.',
      );
    }
  }
}
