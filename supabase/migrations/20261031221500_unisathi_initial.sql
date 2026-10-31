-- UniSathi initial data model. Apply only to a Supabase project after review.
-- No demo data is inserted. Every public table has RLS enabled.

create schema if not exists app_private;
revoke all on schema app_private from public, anon, authenticated;

create type public.unisathi_role as enum ('super_admin', 'institution_admin', 'security', 'teacher', 'student', 'guardian', 'transport_staff');
create type public.institution_kind as enum ('college', 'school');
create type public.attendance_status as enum ('present', 'absent', 'late', 'excused', 'pending');
create type public.incident_category as enum ('bullying', 'ragging', 'medical', 'wellbeing', 'safety', 'unauthorized_exit', 'other');
create type public.incident_status as enum ('reported', 'under_review', 'responding', 'resolved', 'closed');
create type public.notification_kind as enum ('attendance', 'arrival', 'exit', 'support_update', 'emergency', 'system');

create table public.institutions (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 160),
  kind public.institution_kind not null,
  timezone text not null default 'Asia/Kolkata',
  created_at timestamptz not null default now()
);

create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 2 and 120),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.institution_memberships (
  institution_id uuid not null references public.institutions(id) on delete cascade,
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  role public.unisathi_role not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  primary key (institution_id, user_id, role)
);

create table public.guardian_links (
  guardian_id uuid not null references public.profiles(user_id) on delete cascade,
  student_id uuid not null references public.profiles(user_id) on delete cascade,
  institution_id uuid not null references public.institutions(id) on delete cascade,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  primary key (guardian_id, student_id, institution_id),
  check (guardian_id <> student_id)
);

create table public.attendance_records (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions(id) on delete cascade,
  student_id uuid not null references public.profiles(user_id) on delete restrict,
  recorded_by uuid references public.profiles(user_id) on delete set null,
  class_label text not null check (char_length(class_label) between 1 and 140),
  status public.attendance_status not null default 'pending',
  recorded_at timestamptz not null default now(),
  approved_at timestamptz,
  approved_by uuid references public.profiles(user_id) on delete set null,
  created_at timestamptz not null default now(),
  check ((approved_at is null and approved_by is null) or (approved_at is not null and approved_by is not null))
);

