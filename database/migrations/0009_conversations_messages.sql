create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  created_by uuid not null references public.users(id) on delete cascade,
  last_message_at timestamptz,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.conversation_participants (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (conversation_id, user_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.users(id) on delete cascade,
  body text not null,
  read_at timestamptz,
  created_at timestamptz not null default timezone('utc', now())
);

alter table public.conversations enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.messages enable row level security;

create policy conversations_participant_select on public.conversations for select using (
  created_by = (select auth.uid()) or exists (select 1 from public.conversation_participants cp where cp.conversation_id = id and cp.user_id = (select auth.uid())) or (select public.is_admin())
);
create policy conversations_participant_insert on public.conversations for insert with check (created_by = (select auth.uid()) or (select public.is_admin()));
create policy conversations_participant_update on public.conversations for update using (created_by = (select auth.uid()) or (select public.is_admin())) with check (created_by = (select auth.uid()) or (select public.is_admin()));
create policy conversation_participants_self_select on public.conversation_participants for select using (user_id = (select auth.uid()) or (select public.is_admin()));
create policy conversation_participants_self_insert on public.conversation_participants for insert with check (user_id = (select auth.uid()) or (select public.is_admin()));
create policy messages_participant_select on public.messages for select using (sender_id = (select auth.uid()) or exists (select 1 from public.conversation_participants cp where cp.conversation_id = conversation_id and cp.user_id = (select auth.uid())) or (select public.is_admin()));
create policy messages_participant_insert on public.messages for insert with check (sender_id = (select auth.uid()) and exists (select 1 from public.conversation_participants cp where cp.conversation_id = conversation_id and cp.user_id = (select auth.uid())));
create policy messages_sender_update on public.messages for update using (sender_id = (select auth.uid()) or (select public.is_admin())) with check (sender_id = (select auth.uid()) or (select public.is_admin()));
create policy messages_sender_delete on public.messages for delete using (sender_id = (select auth.uid()) or (select public.is_admin()));

create index if not exists conversations_store_id_idx on public.conversations(store_id, last_message_at desc);
create index if not exists conversation_participants_user_id_idx on public.conversation_participants(user_id, conversation_id);
create index if not exists messages_conversation_id_idx on public.messages(conversation_id, created_at);
