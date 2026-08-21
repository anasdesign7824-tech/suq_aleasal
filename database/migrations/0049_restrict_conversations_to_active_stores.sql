-- 0049_restrict_conversations_to_active_stores.sql
-- TASK 017: A conversation must not be opened against a pending, rejected,
-- suspended, or otherwise inactive store. Preserve the existing authenticated
-- RPC contract and derive the caller from auth.uid().

create or replace function public.customer_create_conversation(p_store_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_merchant_id uuid;
  v_conversation public.conversations%rowtype;
  v_store_name text;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'authentication_required';
  end if;

  select s.merchant_id, s.name_ar
    into v_merchant_id, v_store_name
    from public.stores s
   where s.id = p_store_id
     and s.status = 'active';

  if v_merchant_id is null then
    raise exception using errcode = 'P0002', message = 'store_not_found';
  end if;

  if v_merchant_id = v_user_id then
    raise exception using errcode = '22023', message = 'cannot_message_own_store';
  end if;

  select c.*
    into v_conversation
    from public.conversations c
   where c.store_id = p_store_id
     and c.created_by = v_user_id
   order by c.created_at desc
   limit 1
   for update;

  if v_conversation.id is null then
    insert into public.conversations (store_id, created_by)
    values (p_store_id, v_user_id)
    returning * into v_conversation;
  end if;

  insert into public.conversation_participants (conversation_id, user_id)
  values (v_conversation.id, v_user_id), (v_conversation.id, v_merchant_id)
  on conflict (conversation_id, user_id) do nothing;

  return jsonb_build_object(
    'id', v_conversation.id,
    'store_id', v_conversation.store_id,
    'created_by', v_conversation.created_by,
    'last_message_at', v_conversation.last_message_at,
    'created_at', v_conversation.created_at,
    'store_name', coalesce(v_store_name, 'متجر عسلكم'),
    'last_message', 'ابدأ محادثة جديدة',
    'updated_at', coalesce(v_conversation.last_message_at, v_conversation.created_at),
    'participant_ids', jsonb_build_array(v_user_id, v_merchant_id)
  );
end;
$$;

revoke all on function public.customer_create_conversation(uuid) from public, anon;
grant execute on function public.customer_create_conversation(uuid) to authenticated;
