-- Already ran schema.sql earlier? Run just this in the Supabase SQL Editor.
-- Background slideshow: anyone can see it (it shows on every page); only admins add or delete
create table backgrounds (id bigint generated always as identity primary key, url text not null, kind text not null default 'image' check (kind in ('image','video')), created_by uuid default auth.uid(), created_at timestamptz default now());
alter table backgrounds enable row level security;
create policy "backgrounds read"   on backgrounds for select to anon, authenticated using (true);
create policy "backgrounds insert" on backgrounds for insert to authenticated with check (my_role() = 'admin');
create policy "backgrounds delete" on backgrounds for delete to authenticated using (my_role() = 'admin');
