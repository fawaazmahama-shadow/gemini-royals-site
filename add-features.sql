-- Safe to run more than once. Run just this in the Supabase SQL Editor.
-- Group chat, announcements and assignments
create table if not exists messages      (id bigint generated always as identity primary key, body text not null, author_name text, created_by uuid default auth.uid(), created_at timestamptz default now());
create table if not exists announcements (id bigint generated always as identity primary key, title text not null, body text not null, created_by uuid default auth.uid(), created_at timestamptz default now());
create table if not exists assignments   (id bigint generated always as identity primary key, title text not null, course text, due_at timestamptz not null, note text, created_by uuid default auth.uid(), created_at timestamptz default now());
do $$ declare t text; begin
  foreach t in array array['messages','assignments'] loop
    execute format('alter table %I enable row level security', t);
    execute format('drop policy if exists "%1$s read" on %1$I', t);
    execute format('create policy "%1$s read"   on %1$I for select to authenticated using (my_role() in (''member'',''admin''))', t);
    execute format('drop policy if exists "%1$s insert" on %1$I', t);
    execute format('create policy "%1$s insert" on %1$I for insert to authenticated with check (my_role() in (''member'',''admin''))', t);
    execute format('drop policy if exists "%1$s delete" on %1$I', t);
    execute format('create policy "%1$s delete" on %1$I for delete to authenticated using (created_by = auth.uid() or my_role() = ''admin'')', t);
  end loop; end $$;
alter table announcements enable row level security;
drop policy if exists "announcements read" on announcements;
create policy "announcements read"   on announcements for select to authenticated using (my_role() in ('member','admin'));
drop policy if exists "announcements insert" on announcements;
create policy "announcements insert" on announcements for insert to authenticated with check (my_role() = 'admin');
drop policy if exists "announcements delete" on announcements;
create policy "announcements delete" on announcements for delete to authenticated using (my_role() = 'admin');
