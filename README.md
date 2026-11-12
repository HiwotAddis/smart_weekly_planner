# Smart Weekly Planner

Flutter weekly planner with Supabase authentication and Postgres-backed data.

## Prerequisites

- Flutter SDK (3.38+ / Dart 3.10+)
- A Supabase project

## Supabase setup

1. Apply the SQL migration in `supabase/migrations/001_initial_schema.sql`
   (see `supabase/README.md`).
2. Copy `.env.example` to `.env` and fill in the **Project URL** and
   **anon / publishable** key from Project Settings → API.
3. Never put the **service_role** key in `.env` or the Flutter app.

## Run

```bash
flutter pub get
flutter run
```

Credentials are loaded from `.env` (declared as a Flutter asset).
Sessions persist across app restarts via `supabase_flutter` local storage.

## Auth features in this phase

- Registration, login, logout, password-reset email
- Auth gate that restores the session on launch
- Loading states, form validation, and error handling
- Database tables: `profiles`, `tasks`, `availability`, `scheduled_tasks`
- Row Level Security so users only access their own rows

Task scheduling is **not** implemented yet.

## Tests

```bash
flutter test
flutter analyze
```
