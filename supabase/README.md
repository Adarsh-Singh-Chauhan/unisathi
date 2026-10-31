# UniSathi Supabase backend

## Scope

This directory contains a production-oriented starting point for the UniSathi operational backend:

- Supabase Auth user identities mapped to `profiles`.
- Institution memberships and explicit roles; never trust user-editable `user_metadata` for authorisation.
- Attendance, incidents, SOS events, notifications and transport assignments.
- Row Level Security policies and explicit grants for the Data API.
- An Edge Function that validates an authenticated student before creating an SOS event and notifying authorised responders.

## Before applying

1. Create or connect a Supabase project.
2. Review the institution’s safeguarding, incident-handling, consent and data-retention policies.
3. Apply the migration in `migrations/` to the intended project.
4. In **Data API settings**, explicitly expose only the required `public` tables to authenticated clients.
5. Deploy `functions/sos-dispatch` and configure `SUPABASE_URL`, `SUPABASE_ANON_KEY` and `SUPABASE_SERVICE_ROLE_KEY` as Edge Function secrets. Never expose the service role key in a browser or WordPress page.
6. Add an approved notification provider and authorised responder escalation policy; the function currently creates in-app notification records only.

## Security decisions

- Every exposed data table has RLS enabled.
- Anonymous users receive no table privileges.
- Direct write access is deliberately narrow: students can submit their own SOS request and members can submit incident reports.
- Incident information is only visible to its reporter and authorised institutional responders.
- Guardians do not automatically see incident reports.
- Sensitive behaviour, bullying, ragging, medical and wellbeing cases need authorised human review.

## Verification after deployment

Test with separate Student, Guardian, Teacher and Security accounts. Confirm that each account can only read its permitted rows, an SOS creates an event, only authorised responders receive in-app notifications, and no `anon` request can access data.

