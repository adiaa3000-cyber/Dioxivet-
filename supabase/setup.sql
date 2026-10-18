-- Dioxivet Academy setup for the existing Supabase project.
-- Run once in Supabase SQL Editor. This script is designed to be re-runnable.
-- It does not delete existing tables, rows, or storage objects.

create extension if not exists pgcrypto;

create table if not exists public.lessons (
  id uuid primary key default gen_random_uuid(),
  title text not null default 'محاضرة جديدة',
  description text not null default '',
  content_type text not null default 'video',
  content_url text,
  storage_path text not null default 'azareet.mp4.mp4',
  created_at timestamptz not null default now()
);

alter table public.lessons
  add column if not exists title text,
  add column if not exists description text default '',
  add column if not exists content_type text default 'video',
  add column if not exists content_url text,
  add column if not exists storage_path text default 'azareet.mp4.mp4',
  add column if not exists created_at timestamptz default now();

update public.lessons set title = 'محاضرة جديدة' where title is null;
update public.lessons set description = '' where description is null;
update public.lessons set content_type = 'video' where content_type is null;
update public.lessons set storage_path = 'azareet.mp4.mp4'
  where storage_path is null or storage_path = '';
update public.lessons set created_at = now() where created_at is null;

alter table public.lessons
  alter column title set default 'محاضرة جديدة',
  alter column title set not null,
  alter column description set default '',
  alter column content_type set default 'video',
  alter column content_type set not null,
  alter column storage_path set default 'azareet.mp4.mp4',
  alter column created_at set default now();

alter table public.lessons enable row level security;

drop policy if exists "Public can read lessons" on public.lessons;
create policy "Public can read lessons"
  on public.lessons for select
  to anon, authenticated
  using (true);

-- Make sure the existing video bucket exists. Public read is used by this
-- starter app; do not store private/student data in this bucket.
insert into storage.buckets (id, name, public)
values ('lecture-videos', 'lecture-videos', true)
on conflict (id) do update set public = true;

drop policy if exists "Public can read lecture videos" on storage.objects;
create policy "Public can read lecture videos"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'lecture-videos');

-- Add a starter lesson only when no row already references this video.
insert into public.lessons (title, description, content_type, storage_path)
select 'محاضرة الأزياريت', 'المحاضرة التجريبية على Dioxivet Academy', 'video', 'azareet.mp4.mp4'
where not exists (
  select 1 from public.lessons where storage_path = 'azareet.mp4.mp4'
);
