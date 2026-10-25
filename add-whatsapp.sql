-- Safe to run more than once. Run just this in the Supabase SQL Editor.
-- Members-only settings (holds the private WhatsApp group link, so it never appears in the page source)
create table if not exists settings (key text primary key, value text not null, created_at timestamptz default now());
alter table settings enable row level security;
drop policy if exists "settings read" on settings;
create policy "settings read" on settings for select to authenticated using (my_role() in ('member','admin'));
insert into settings (key, value) values ('whatsapp', 'PASTE_WHATSAPP_GROUP_LINK_HERE')
  on conflict (key) do update set value = excluded.value;
