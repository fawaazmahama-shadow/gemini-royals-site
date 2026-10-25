-- Safe to run more than once. Run just this in the Supabase SQL Editor.
-- Class recordings: only admins add or delete; members and admins watch and download
create table if not exists recordings (id bigint generated always as identity primary key, title text not null, class_id bigint references classes on delete set null, url text not null, created_by uuid default auth.uid(), created_at timestamptz default now());
alter table recordings enable row level security;
drop policy if exists "recordings read" on recordings;
create policy "recordings read"   on recordings for select to authenticated using (my_role() in ('member','admin'));
drop policy if exists "recordings insert" on recordings;
create policy "recordings insert" on recordings for insert to authenticated with check (my_role() = 'admin');
drop policy if exists "recordings delete" on recordings;
create policy "recordings delete" on recordings for delete to authenticated using (my_role() = 'admin');
