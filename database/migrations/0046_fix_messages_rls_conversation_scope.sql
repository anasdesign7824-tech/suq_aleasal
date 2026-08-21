-- TASK 001: bind message participant checks to the row's conversation.
-- This migration changes only the two participant policies. It does not alter
-- the RPC write path, sender ownership, admin access, or message schema.

begin;

drop policy if exists messages_participant_insert on public.messages;
create policy messages_participant_insert
on public.messages
for insert
to public
with check (
  sender_id = auth.uid()
  and exists (
    select 1
    from public.conversation_participants cp
    where cp.conversation_id = messages.conversation_id
      and cp.user_id = auth.uid()
  )
);

drop policy if exists messages_participant_select on public.messages;
create policy messages_participant_select
on public.messages
for select
to public
using (
  sender_id = auth.uid()
  or exists (
    select 1
    from public.conversation_participants cp
    where cp.conversation_id = messages.conversation_id
      and cp.user_id = auth.uid()
  )
  or private.is_admin()
);

commit;
