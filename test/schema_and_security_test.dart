import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File('supabase/migrations/001_initial_schema.sql');

  test('migration file exists', () {
    expect(migration.existsSync(), isTrue);
  });

  test('migration defines required tables', () {
    final sql = migration.readAsStringSync();
    for (final table in [
      'public.profiles',
      'public.tasks',
      'public.availability',
      'public.scheduled_tasks',
    ]) {
      expect(sql.contains('create table if not exists $table'), isTrue);
    }
  });

  test('migration enables RLS and own-row policies', () {
    final sql = migration.readAsStringSync();
    expect(sql.contains('enable row level security'), isTrue);
    expect(sql.contains('auth.uid() = user_id'), isTrue);
    expect(sql.contains('auth.uid() = id'), isTrue);
  });

  test('Flutter lib loads credentials from dotenv (no hardcoded JWTs)', () {
    final libDir = Directory('lib');
    final dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    final jwtPattern = RegExp(
      r'eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,}',
    );

    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      expect(
        jwtPattern.hasMatch(source),
        isFalse,
        reason: '${file.path} must not hardcode JWT keys',
      );
    }

    final config = File('lib/config/supabase_config.dart').readAsStringSync();
    expect(config.contains('flutter_dotenv'), isTrue);
    expect(config.contains('SUPABASE_PUBLISHABLE_KEY'), isTrue);
    expect(config.contains('SUPABASE_URL'), isTrue);
  });
}
