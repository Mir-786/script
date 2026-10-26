-- DuoDesk Supabase schema
-- Run in Supabase Dashboard → SQL Editor.
-- Then enable Realtime for both tables (Database → Replication / Publications).
-- Browser code must use only the anon/publishable key, never service_role.

create extension if not exists pgcrypto;

create table if not exists public.work_items (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 160),
  description text not null default '',
  stage text not null default 'Idea' check (stage in ('Idea','Script','Shoot','Edit','Public')),
  assignee text not null default 'Miraj' check (assignee in ('Miraj','Moyna')),
  due_date date,
  priority text not null default 'Normal' check (priority in ('Low','Normal','High','Urgent')),
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.workspace_pages (
  id uuid primary key default gen_random_uuid(),
  title text not null default 'Untitled' check (char_length(title) between 1 and 140),
  content text not null default '',
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.work_items enable row level security;
alter table public.workspace_pages enable row level security;

-- This private two-person workspace allows only the two intended Auth accounts.
-- Ensure the matching emails are exactly these values in Supabase Auth.
drop policy if exists "Duo partners can read work" on public.work_items;
create policy "Duo partners can read work" on public.work_items for select to authenticated
using ((auth.jwt() ->> 'email') in ('miraj@duodesk.app','moyna@duodesk.app'));

drop policy if exists "Duo partners can add work" on public.work_items;
create policy "Duo partners can add work" on public.work_items for insert to authenticated
with check ((auth.jwt() ->> 'email') in ('miraj@duodesk.app','moyna@duodesk.app')
  and created_by = auth.uid());

drop policy if exists "Duo partners can update work" on public.work_items;
create policy "Duo partners can update work" on public.work_items for update to authenticated
using ((auth.jwt() ->> 'email') in ('miraj@duodesk.app','moyna@duodesk.app'))
with check ((auth.jwt() ->> 'email') in ('miraj@duodesk.app','moyna@duodesk.app'));

drop policy if exists "Duo partners can delete work" on public.work_items;
create policy "Duo partners can delete work" on public.work_items for delete to authenticated
using ((auth.jwt() ->> 'email') in ('miraj@duodesk.app','moyna@duodesk.app'));

drop policy if exists "Duo partners can read pages" on public.workspace_pages;
create policy "Duo partners can read pages" on public.workspace_pages for select to authenticated
using ((auth.jwt() ->> 'email') in ('miraj@duodesk.app','moyna@duodesk.app'));

drop policy if exists "Duo partners can add pages" on public.workspace_pages;
create policy "Duo partners can add pages" on public.workspace_pages for insert to authenticated
with check ((auth.jwt() ->> 'email') in ('miraj@duodesk.app','moyna@duodesk.app')
  and created_by = auth.uid());

drop policy if exists "Duo partners can update pages" on public.workspace_pages;
create policy "Duo partners can update pages" on public.workspace_pages for update to authenticated
using ((auth.jwt() ->> 'email') in ('miraj@duodesk.app','moyna@duodesk.app'))
with check ((auth.jwt() ->> 'email') in ('miraj@duodesk.app','moyna@duodesk.app'));

drop policy if exists "Duo partners can delete pages" on public.workspace_pages;
create policy "Duo partners can delete pages" on public.workspace_pages for delete to authenticated
using ((auth.jwt() ->> 'email') in ('miraj@duodesk.app','moyna@duodesk.app'));

create index if not exists work_items_due_date_idx on public.work_items (due_date);
create index if not exists work_items_updated_at_idx on public.work_items (updated_at desc);
create index if not exists workspace_pages_updated_at_idx on public.workspace_pages (updated_at desc);

-- Optional updated_at trigger
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;
drop trigger if exists work_items_set_updated_at on public.work_items;
create trigger work_items_set_updated_at before update on public.work_items
for each row execute function public.set_updated_at();
drop trigger if exists workspace_pages_set_updated_at on public.workspace_pages;
create trigger workspace_pages_set_updated_at before update on public.workspace_pages
for each row execute function public.set_updated_at();

-- In Supabase Dashboard, add work_items and workspace_pages to the supabase_realtime publication.
