-- Gemini Royals database setup. Run in Supabase: SQL Editor > New query > Run.
-- WARNING: this ERASES all existing site data (events, photos, resources, classes, attendance,
-- messages, announcements, assignments, guestbook, settings and member profiles) before rebuilding.
-- Login accounts are kept, but everyone is reset to 'pending' except fawaazmahama@gmail.com, who becomes admin.
-- Uploaded files in Storage are not touched by SQL: empty the 'files' bucket in Dashboard > Storage if you want them gone.
drop table if exists backgrounds, recordings, messages, announcements, assignments, settings, attendance, events, photos, resources, classes, wishes, profiles cascade;
drop trigger if exists on_signup on auth.users;
drop trigger if exists promote_owner on auth.users;

-- Profiles: every sign-up starts as 'pending' until an admin verifies them
create table profiles (id uuid primary key references auth.users on delete cascade, email text, full_name text,
  requested text default 'member', bio text, program text, role text not null default 'pending' check (role in ('pending','guest','member','admin')), created_at timestamptz default now());
create or replace function public.my_role() returns text language sql security definer set search_path = public stable as $$ select role from public.profiles where id = auth.uid() $$;
create or replace function public.on_signup() returns trigger language plpgsql security definer set search_path = public as $$
begin insert into profiles (id, email, full_name, requested) values (new.id, new.email, new.raw_user_meta_data->>'full_name', coalesce(new.raw_user_meta_data->>'requested','member')); return new; end $$;
create trigger on_signup after insert on auth.users for each row execute function public.on_signup();

-- The owner's account is always the admin (only once the email address is confirmed)
create or replace function public.promote_owner() returns trigger language plpgsql security definer set search_path = public as $$
begin if lower(new.email) = 'fawaazmahama@gmail.com' and new.email_confirmed_at is not null then update public.profiles set role = 'admin' where id = new.id; end if; return new; end $$;
create trigger promote_owner after insert or update of email_confirmed_at on auth.users for each row execute function public.promote_owner();

create table events    (id bigint generated always as identity primary key, title text not null, note text, event_date timestamptz not null, created_by uuid default auth.uid(), created_at timestamptz default now());
create table photos    (id bigint generated always as identity primary key, caption text, url text not null, created_by uuid default auth.uid(), created_at timestamptz default now());
create table resources (id bigint generated always as identity primary key, title text not null, subject text, url text, created_by uuid default auth.uid(), created_at timestamptz default now());
create table classes   (id bigint generated always as identity primary key, title text not null, starts_at timestamptz not null, guests boolean default false, meet text,
  room text not null default replace(gen_random_uuid()::text,'-',''), created_by uuid default auth.uid(), created_at timestamptz default now());
create table attendance(id bigint generated always as identity primary key, class_id bigint references classes on delete cascade, user_id uuid default auth.uid(), email text, name text, created_at timestamptz default now(), unique (class_id, user_id));
create table wishes    (id bigint generated always as identity primary key, name text not null, message text not null, created_at timestamptz default now());

alter table profiles enable row level security;
create policy "profiles read"   on profiles for select to authenticated using (id = auth.uid() or my_role() = 'admin');
create policy "profiles update" on profiles for update to authenticated using (my_role() = 'admin');

-- Members directory: profile fields, who can read and edit profiles
create policy "profiles members read" on profiles for select to authenticated using (my_role() in ('member','admin') and role in ('member','admin'));
create policy "profiles update own"   on profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
-- Safety net: only an admin can ever change a role
create or replace function public.guard_role() returns trigger language plpgsql security definer set search_path = public as $$
begin if new.role is distinct from old.role and auth.uid() is not null and my_role() is distinct from 'admin' then raise exception 'Only an admin can change roles'; end if; return new; end $$;
drop trigger if exists guard_role on profiles;
create trigger guard_role before update on profiles for each row execute function public.guard_role();

-- Full members and admins: timeline, memories, resources
do $$ declare t text; begin
  foreach t in array array['events','photos','resources'] loop
    execute format('alter table %I enable row level security', t);
    execute format('create policy "%1$s read"   on %1$I for select to authenticated using (my_role() in (''member'',''admin''))', t);
    execute format('create policy "%1$s insert" on %1$I for insert to authenticated with check (my_role() in (''member'',''admin''))', t);
    execute format('create policy "%1$s delete" on %1$I for delete to authenticated using (created_by = auth.uid() or my_role() = ''admin'')', t);
  end loop; end $$;

