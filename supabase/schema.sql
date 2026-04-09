-- =============================================================
-- GAPP Supabase Schema
-- Run this in your Supabase SQL Editor (Settings > SQL Editor)
-- =============================================================

-- 0. Extensions
create extension if not exists "pgcrypto";

-- =============================================================
-- 1. IDENTITY & PROFILES
-- =============================================================

-- User profiles (extends auth.users)
create table public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  phone text,
  avatar_url text,
  role text not null default 'CLIENT' check (role in ('CLIENT', 'GARDENER', 'MANAGER', 'ADMIN')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_user_profiles_role on public.user_profiles(role);

-- Client profiles
create table public.client_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  display_name text not null,
  phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Gardener profiles
create table public.gardener_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  display_name text not null,
  phone text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =============================================================
-- 2. GARDENS & ASSIGNMENTS
-- =============================================================

create table public.gardens (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.client_profiles(id) on delete restrict,
  name text not null,
  address text not null,
  latitude double precision,
  longitude double precision,
  qr_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_gardens_client_id on public.gardens(client_id);

create table public.garden_assignments (
  id uuid primary key default gen_random_uuid(),
  garden_id uuid not null references public.gardens(id) on delete cascade,
  gardener_id uuid not null references public.gardener_profiles(id) on delete restrict,
  is_active boolean not null default true,
  valid_from timestamptz not null default now(),
  valid_to timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_garden_assignments_garden on public.garden_assignments(garden_id);
create index idx_garden_assignments_gardener on public.garden_assignments(gardener_id);
create unique index ux_garden_active_assignment
  on public.garden_assignments(garden_id) where (is_active = true);

-- =============================================================
-- 3. VISITS & PHOTOS
-- =============================================================

create table public.visits (
  id uuid primary key default gen_random_uuid(),
  garden_id uuid not null references public.gardens(id) on delete restrict,
  gardener_id uuid not null references public.gardener_profiles(id) on delete restrict,
  status text not null default 'ACTIVE' check (status in ('ACTIVE', 'CLOSED')),
  verification_status text not null default 'VERIFIED' check (verification_status in ('VERIFIED', 'NOT_VERIFIED')),
  initiation_method text not null default 'MANUAL' check (initiation_method in ('QR_SCAN', 'MANUAL')),
  title text not null default '',
  description text not null default '',
  public_comment text not null default '',
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_visits_garden on public.visits(garden_id);
create index idx_visits_gardener on public.visits(gardener_id);
create index idx_visits_started_at on public.visits(started_at desc);
create unique index ux_visits_active_per_gardener
  on public.visits(gardener_id) where (status = 'ACTIVE');

create table public.visit_photos (
  id uuid primary key default gen_random_uuid(),
  visit_id uuid not null references public.visits(id) on delete cascade,
  storage_path text not null,
  thumbnail_path text not null default '',
  label text not null default '',
  created_at timestamptz not null default now()
);

create index idx_visit_photos_visit on public.visit_photos(visit_id);

-- =============================================================
-- 4. MESSAGING
-- =============================================================

create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  gardener_id uuid not null references public.gardener_profiles(id) on delete restrict,
  client_id uuid not null references public.client_profiles(id) on delete restrict,
  visit_id uuid references public.visits(id),
  garden_id uuid references public.gardens(id),
  status text not null default 'ACTIVE' check (status in ('ACTIVE', 'ARCHIVED')),
  last_message_at timestamptz,
  unread_message_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (gardener_id, client_id)
);

create index idx_conversations_gardener on public.conversations(gardener_id);
create index idx_conversations_client on public.conversations(client_id);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references auth.users(id),
  recipient_id uuid not null references auth.users(id),
  sender_role text not null check (sender_role in ('GARDENER', 'CLIENT')),
  content_type text not null default 'TEXT' check (content_type in ('TEXT', 'IMAGE', 'DOCUMENT')),
  content text,
  media_url text,
  media_file_name text,
  media_mime_type text,
  is_read boolean not null default false,
  read_at timestamptz,
  requires_response boolean not null default false,
  created_at timestamptz not null default now()
);

create index idx_messages_conversation on public.messages(conversation_id);
create index idx_messages_created_at on public.messages(created_at);

create table public.message_responses (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  responder_id uuid not null references auth.users(id),
  action text not null check (action in ('ACCEPT', 'REJECT', 'MORE_INFO')),
  additional_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz
);

create index idx_responses_message on public.message_responses(message_id);

-- =============================================================
-- 5. UPDATED_AT TRIGGER
-- =============================================================

create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger set_updated_at before update on public.user_profiles
  for each row execute function public.handle_updated_at();
create trigger set_updated_at before update on public.client_profiles
  for each row execute function public.handle_updated_at();
create trigger set_updated_at before update on public.gardener_profiles
  for each row execute function public.handle_updated_at();
create trigger set_updated_at before update on public.gardens
  for each row execute function public.handle_updated_at();
create trigger set_updated_at before update on public.garden_assignments
  for each row execute function public.handle_updated_at();
create trigger set_updated_at before update on public.visits
  for each row execute function public.handle_updated_at();
create trigger set_updated_at before update on public.conversations
  for each row execute function public.handle_updated_at();

-- =============================================================
-- 6. AUTO-CREATE PROFILE ON SIGNUP
-- =============================================================

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.user_profiles (id, display_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'display_name', new.email),
    coalesce(new.raw_user_meta_data->>'role', 'CLIENT')
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- =============================================================
-- 7. ROW LEVEL SECURITY
-- =============================================================

alter table public.user_profiles enable row level security;
alter table public.client_profiles enable row level security;
alter table public.gardener_profiles enable row level security;
alter table public.gardens enable row level security;
alter table public.garden_assignments enable row level security;
alter table public.visits enable row level security;
alter table public.visit_photos enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.message_responses enable row level security;

-- Helper: check if current user is admin
create or replace function public.is_admin()
returns boolean as $$
  select exists (
    select 1 from public.user_profiles
    where id = auth.uid() and role = 'ADMIN'
  );
$$ language sql security definer stable;

-- Helper: get gardener_profile id for current user
create or replace function public.my_gardener_id()
returns uuid as $$
  select id from public.gardener_profiles where user_id = auth.uid();
$$ language sql security definer stable;

-- Helper: get client_profile id for current user
create or replace function public.my_client_id()
returns uuid as $$
  select id from public.client_profiles where user_id = auth.uid();
$$ language sql security definer stable;

-- ---- user_profiles ----
create policy "Users can read own profile"
  on public.user_profiles for select
  using (id = auth.uid() or public.is_admin());

create policy "Users can update own profile"
  on public.user_profiles for update
  using (id = auth.uid() or public.is_admin());

create policy "Admins can insert profiles"
  on public.user_profiles for insert
  with check (public.is_admin());

create policy "Admins can delete profiles"
  on public.user_profiles for delete
  using (public.is_admin());

-- ---- client_profiles ----
create policy "Clients read own, admins read all"
  on public.client_profiles for select
  using (user_id = auth.uid() or public.is_admin());

create policy "Admins manage client_profiles"
  on public.client_profiles for all
  using (public.is_admin());

-- ---- gardener_profiles ----
create policy "Gardeners read own, admins read all"
  on public.gardener_profiles for select
  using (user_id = auth.uid() or public.is_admin());

create policy "Admins manage gardener_profiles"
  on public.gardener_profiles for all
  using (public.is_admin());

-- ---- gardens ----
create policy "Clients see own gardens"
  on public.gardens for select
  using (
    client_id = public.my_client_id()
    or public.is_admin()
    or exists (
      select 1 from public.garden_assignments ga
      where ga.garden_id = gardens.id
        and ga.gardener_id = public.my_gardener_id()
        and ga.is_active = true
    )
  );

create policy "Admins manage gardens"
  on public.gardens for all
  using (public.is_admin());

-- ---- garden_assignments ----
create policy "Gardeners see own assignments"
  on public.garden_assignments for select
  using (
    gardener_id = public.my_gardener_id()
    or public.is_admin()
  );

create policy "Admins manage assignments"
  on public.garden_assignments for all
  using (public.is_admin());

-- ---- visits ----
create policy "Gardeners manage own visits"
  on public.visits for all
  using (
    gardener_id = public.my_gardener_id()
    or public.is_admin()
  );

create policy "Clients read their garden visits"
  on public.visits for select
  using (
    exists (
      select 1 from public.gardens g
      where g.id = visits.garden_id
        and g.client_id = public.my_client_id()
    )
  );

-- ---- visit_photos ----
create policy "Gardeners manage visit photos"
  on public.visit_photos for all
  using (
    exists (
      select 1 from public.visits v
      where v.id = visit_photos.visit_id
        and v.gardener_id = public.my_gardener_id()
    )
    or public.is_admin()
  );

create policy "Clients read their visit photos"
  on public.visit_photos for select
  using (
    exists (
      select 1 from public.visits v
      join public.gardens g on g.id = v.garden_id
      where v.id = visit_photos.visit_id
        and g.client_id = public.my_client_id()
    )
  );

-- ---- conversations ----
create policy "Participants see own conversations"
  on public.conversations for select
  using (
    gardener_id = public.my_gardener_id()
    or client_id = public.my_client_id()
    or public.is_admin()
  );

create policy "Participants manage own conversations"
  on public.conversations for all
  using (
    gardener_id = public.my_gardener_id()
    or client_id = public.my_client_id()
    or public.is_admin()
  );

-- ---- messages ----
create policy "Participants see conversation messages"
  on public.messages for select
  using (
    sender_id = auth.uid()
    or recipient_id = auth.uid()
    or public.is_admin()
  );

create policy "Users send messages"
  on public.messages for insert
  with check (sender_id = auth.uid() or public.is_admin());

create policy "Recipients mark as read"
  on public.messages for update
  using (recipient_id = auth.uid() or public.is_admin());

-- ---- message_responses ----
create policy "Participants see responses"
  on public.message_responses for select
  using (
    responder_id = auth.uid()
    or exists (
      select 1 from public.messages m
      where m.id = message_responses.message_id
        and m.sender_id = auth.uid()
    )
    or public.is_admin()
  );

create policy "Responders create responses"
  on public.message_responses for insert
  with check (responder_id = auth.uid() or public.is_admin());

-- =============================================================
-- 8. STORAGE BUCKET
-- =============================================================

insert into storage.buckets (id, name, public)
values ('visit-photos', 'visit-photos', false)
on conflict (id) do nothing;

create policy "Gardeners upload visit photos"
  on storage.objects for insert
  with check (
    bucket_id = 'visit-photos'
    and (auth.uid() is not null)
  );

create policy "Authenticated users read visit photos"
  on storage.objects for select
  using (
    bucket_id = 'visit-photos'
    and (auth.uid() is not null)
  );

create policy "Gardeners delete own visit photos"
  on storage.objects for delete
  using (
    bucket_id = 'visit-photos'
    and (auth.uid() is not null)
  );

-- =============================================================
-- 9. SEED DATA
-- =============================================================

-- Note: The admin user must be created via Supabase Auth first.
-- After creating the admin user in the dashboard or via API,
-- their profile will be auto-created by the trigger.
-- Then run this to set their role to ADMIN:
--
-- update public.user_profiles
-- set role = 'ADMIN', display_name = 'Admin GAPP'
-- where id = '<admin-user-uuid-from-auth>';
