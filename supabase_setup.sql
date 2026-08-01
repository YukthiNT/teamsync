-- TeamSync database setup for Supabase.
-- Run this whole file in your Supabase project's SQL Editor
-- (left sidebar -> SQL Editor -> New query -> paste this in -> Run).

-- ---------------- TABLES ----------------

create table if not exists messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null,
  sender_name text not null,
  text text not null,
  created_at timestamptz not null default now()
);

create table if not exists presence (
  user_id uuid primary key,
  display_name text not null,
  is_online boolean not null default true,
  last_seen timestamptz not null default now()
);

create table if not exists tasks (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  created_by text not null,
  status text not null default 'todo',
  created_at timestamptz not null default now()
);

-- ---------------- ROW LEVEL SECURITY ----------------
-- RLS is on by default for new tables in most Supabase projects, but we
-- enable it explicitly here to be safe, then add policies that allow any
-- signed-in user (including anonymous sign-ins) to read/write.

alter table messages enable row level security;
alter table presence enable row level security;
alter table tasks enable row level security;

-- Messages: any authenticated user can read all messages and create new
-- ones (only as themselves). Messages are immutable once sent.
create policy "Authenticated users can read messages"
  on messages for select
  to authenticated
  using (true);

create policy "Users can send messages as themselves"
  on messages for insert
  to authenticated
  with check (auth.uid() = sender_id);

-- Presence: any authenticated user can read everyone's presence, but can
-- only write their own row.
create policy "Authenticated users can read presence"
  on presence for select
  to authenticated
  using (true);

create policy "Users can upsert their own presence"
  on presence for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update their own presence"
  on presence for update
  to authenticated
  using (auth.uid() = user_id);

-- Tasks: any authenticated user can read, create, and update tasks
-- (simple shared team board, no per-user ownership).
create policy "Authenticated users can read tasks"
  on tasks for select
  to authenticated
  using (true);

create policy "Authenticated users can create tasks"
  on tasks for insert
  to authenticated
  with check (true);

create policy "Authenticated users can update tasks"
  on tasks for update
  to authenticated
  using (true);

-- ---------------- REALTIME ----------------
-- Adds these tables to Supabase's realtime publication so the app's
-- .stream() calls receive live updates over the websocket connection.

alter publication supabase_realtime add table messages;
alter publication supabase_realtime add table presence;
alter publication supabase_realtime add table tasks;