-- Classes: members/admins see all; one-time guests only see classes opened to guests (room names are random secrets)
alter table classes enable row level security;
create policy "classes read"   on classes for select to authenticated using (my_role() in ('member','admin') or (my_role() = 'guest' and guests));
create policy "classes insert" on classes for insert to authenticated with check (my_role() in ('member','admin'));
create policy "classes delete" on classes for delete to authenticated using (created_by = auth.uid() or my_role() = 'admin');

alter table attendance enable row level security;
create policy "attendance insert" on attendance for insert to authenticated with check (my_role() in ('member','admin','guest') and user_id = auth.uid());
create policy "attendance read"   on attendance for select to authenticated using (user_id = auth.uid() or my_role() = 'admin');

-- Guestbook: anyone can read and write; admin can delete
alter table wishes enable row level security;
create policy "wishes read"   on wishes for select to anon, authenticated using (true);
create policy "wishes insert" on wishes for insert to anon, authenticated with check (true);
create policy "wishes delete" on wishes for delete to authenticated using (my_role() = 'admin');

insert into storage.buckets (id, name, public) values ('files','files',true) on conflict do nothing;
drop policy if exists "files upload" on storage.objects;
create policy "files upload" on storage.objects for insert to authenticated with check (bucket_id = 'files' and my_role() in ('member','admin'));

-- Group chat, announcements and assignments
create table messages      (id bigint generated always as identity primary key, body text not null, author_name text, created_by uuid default auth.uid(), created_at timestamptz default now());
create table announcements (id bigint generated always as identity primary key, title text not null, body text not null, created_by uuid default auth.uid(), created_at timestamptz default now());
create table assignments   (id bigint generated always as identity primary key, title text not null, course text, due_at timestamptz not null, note text, created_by uuid default auth.uid(), created_at timestamptz default now());
do $$ declare t text; begin
  foreach t in array array['messages','assignments'] loop
    execute format('alter table %I enable row level security', t);
    execute format('create policy "%1$s read"   on %1$I for select to authenticated using (my_role() in (''member'',''admin''))', t);
    execute format('create policy "%1$s insert" on %1$I for insert to authenticated with check (my_role() in (''member'',''admin''))', t);
    execute format('create policy "%1$s delete" on %1$I for delete to authenticated using (created_by = auth.uid() or my_role() = ''admin'')', t);
  end loop; end $$;
alter table announcements enable row level security;
create policy "announcements read"   on announcements for select to authenticated using (my_role() in ('member','admin'));
create policy "announcements insert" on announcements for insert to authenticated with check (my_role() = 'admin');
create policy "announcements delete" on announcements for delete to authenticated using (my_role() = 'admin');

-- Class recordings: only admins add or delete; members and admins watch and download
create table recordings (id bigint generated always as identity primary key, title text not null, class_id bigint references classes on delete set null, url text not null, created_by uuid default auth.uid(), created_at timestamptz default now());
alter table recordings enable row level security;
create policy "recordings read"   on recordings for select to authenticated using (my_role() in ('member','admin'));
create policy "recordings insert" on recordings for insert to authenticated with check (my_role() = 'admin');
create policy "recordings delete" on recordings for delete to authenticated using (my_role() = 'admin');

-- Background slideshow: anyone can see it (it shows on every page); only admins add or delete
create table backgrounds (id bigint generated always as identity primary key, url text not null, kind text not null default 'image' check (kind in ('image','video')), created_by uuid default auth.uid(), created_at timestamptz default now());
alter table backgrounds enable row level security;
create policy "backgrounds read"   on backgrounds for select to anon, authenticated using (true);
create policy "backgrounds insert" on backgrounds for insert to authenticated with check (my_role() = 'admin');
create policy "backgrounds delete" on backgrounds for delete to authenticated using (my_role() = 'admin');

-- Members-only settings (holds the private WhatsApp group link, so it never appears in the page source)
create table settings (key text primary key, value text not null, created_at timestamptz default now());
alter table settings enable row level security;
create policy "settings read" on settings for select to authenticated using (my_role() in ('member','admin'));
insert into settings (key, value) values ('whatsapp', 'PASTE_WHATSAPP_GROUP_LINK_HERE')
  on conflict (key) do update set value = excluded.value;

-- Rebuild a profile for every existing login account. Everyone starts as 'pending' except the owner, who is the admin.
insert into profiles (id, email, full_name, requested, role)
select id, email, raw_user_meta_data->>'full_name', coalesce(raw_user_meta_data->>'requested','member'),
       case when lower(email) = 'fawaazmahama@gmail.com' then 'admin' else 'pending' end
from auth.users on conflict (id) do nothing;

-- Check: this should list fawaazmahama@gmail.com as admin (if you have already signed up with it).
-- If it is empty, sign up on the site with that email, confirm the email, and you become admin automatically.
select email, role from profiles where role = 'admin';
