-- Create a minimal application profile whenever a Supabase Auth user signs up.
-- User metadata is used only for display text, never for authorisation.

create or replace function app_private.handle_new_user()
returns trigger language plpgsql security definer set search_path = public, auth as $$
begin
  insert into public.profiles (user_id, display_name)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''), split_part(coalesce(new.email, 'member'), '@', 1), 'Member')
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

revoke all on function app_private.handle_new_user() from public;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function app_private.handle_new_user();

