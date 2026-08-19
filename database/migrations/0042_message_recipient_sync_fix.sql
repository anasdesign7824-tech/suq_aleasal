-- Deliver message notifications to the other participant in both directions.
create or replace function public.customer_send_message(
  p_conversation_id uuid,
  p_body text
)
returns jsonb
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_message public.messages%rowtype;
  v_store_id uuid;
  v_recipient_id uuid;
  v_store_name text;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'authentication_required';
  end if;
  if nullif(trim(p_body), '') is null then
    raise exception using errcode = '22023', message = 'message_empty';
  end if;

  select c.store_id, s.name_ar
    into v_store_id, v_store_name
    from public.conversations c
    join public.stores s on s.id = c.store_id
   where c.id = p_conversation_id
     and exists (
       select 1 from public.conversation_participants cp
        where cp.conversation_id = c.id and cp.user_id = v_user_id
     )
   for update;

  if v_store_id is null then
    raise exception using errcode = '42501', message = 'conversation_not_owned';
  end if;

  select cp.user_id
    into v_recipient_id
    from public.conversation_participants cp
   where cp.conversation_id = p_conversation_id
     and cp.user_id <> v_user_id
   order by cp.created_at
   limit 1;

  insert into public.messages (conversation_id, sender_id, body)
  values (p_conversation_id, v_user_id, trim(p_body))
  returning * into v_message;

  update public.conversations
     set last_message_at = v_message.created_at
   where id = p_conversation_id;

  if v_recipient_id is not null then
    insert into public.notifications (user_id, notification_type, title_ar, body_ar, payload)
    values (
      v_recipient_id,
      'message_received',
      'رسالة جديدة',
      'وصلت رسالة جديدة من أحد أطراف المحادثة.',
      jsonb_build_object('conversation_id', p_conversation_id, 'store_id', v_store_id)
    );
  end if;

  return jsonb_build_object(
    'id', v_message.id,
    'conversation_id', v_message.conversation_id,
    'sender_id', v_message.sender_id,
    'body', v_message.body,
    'read_at', v_message.read_at,
    'created_at', v_message.created_at,
    'sent_at', v_message.created_at,
    'is_mine', true,
    'store_name', coalesce(v_store_name, 'متجر عسلكم')
  );
end;
$$;