create table public.incidents (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions(id) on delete cascade,
  subject_student_id uuid references public.profiles(user_id) on delete set null,
  reported_by uuid not null default auth.uid() references public.profiles(user_id) on delete restrict,
  category public.incident_category not null,
  summary text not null check (char_length(summary) between 10 and 1500),
  occurred_at timestamptz,
  location_label text,
  status public.incident_status not null default 'reported',
  assigned_to uuid references public.profiles(user_id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.emergency_events (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions(id) on delete cascade,
  student_id uuid not null references public.profiles(user_id) on delete restrict,
  status public.incident_status not null default 'reported',
  location_label text,
  requested_at timestamptz not null default now(),
  acknowledged_at timestamptz,
  acknowledged_by uuid references public.profiles(user_id) on delete set null,
  closed_at timestamptz,
  closed_by uuid references public.profiles(user_id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles(user_id) on delete cascade,
  institution_id uuid not null references public.institutions(id) on delete cascade,
  kind public.notification_kind not null,
  title text not null check (char_length(title) between 2 and 180),
  body text not null check (char_length(body) between 2 and 1000),
  related_emergency_id uuid references public.emergency_events(id) on delete cascade,
  related_incident_id uuid references public.incidents(id) on delete cascade,
  read_at timestamptz,
  created_at timestamptz not null default now(),
  check (num_nonnulls(related_emergency_id, related_incident_id) <= 1)
);

create table public.bus_routes (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions(id) on delete cascade,
  name text not null check (char_length(name) between 2 and 100),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (institution_id, name)
);

create table public.bus_assignments (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions(id) on delete cascade,
  route_id uuid not null references public.bus_routes(id) on delete cascade,
  student_id uuid not null references public.profiles(user_id) on delete cascade,
  boarding_stop_label text not null check (char_length(boarding_stop_label) between 2 and 160),
  active boolean not null default true,
  unique (route_id, student_id)
);

create index attendance_records_student_time_idx on public.attendance_records (student_id, recorded_at desc);
create index attendance_records_institution_time_idx on public.attendance_records (institution_id, recorded_at desc);
create index incidents_institution_status_idx on public.incidents (institution_id, status, created_at desc);
create index emergency_events_institution_status_idx on public.emergency_events (institution_id, status, requested_at desc);
create index notifications_recipient_unread_idx on public.notifications (recipient_id, created_at desc) where read_at is null;
create index memberships_user_active_idx on public.institution_memberships (user_id, institution_id) where active;
create index guardian_links_student_active_idx on public.guardian_links (student_id, institution_id) where active;
create index bus_assignments_student_active_idx on public.bus_assignments (student_id, institution_id) where active;

create or replace function app_private.touch_updated_at()
returns trigger language plpgsql set search_path = public as $$
begin new.updated_at = now(); return new; end;
$$;

create trigger profiles_touch_updated_at before update on public.profiles for each row execute procedure app_private.touch_updated_at();
create trigger incidents_touch_updated_at before update on public.incidents for each row execute procedure app_private.touch_updated_at();

create or replace function app_private.has_active_role(target_institution_id uuid, accepted_roles public.unisathi_role[])
returns boolean language sql stable security definer set search_path = public, auth as $$
  select exists (
    select 1 from public.institution_memberships membership
    where membership.institution_id = target_institution_id
      and membership.user_id = auth.uid()
      and membership.active
      and membership.role = any(accepted_roles)
  );
$$;
revoke all on function app_private.has_active_role(uuid, public.unisathi_role[]) from public;

create or replace function app_private.is_linked_guardian(target_student_id uuid, target_institution_id uuid)
returns boolean language sql stable security definer set search_path = public, auth as $$
  select exists (
    select 1 from public.guardian_links link
    where link.guardian_id = auth.uid() and link.student_id = target_student_id
      and link.institution_id = target_institution_id and link.active
  );
$$;
revoke all on function app_private.is_linked_guardian(uuid, uuid) from public;

alter table public.institutions enable row level security;
alter table public.profiles enable row level security;
alter table public.institution_memberships enable row level security;
alter table public.guardian_links enable row level security;
alter table public.attendance_records enable row level security;
alter table public.incidents enable row level security;
alter table public.emergency_events enable row level security;
alter table public.notifications enable row level security;
alter table public.bus_routes enable row level security;
alter table public.bus_assignments enable row level security;

revoke all on all tables in schema public from anon;
revoke all on all tables in schema public from authenticated;
grant usage on schema public to authenticated;
grant select on public.institutions, public.profiles, public.institution_memberships, public.guardian_links, public.attendance_records, public.incidents, public.emergency_events, public.notifications, public.bus_routes, public.bus_assignments to authenticated;
grant insert on public.incidents, public.emergency_events to authenticated;
grant update (read_at) on public.notifications to authenticated;

create policy "members can view their institution" on public.institutions for select to authenticated using (app_private.has_active_role(id, array['super_admin','institution_admin','security','teacher','student','guardian','transport_staff']::public.unisathi_role[]));
create policy "users view own profile" on public.profiles for select to authenticated using (user_id = auth.uid());
create policy "members view membership scope" on public.institution_memberships for select to authenticated using (user_id = auth.uid() or app_private.has_active_role(institution_id, array['super_admin','institution_admin']::public.unisathi_role[]));
create policy "guardians view own links" on public.guardian_links for select to authenticated using (guardian_id = auth.uid() or student_id = auth.uid());
create policy "attendance visible by relation" on public.attendance_records for select to authenticated using (student_id = auth.uid() or app_private.is_linked_guardian(student_id, institution_id) or app_private.has_active_role(institution_id, array['super_admin','institution_admin','teacher']::public.unisathi_role[]));
create policy "incidents readable by reporter or authorised responder" on public.incidents for select to authenticated using (reported_by = auth.uid() or app_private.has_active_role(institution_id, array['super_admin','institution_admin','security']::public.unisathi_role[]));
create policy "members may submit incident reports" on public.incidents for insert to authenticated with check (reported_by = auth.uid() and app_private.has_active_role(institution_id, array['super_admin','institution_admin','security','teacher','student','guardian']::public.unisathi_role[]));
create policy "emergencies readable by student or responders" on public.emergency_events for select to authenticated using (student_id = auth.uid() or app_private.has_active_role(institution_id, array['super_admin','institution_admin','security']::public.unisathi_role[]));
create policy "students can request their own SOS" on public.emergency_events for insert to authenticated with check (student_id = auth.uid() and app_private.has_active_role(institution_id, array['student']::public.unisathi_role[]));
create policy "users read own notifications" on public.notifications for select to authenticated using (recipient_id = auth.uid());
create policy "users mark own notifications read" on public.notifications for update to authenticated using (recipient_id = auth.uid()) with check (recipient_id = auth.uid());
create policy "transport visible by relation" on public.bus_routes for select to authenticated using (app_private.has_active_role(institution_id, array['super_admin','institution_admin','transport_staff']::public.unisathi_role[]) or exists (select 1 from public.bus_assignments assignment where assignment.route_id = id and (assignment.student_id = auth.uid() or app_private.is_linked_guardian(assignment.student_id, assignment.institution_id))));
create policy "assignments visible by relation" on public.bus_assignments for select to authenticated using (student_id = auth.uid() or app_private.is_linked_guardian(student_id, institution_id) or app_private.has_active_role(institution_id, array['super_admin','institution_admin','transport_staff']::public.unisathi_role[]));

-- Data API exposure is explicit as of October 30, 2026. Enable the public schema
-- tables above in your project's Data API settings after applying this migration.

