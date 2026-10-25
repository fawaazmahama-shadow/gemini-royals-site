-- Already ran schema.sql earlier? Run just this in the Supabase SQL Editor.
-- Class recordings: only admins add or delete; members and admins watch and download
create table recordings (id bigint generated always as identity primary key, title text not null, class_id bigint references classes on delete set null, url text not null, created_by uuid default auth.uid(), created_at timestamptz default now());
alter table recordings enable row level security;
create policy "recordings read"   on recordings for select to authenticated using (my_role() in ('member','admin'));
create policy "recordings insert" on recordings for insert to authenticated with check (my_role() = 'admin');
create policy "recordings delete" on recordings for delete to authenticated using (my_role() = 'admin');
