-- Safe to run more than once. Run just this in the Supabase SQL Editor.
-- Members directory: profile fields, who can read and edit profiles
alter table profiles add column if not exists bio text, add column if not exists program text;
drop policy if exists "profiles members read" on profiles;
create policy "profiles members read" on profiles for select to authenticated using (my_role() in ('member','admin') and role in ('member','admin'));
drop policy if exists "profiles update own" on profiles;
create policy "profiles update own"   on profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
-- Safety net: only an admin can ever change a role
create or replace function public.guard_role() returns trigger language plpgsql security definer set search_path = public as $$
begin if new.role is distinct from old.role and auth.uid() is not null and my_role() is distinct from 'admin' then raise exception 'Only an admin can change roles'; end if; return new; end $$;
drop trigger if exists guard_role on profiles;
create trigger guard_role before update on profiles for each row execute function public.guard_role();
