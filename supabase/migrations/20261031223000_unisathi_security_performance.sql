-- Resolve advisor findings: index foreign keys and cache auth.uid() per query in RLS policies.

create index attendance_records_recorded_by_idx on public.attendance_records (recorded_by) where recorded_by is not null;
create index attendance_records_approved_by_idx on public.attendance_records (approved_by) where approved_by is not null;
create index bus_assignments_institution_idx on public.bus_assignments (institution_id);
create index emergency_events_student_idx on public.emergency_events (student_id);
create index emergency_events_acknowledged_by_idx on public.emergency_events (acknowledged_by) where acknowledged_by is not null;
create index emergency_events_closed_by_idx on public.emergency_events (closed_by) where closed_by is not null;
create index guardian_links_institution_idx on public.guardian_links (institution_id);
create index incidents_subject_student_idx on public.incidents (subject_student_id) where subject_student_id is not null;
create index incidents_reported_by_idx on public.incidents (reported_by);
create index incidents_assigned_to_idx on public.incidents (assigned_to) where assigned_to is not null;
create index notifications_institution_idx on public.notifications (institution_id, created_at desc);
create index notifications_related_emergency_idx on public.notifications (related_emergency_id) where related_emergency_id is not null;
create index notifications_related_incident_idx on public.notifications (related_incident_id) where related_incident_id is not null;

drop policy "users view own profile" on public.profiles;
create policy "users view own profile" on public.profiles for select to authenticated using (user_id = (select auth.uid()));

drop policy "members view membership scope" on public.institution_memberships;
create policy "members view membership scope" on public.institution_memberships for select to authenticated using (user_id = (select auth.uid()) or app_private.has_active_role(institution_id, array['super_admin','institution_admin']::public.unisathi_role[]));

drop policy "guardians view own links" on public.guardian_links;
create policy "guardians view own links" on public.guardian_links for select to authenticated using (guardian_id = (select auth.uid()) or student_id = (select auth.uid()));

drop policy "attendance visible by relation" on public.attendance_records;
create policy "attendance visible by relation" on public.attendance_records for select to authenticated using (student_id = (select auth.uid()) or app_private.is_linked_guardian(student_id, institution_id) or app_private.has_active_role(institution_id, array['super_admin','institution_admin','teacher']::public.unisathi_role[]));

drop policy "incidents readable by reporter or authorised responder" on public.incidents;
create policy "incidents readable by reporter or authorised responder" on public.incidents for select to authenticated using (reported_by = (select auth.uid()) or app_private.has_active_role(institution_id, array['super_admin','institution_admin','security']::public.unisathi_role[]));
drop policy "members may submit incident reports" on public.incidents;
create policy "members may submit incident reports" on public.incidents for insert to authenticated with check (reported_by = (select auth.uid()) and app_private.has_active_role(institution_id, array['super_admin','institution_admin','security','teacher','student','guardian']::public.unisathi_role[]));

drop policy "emergencies readable by student or responders" on public.emergency_events;
create policy "emergencies readable by student or responders" on public.emergency_events for select to authenticated using (student_id = (select auth.uid()) or app_private.has_active_role(institution_id, array['super_admin','institution_admin','security']::public.unisathi_role[]));
drop policy "students can request their own SOS" on public.emergency_events;
create policy "students can request their own SOS" on public.emergency_events for insert to authenticated with check (student_id = (select auth.uid()) and app_private.has_active_role(institution_id, array['student']::public.unisathi_role[]));

drop policy "users read own notifications" on public.notifications;
create policy "users read own notifications" on public.notifications for select to authenticated using (recipient_id = (select auth.uid()));
drop policy "users mark own notifications read" on public.notifications;
create policy "users mark own notifications read" on public.notifications for update to authenticated using (recipient_id = (select auth.uid())) with check (recipient_id = (select auth.uid()));

drop policy "transport visible by relation" on public.bus_routes;
create policy "transport visible by relation" on public.bus_routes for select to authenticated using (app_private.has_active_role(institution_id, array['super_admin','institution_admin','transport_staff']::public.unisathi_role[]) or exists (select 1 from public.bus_assignments assignment where assignment.route_id = id and (assignment.student_id = (select auth.uid()) or app_private.is_linked_guardian(assignment.student_id, assignment.institution_id))));
drop policy "assignments visible by relation" on public.bus_assignments;
create policy "assignments visible by relation" on public.bus_assignments for select to authenticated using (student_id = (select auth.uid()) or app_private.is_linked_guardian(student_id, institution_id) or app_private.has_active_role(institution_id, array['super_admin','institution_admin','transport_staff']::public.unisathi_role[]));

