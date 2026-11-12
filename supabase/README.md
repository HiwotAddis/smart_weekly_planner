# Supabase setup

## 1. Create a project

Create a project at [https://supabase.com](https://supabase.com).

## 2. Apply the schema

Open **SQL Editor** in the dashboard and run:

`migrations/001_initial_schema.sql`

This creates `profiles`, `tasks`, `availability`, and `scheduled_tasks` with
foreign keys, indexes, timestamps, and Row Level Security so users can only
access their own rows.

## 3. Auth settings

Under **Authentication → Providers**, enable Email.

Optional: under **Authentication → URL Configuration**, set a redirect URL for
password-reset deep links when you add mobile URL schemes later.

## 4. Flutter credentials

Copy `.env.example` to `.env` and set:

- Project URL → `SUPABASE_URL`
- `anon` / `publishable` key → `SUPABASE_PUBLISHABLE_KEY`

**Do not** put the `service_role` key in `.env` or the Flutter app.

Then run:

```bash
flutter run
```
