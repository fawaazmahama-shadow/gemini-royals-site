-- Safe to run more than once. Run just this in the Supabase SQL Editor.
alter table classes add column if not exists meet text;
