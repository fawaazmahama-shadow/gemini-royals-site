-- Already ran schema.sql? Run just this in the Supabase SQL Editor.
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
