-- =============================================================
-- GAPP Supabase Schema — Multitenant Edition (Spec 12)
-- Run this in your Supabase SQL Editor (Settings > SQL Editor)
-- =============================================================

-- 0. Extensions
create extension if not exists "pgcrypto";

-- =============================================================
-- 1. COMPANIES (tenant root)
-- =============================================================

create table public.companies (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  slug       text not null unique,
  logo_url   text,
  is_active  boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_companies_slug on public.companies(slug);

-- =============================================================
-- 2. IDENTITY & PROFILES
-- =============================================================

-- User profiles (extends auth.users)
create table public.user_profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  phone        text,
  avatar_url   text,
  role         text not null default 'CLIENT'
                 check (role in ('CLIENT', 'GARDENER', 'MANAGER', 'ADMIN', 'SUPER_ADMIN', 'COMPANY_ADMIN')),
  company_id   uuid references public.companies(id) on delete restrict,
  is_active    boolean not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- ADMIN is deprecated; SUPER_ADMIN and COMPANY_ADMIN are the new admin roles.
-- company_id is NULL for SUPER_ADMIN and CLIENT; required for COMPANY_ADMIN and GARDENER.

create index idx_user_profiles_role on public.user_profiles(role);
create index idx_user_profiles_company on public.user_profiles(company_id);

-- Client profiles (global — no company_id)
create table public.client_profiles (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null unique references auth.users(id) on delete cascade,
  display_name text not null,
  phone        text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- Gardener profiles
create table public.gardener_profiles (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null unique references auth.users(id) on delete cascade,
  display_name text not null,
  phone        text,
  avatar_url   text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- =============================================================
-- 3. GARDENS & ASSIGNMENTS
-- =============================================================

create table public.gardens (
  id         uuid primary key default gen_random_uuid(),
  client_id  uuid not null references public.client_profiles(id) on delete restrict,
  company_id uuid not null references public.companies(id) on delete restrict,
  name       text not null,
  address    text not null,
  latitude   double precision,
  longitude  double precision,
  qr_code    text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_gardens_client_id  on public.gardens(client_id);
create index idx_gardens_company_id on public.gardens(company_id);

create table public.garden_assignments (
  id          uuid primary key default gen_random_uuid(),
  garden_id   uuid not null references public.gardens(id) on delete cascade,
  gardener_id uuid not null references public.gardener_profiles(id) on delete restrict,
  is_active   boolean not null default true,
  valid_from  timestamptz not null default now(),
  valid_to    timestamptz,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index idx_garden_assignments_garden   on public.garden_assignments(garden_id);
create index idx_garden_assignments_gardener on public.garden_assignments(gardener_id);
create unique index ux_garden_active_assignment
  on public.garden_assignments(garden_id) where (is_active = true);

-- =============================================================
-- 4. VISITS & PHOTOS
-- =============================================================

create table public.visits (
  id                  uuid primary key default gen_random_uuid(),
  garden_id           uuid not null references public.gardens(id) on delete restrict,
  gardener_id         uuid not null references public.gardener_profiles(id) on delete restrict,
  status              text not null default 'ACTIVE' check (status in ('ACTIVE', 'CLOSED')),
  verification_status text not null default 'VERIFIED' check (verification_status in ('VERIFIED', 'NOT_VERIFIED')),
  initiation_method   text not null default 'MANUAL' check (initiation_method in ('QR_SCAN', 'MANUAL')),
  title               text not null default '',
  description         text not null default '',
  public_comment      text not null default '',
  started_at          timestamptz not null default now(),
  ended_at            timestamptz,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create index idx_visits_garden     on public.visits(garden_id);
create index idx_visits_gardener   on public.visits(gardener_id);
create index idx_visits_started_at on public.visits(started_at desc);
create unique index ux_visits_active_per_gardener
  on public.visits(gardener_id) where (status = 'ACTIVE');

create table public.visit_photos (
  id             uuid primary key default gen_random_uuid(),
  visit_id       uuid not null references public.visits(id) on delete cascade,
  storage_path   text not null,
  thumbnail_path text not null default '',
  label          text not null default '',
  created_at     timestamptz not null default now()
);

create index idx_visit_photos_visit on public.visit_photos(visit_id);

-- =============================================================
-- 5. DEVICE TOKENS (push notifications)
-- =============================================================

create table public.device_tokens (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  token      text not null,
  platform   text not null check (platform in ('ios', 'android')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, token)
);

create index idx_device_tokens_user_id on public.device_tokens(user_id);

-- =============================================================
-- 6. MESSAGING
-- =============================================================

create table public.conversations (
  id                   uuid primary key default gen_random_uuid(),
  gardener_id          uuid not null references public.gardener_profiles(id) on delete restrict,
  client_id            uuid not null references public.client_profiles(id) on delete restrict,
  company_id           uuid not null references public.companies(id) on delete restrict,
  visit_id             uuid references public.visits(id),
  garden_id            uuid references public.gardens(id),
  status               text not null default 'ACTIVE' check (status in ('ACTIVE', 'ARCHIVED')),
  last_message_at      timestamptz,
  unread_message_count integer not null default 0,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  unique (gardener_id, client_id, company_id)
);

create index idx_conversations_gardener   on public.conversations(gardener_id);
create index idx_conversations_client     on public.conversations(client_id);
create index idx_conversations_company    on public.conversations(company_id);

create table public.messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id       uuid not null references auth.users(id),
  recipient_id    uuid not null references auth.users(id),
  sender_role     text not null check (sender_role in ('GARDENER', 'CLIENT')),
  content_type    text not null default 'TEXT' check (content_type in ('TEXT', 'IMAGE', 'DOCUMENT')),
  content         text,
  media_url       text,
  media_file_name text,
  media_mime_type text,
  is_read         boolean not null default false,
  read_at         timestamptz,
  requires_response boolean not null default false,
  created_at      timestamptz not null default now()
);

create index idx_messages_conversation on public.messages(conversation_id);
create index idx_messages_created_at  on public.messages(created_at);

create table public.message_responses (
  id              uuid primary key default gen_random_uuid(),
  message_id      uuid not null references public.messages(id) on delete cascade,
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  responder_id    uuid not null references auth.users(id),
  action          text not null check (action in ('ACCEPT', 'REJECT', 'MORE_INFO')),
  additional_message text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz
);

create index idx_responses_message on public.message_responses(message_id);

-- =============================================================
-- 7. LOCATION TRACKING (HEATMAP DATA)
-- =============================================================

create table public.visit_location_points (
  id          uuid default gen_random_uuid() primary key,
  visit_id    uuid not null references public.visits(id) on delete cascade,
  lat         double precision not null,
  lng         double precision not null,
  accuracy    double precision,
  recorded_at timestamptz not null default now()
);

create index idx_visit_location_points_visit_id    on public.visit_location_points(visit_id);
create index idx_visit_location_points_recorded_at on public.visit_location_points(recorded_at);

-- =============================================================
-- 8. UPDATED_AT TRIGGER
-- =============================================================

create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger set_updated_at before update on public.companies
  for each row execute function public.handle_updated_at();
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
create trigger set_updated_at before update on public.device_tokens
  for each row execute function public.handle_updated_at();

-- =============================================================
-- 9. AUTO-CREATE PROFILE ON SIGNUP
-- =============================================================

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.user_profiles (id, display_name, role, company_id)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'display_name', new.email),
    coalesce(new.raw_user_meta_data->>'role', 'CLIENT'),
    (new.raw_user_meta_data->>'company_id')::uuid
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- =============================================================
-- 10. ROW LEVEL SECURITY
-- =============================================================

alter table public.companies             enable row level security;
alter table public.user_profiles         enable row level security;
alter table public.client_profiles       enable row level security;
alter table public.gardener_profiles     enable row level security;
alter table public.gardens               enable row level security;
alter table public.garden_assignments    enable row level security;
alter table public.visits                enable row level security;
alter table public.visit_photos          enable row level security;
alter table public.conversations         enable row level security;
alter table public.device_tokens         enable row level security;
alter table public.messages              enable row level security;
alter table public.message_responses     enable row level security;
alter table public.visit_location_points enable row level security;

-- ---- Helper functions ----

-- Super-admin: full platform access (includes legacy ADMIN role)
create or replace function public.is_super_admin()
returns boolean as $$
  select exists (
    select 1 from public.user_profiles
    where id = auth.uid() and role in ('ADMIN', 'SUPER_ADMIN')
  );
$$ language sql security definer stable;

-- Company-admin: manages their own company
create or replace function public.is_company_admin()
returns boolean as $$
  select exists (
    select 1 from public.user_profiles
    where id = auth.uid() and role = 'COMPANY_ADMIN'
  );
$$ language sql security definer stable;

-- Get company_id for current user
create or replace function public.my_company_id()
returns uuid as $$
  select company_id from public.user_profiles where id = auth.uid();
$$ language sql security definer stable;

-- Get gardener_profile id for current user
create or replace function public.my_gardener_id()
returns uuid as $$
  select id from public.gardener_profiles where user_id = auth.uid();
$$ language sql security definer stable;

-- Get client_profile id for current user
create or replace function public.my_client_id()
returns uuid as $$
  select id from public.client_profiles where user_id = auth.uid();
$$ language sql security definer stable;

-- Kept for backward compat with any existing Edge Functions
create or replace function public.is_admin()
returns boolean as $$
  select public.is_super_admin();
$$ language sql security definer stable;

-- ---- companies ----
create policy "Super-admins manage companies"
  on public.companies for all
  using (public.is_super_admin())
  with check (public.is_super_admin());

create policy "Company-admins read own company"
  on public.companies for select
  using (id = public.my_company_id());

-- ---- user_profiles ----
create policy "Super-admins manage all profiles"
  on public.user_profiles for all
  using (public.is_super_admin())
  with check (public.is_super_admin());

create policy "Company-admins manage profiles in their company"
  on public.user_profiles for all
  using (
    public.is_company_admin()
    and (company_id = public.my_company_id() or id = auth.uid())
  )
  with check (
    public.is_company_admin()
    and (company_id = public.my_company_id() or id = auth.uid())
  );

create policy "Users read and update own profile"
  on public.user_profiles for select
  using (id = auth.uid());

create policy "Users update own profile"
  on public.user_profiles for update
  using (id = auth.uid());

-- ---- client_profiles ----
-- Gardeners: only display_name and phone via a restricted select
-- Implemented via policy; all columns visible to allowed roles, select restricted for gardeners
create policy "Super-admins manage client_profiles"
  on public.client_profiles for all
  using (public.is_super_admin());

create policy "Company-admins manage client_profiles"
  on public.client_profiles for all
  using (public.is_company_admin());

create policy "Clients read own profile"
  on public.client_profiles for select
  using (user_id = auth.uid());

create policy "Clients update own profile"
  on public.client_profiles for update
  using (user_id = auth.uid());

create policy "Gardeners read client name and phone"
  on public.client_profiles for select
  using (
    exists (
      select 1 from public.garden_assignments ga
      join public.gardens g on g.id = ga.garden_id
      where ga.gardener_id = public.my_gardener_id()
        and ga.is_active = true
        and g.client_id = client_profiles.id
        and g.company_id = public.my_company_id()
    )
  );

-- ---- gardener_profiles ----
create policy "Super-admins manage gardener_profiles"
  on public.gardener_profiles for all
  using (public.is_super_admin());

create policy "Company-admins manage their gardener_profiles"
  on public.gardener_profiles for all
  using (
    public.is_company_admin()
    and exists (
      select 1 from public.user_profiles up
      where up.id = gardener_profiles.user_id
        and up.company_id = public.my_company_id()
    )
  );

create policy "Gardeners read own profile"
  on public.gardener_profiles for select
  using (user_id = auth.uid());

create policy "Gardeners update own profile"
  on public.gardener_profiles for update
  using (user_id = auth.uid());

-- ---- gardens ----
create policy "Super-admins manage all gardens"
  on public.gardens for all
  using (public.is_super_admin())
  with check (public.is_super_admin());

create policy "Company-admins manage their gardens"
  on public.gardens for all
  using (public.is_company_admin() and company_id = public.my_company_id())
  with check (public.is_company_admin() and company_id = public.my_company_id());

create policy "Gardeners see assigned gardens"
  on public.gardens for select
  using (
    exists (
      select 1 from public.garden_assignments ga
      where ga.garden_id = gardens.id
        and ga.gardener_id = public.my_gardener_id()
        and ga.is_active = true
    )
    and company_id = public.my_company_id()
  );

create policy "Clients see own gardens"
  on public.gardens for select
  using (client_id = public.my_client_id());

-- ---- garden_assignments ----
create policy "Super-admins manage all assignments"
  on public.garden_assignments for all
  using (public.is_super_admin());

create policy "Company-admins manage their assignments"
  on public.garden_assignments for all
  using (
    public.is_company_admin()
    and exists (
      select 1 from public.gardens g
      where g.id = garden_assignments.garden_id
        and g.company_id = public.my_company_id()
    )
  );

create policy "Gardeners see own assignments"
  on public.garden_assignments for select
  using (gardener_id = public.my_gardener_id());

-- ---- visits ----
create policy "Super-admins manage all visits"
  on public.visits for all
  using (public.is_super_admin());

create policy "Company-admins manage their visits"
  on public.visits for all
  using (
    public.is_company_admin()
    and exists (
      select 1 from public.gardens g
      where g.id = visits.garden_id
        and g.company_id = public.my_company_id()
    )
  );

create policy "Gardeners manage own visits"
  on public.visits for all
  using (gardener_id = public.my_gardener_id());

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
create policy "Super-admins manage all visit photos"
  on public.visit_photos for all
  using (public.is_super_admin());

create policy "Company-admins manage their visit photos"
  on public.visit_photos for all
  using (
    public.is_company_admin()
    and exists (
      select 1 from public.visits v
      join public.gardens g on g.id = v.garden_id
      where v.id = visit_photos.visit_id
        and g.company_id = public.my_company_id()
    )
  );

create policy "Gardeners manage own visit photos"
  on public.visit_photos for all
  using (
    exists (
      select 1 from public.visits v
      where v.id = visit_photos.visit_id
        and v.gardener_id = public.my_gardener_id()
    )
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

-- ---- device_tokens ----
create policy "Users manage own tokens"
  on public.device_tokens for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---- conversations ----
create policy "Super-admins manage all conversations"
  on public.conversations for all
  using (public.is_super_admin());

create policy "Company-admins manage their conversations"
  on public.conversations for all
  using (public.is_company_admin() and company_id = public.my_company_id());

create policy "Gardeners see own conversations"
  on public.conversations for select
  using (gardener_id = public.my_gardener_id());

create policy "Gardeners update own conversations"
  on public.conversations for update
  using (gardener_id = public.my_gardener_id());

create policy "Clients see own conversations"
  on public.conversations for select
  using (client_id = public.my_client_id());

create policy "Clients update own conversations"
  on public.conversations for update
  using (client_id = public.my_client_id());

-- ---- messages ----
create policy "Super-admins manage all messages"
  on public.messages for all
  using (public.is_super_admin());

create policy "Participants see conversation messages"
  on public.messages for select
  using (sender_id = auth.uid() or recipient_id = auth.uid());

create policy "Users send messages"
  on public.messages for insert
  with check (sender_id = auth.uid());

create policy "Recipients mark as read"
  on public.messages for update
  using (recipient_id = auth.uid());

-- ---- message_responses ----
create policy "Super-admins manage all responses"
  on public.message_responses for all
  using (public.is_super_admin());

create policy "Participants see responses"
  on public.message_responses for select
  using (
    responder_id = auth.uid()
    or exists (
      select 1 from public.messages m
      where m.id = message_responses.message_id
        and m.sender_id = auth.uid()
    )
  );

create policy "Responders create responses"
  on public.message_responses for insert
  with check (responder_id = auth.uid());

-- ---- visit_location_points ----
create policy "Super-admins manage all location points"
  on public.visit_location_points for all
  using (public.is_super_admin())
  with check (public.is_super_admin());

create policy "Company-admins manage their location points"
  on public.visit_location_points for all
  using (
    public.is_company_admin()
    and visit_id in (
      select v.id from public.visits v
      join public.gardens g on g.id = v.garden_id
      where g.company_id = public.my_company_id()
    )
  );

create policy "Gardeners manage their visit location points"
  on public.visit_location_points for all
  using (
    visit_id in (
      select id from public.visits
      where gardener_id = public.my_gardener_id()
    )
  )
  with check (
    visit_id in (
      select id from public.visits
      where gardener_id = public.my_gardener_id()
    )
  );

create policy "Clients read their garden visit location points"
  on public.visit_location_points for select
  using (
    visit_id in (
      select v.id from public.visits v
      join public.gardens g on g.id = v.garden_id
      where g.client_id = public.my_client_id()
    )
  );

-- =============================================================
-- 11. STORAGE BUCKET
-- =============================================================

insert into storage.buckets (id, name, public)
values ('visit-photos', 'visit-photos', false)
on conflict (id) do nothing;

drop policy if exists "Gardeners upload visit photos" on storage.objects;
drop policy if exists "Authenticated users read visit photos" on storage.objects;
drop policy if exists "Gardeners delete own visit photos" on storage.objects;

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
-- 12. SEED DATA
-- =============================================================

-- 1. Create the super-admin user via Supabase Auth (Dashboard or API).
--    Their profile is auto-created by the trigger.
-- 2. Promote them to SUPER_ADMIN:
--
-- update public.user_profiles
-- set role = 'SUPER_ADMIN', display_name = 'Super Admin GAPP'
-- where id = '<super-admin-uuid-from-auth>';
--
-- 3. Create companies and company-admins via the web admin panel (Empresas section).
