-- Safe to run more than once. Run just this in the Supabase SQL Editor.
-- Background slideshow: anyone can see it (it shows on every page); only admins add or delete
create table if not exists backgrounds (id bigint generated always as identity primary key, url text not null, kind text not null default 'image' check (kind in ('image','video')), created_by uuid default auth.uid(), created_at timestamptz default now());
alter table backgrounds enable row level security;
drop policy if exists "backgrounds read" on backgrounds;
create policy "backgrounds read"   on backgrounds for select to anon, authenticated using (true);
drop policy if exists "backgrounds insert" on backgrounds;
create policy "backgrounds insert" on backgrounds for insert to authenticated with check (my_role() = 'admin');
drop policy if exists "backgrounds delete" on backgrounds;
create policy "backgrounds delete" on backgrounds for delete to authenticated using (my_role() = 'admin');
