import 'package:flutter_test/flutter_test.dart';
import 'package:smart_weekly_planner/config/supabase_config.dart';

void main() {
  test('SupabaseConfig reports missing .env values as unconfigured', () {
    // dotenv is not loaded in this test, so env map is empty.
    expect(SupabaseConfig.isConfigured, isFalse);
  });
}
