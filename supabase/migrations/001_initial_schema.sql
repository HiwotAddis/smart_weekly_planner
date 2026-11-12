-- Smart Weekly Planner — initial schema
-- Run in the Supabase SQL Editor (or via supabase db push).
-- Uses the anon/authenticated roles only; never embed the service-role key in the app.

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  display_name text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists profiles_email_idx on public.profiles (email);

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Auto-create a profile when a user signs up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, email, display_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1))
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- tasks
-- ---------------------------------------------------------------------------

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  description text,
  deadline timestamptz not null,
  estimated_minutes integer not null check (estimated_minutes > 0),
  remaining_minutes integer not null check (remaining_minutes >= 0),
  priority text not null default 'medium'
    check (priority in ('low', 'medium', 'high')),
  is_completed boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint tasks_title_not_blank check (char_length(trim(title)) > 0)
);

create index if not exists tasks_user_id_idx on public.tasks (user_id);
create index if not exists tasks_user_deadline_idx on public.tasks (user_id, deadline);
create index if not exists tasks_user_completed_idx on public.tasks (user_id, is_completed);

drop trigger if exists tasks_set_updated_at on public.tasks;
create trigger tasks_set_updated_at
  before update on public.tasks
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- availability (weekly time windows; day_of_week matches Dart DateTime.weekday: 1=Mon … 7=Sun)
-- ---------------------------------------------------------------------------

create table if not exists public.availability (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  day_of_week smallint not null check (day_of_week between 1 and 7),
  start_time time not null,
  end_time time not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint availability_valid_window check (end_time > start_time),
  constraint availability_unique_slot unique (user_id, day_of_week, start_time, end_time)
);

create index if not exists availability_user_id_idx on public.availability (user_id);
create index if not exists availability_user_day_idx on public.availability (user_id, day_of_week);

drop trigger if exists availability_set_updated_at on public.availability;
create trigger availability_set_updated_at
  before update on public.availability
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- scheduled_tasks (slots produced later by the scheduler — schema only for now)
-- ---------------------------------------------------------------------------

create table if not exists public.scheduled_tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  task_id uuid not null references public.tasks (id) on delete cascade,
  scheduled_start timestamptz not null,
  scheduled_end timestamptz not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint scheduled_tasks_valid_window check (scheduled_end > scheduled_start)
);

create index if not exists scheduled_tasks_user_id_idx on public.scheduled_tasks (user_id);
create index if not exists scheduled_tasks_task_id_idx on public.scheduled_tasks (task_id);
create index if not exists scheduled_tasks_user_start_idx
  on public.scheduled_tasks (user_id, scheduled_start);

drop trigger if exists scheduled_tasks_set_updated_at on public.scheduled_tasks;
create trigger scheduled_tasks_set_updated_at
  before update on public.scheduled_tasks
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.tasks enable row level security;
alter table public.availability enable row level security;
alter table public.scheduled_tasks enable row level security;

-- profiles
drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile"
  on public.profiles for select
  to authenticated
  using (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Inserts are performed by the security-definer trigger on signup.
-- Authenticated users must not insert arbitrary profile rows.
drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
  on public.profiles for insert
  to authenticated
  with check (auth.uid() = id);

-- tasks
drop policy if exists "Users can select own tasks" on public.tasks;
create policy "Users can select own tasks"
  on public.tasks for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own tasks" on public.tasks;
create policy "Users can insert own tasks"
  on public.tasks for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own tasks" on public.tasks;
create policy "Users can update own tasks"
  on public.tasks for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete own tasks" on public.tasks;
create policy "Users can delete own tasks"
  on public.tasks for delete
  to authenticated
  using (auth.uid() = user_id);

-- availability
drop policy if exists "Users can select own availability" on public.availability;
create policy "Users can select own availability"
  on public.availability for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own availability" on public.availability;
create policy "Users can insert own availability"
  on public.availability for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own availability" on public.availability;
create policy "Users can update own availability"
  on public.availability for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete own availability" on public.availability;
create policy "Users can delete own availability"
  on public.availability for delete
  to authenticated
  using (auth.uid() = user_id);

-- scheduled_tasks
drop policy if exists "Users can select own scheduled tasks" on public.scheduled_tasks;
create policy "Users can select own scheduled tasks"
  on public.scheduled_tasks for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own scheduled tasks" on public.scheduled_tasks;
create policy "Users can insert own scheduled tasks"
  on public.scheduled_tasks for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own scheduled tasks" on public.scheduled_tasks;
create policy "Users can update own scheduled tasks"
  on public.scheduled_tasks for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete own scheduled tasks" on public.scheduled_tasks;
create policy "Users can delete own scheduled tasks"
  on public.scheduled_tasks for delete
  to authenticated
  using (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Grants (API roles — no service_role usage from the Flutter client)
-- ---------------------------------------------------------------------------

grant usage on schema public to anon, authenticated;

grant select, update, insert on table public.profiles to authenticated;
grant select, insert, update, delete on table public.tasks to authenticated;
grant select, insert, update, delete on table public.availability to authenticated;
grant select, insert, update, delete on table public.scheduled_tasks to authenticated;
