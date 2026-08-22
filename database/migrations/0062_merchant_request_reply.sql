-- REQ-01: merchant reply to a customer request.
-- The merchant identity is always derived from auth.uid().
-- The operation inserts one request message, answers the request, and notifies the requester atomically.

begin;

alter table public.request_messages
  add column if not exists response_code text;

do $$
begin
  if not exists (
    select 1
      from pg_constraint
     where conrelid = 'public.request_messages'::regclass
       and conname = 'request_messages_response_code_check'
  ) then
    alter table public.request_messages
      add constraint request_messages_response_code_check
      check (response_code is null or response_code in ('available', 'unavailable', 'contact_required'));
  end if;
end;
$$;

create or replace function public.merchant_reply_to_request(
  p_request_id uuid,
  p_body text,
  p_response_code text default 'contact_required',
  p_mutation_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  v_merchant_id uuid := auth.uid();
  v_request public.requests%rowtype;
  v_message public.request_messages%rowtype;
  v_store_name text;
  v_store_merchant_id uuid;
  v_body text := nullif(trim(coalesce(p_body, '')), '');
  v_response_code text := coalesce(nullif(trim(coalesce(p_response_code, '')), ''), 'contact_required');
  v_key text := nullif(trim(coalesce(p_mutation_key, '')), '');
  v_result_id uuid;
  v_notification_id uuid;
begin
  if v_merchant_id is null then
    raise exception using errcode = '42501', message = 'authentication_required';
  end if;

  if p_request_id is null then
    raise exception using errcode = '22023', message = 'request_id_required';
  end if;

  if v_body is null then
    raise exception using errcode = '22023', message = 'reply_body_empty';
  end if;
  if char_length(v_body) > 5000 then
    raise exception using errcode = '22023', message = 'reply_body_too_long';
  end if;
  if v_response_code not in ('available', 'unavailable', 'contact_required') then
    raise exception using errcode = '22023', message = 'reply_code_invalid';
  end if;

  if v_key is null then
    v_key := md5(
      v_merchant_id::text || ':request.reply:' || p_request_id::text || ':' ||
      v_response_code || ':' || v_body
    );
  end if;
  if char_length(v_key) > 128 then
    raise exception using errcode = '22023', message = 'mutation_key_too_long';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(v_merchant_id::text || ':request.reply:' || v_key, 0)
  );

  select cm.result_id
    into v_result_id
    from private.client_mutations cm
   where cm.user_id = v_merchant_id
     and cm.operation = 'request.reply'
     and cm.mutation_key = v_key
   for update;

  if v_result_id is not null then
    select rm.*
      into v_message
      from public.request_messages rm
     where rm.id = v_result_id
       and rm.sender_id = v_merchant_id
       and rm.request_id = p_request_id;
    if not found then
      raise exception using errcode = 'P0002', message = 'mutation_result_unavailable';
    end if;

    select r.*
      into v_request
      from public.requests r
     where r.id = p_request_id;
    select s.name_ar, s.merchant_id
      into v_store_name, v_store_merchant_id
      from public.stores s
     where s.id = v_request.store_id;

    return jsonb_build_object(
      'id', v_message.id,
      'request_id', v_message.request_id,
      'sender_id', v_message.sender_id,
      'body', v_message.body,
      'response_code', v_message.response_code,
      'created_at', v_message.created_at,
      'requester_id', v_request.requester_id,
      'store_id', v_request.store_id,
      'store_name', coalesce(v_store_name, 'متجر عسلكم'),
      'request_status', v_request.status,
      'notification_id', null
    );
  end if;

  select r.*
    into v_request
    from public.requests r
   where r.id = p_request_id
   for update;
  if found then
    select s.name_ar, s.merchant_id
      into v_store_name, v_store_merchant_id
      from public.stores s
     where s.id = v_request.store_id;
  end if;

  if not found or v_store_merchant_id <> v_merchant_id then
    raise exception using errcode = '42501', message = 'request_not_owned';
  end if;

  if v_request.status in ('closed', 'cancelled') then
    raise exception using errcode = '22023', message = 'request_not_replyable';
  end if;

  insert into public.request_messages (
    request_id,
    sender_id,
    body,
    response_code
  ) values (
    p_request_id,
    v_merchant_id,
    v_body,
    v_response_code
  ) returning * into v_message;

  update public.requests
     set status = 'answered',
         updated_at = timezone('utc', now())
   where id = p_request_id;

  if v_request.requester_id <> v_merchant_id then
    insert into public.notifications (
      user_id,
      notification_type,
      title_ar,
      body_ar,
      payload
    ) values (
      v_request.requester_id,
      'request_answered',
      'رد جديد على طلبك',
      case v_response_code
        when 'available' then 'أفاد التاجر بأن المنتج متوفر.'
        when 'unavailable' then 'أفاد التاجر بأن المنتج غير متوفر حاليًا.'
        else 'أرسل التاجر ردًا على طلبك؛ افتح الطلب لمعرفة التفاصيل.'
      end,
      jsonb_build_object(
        'request_id', p_request_id,
        'store_id', v_request.store_id,
        'response_code', v_response_code
      )
    ) returning id into v_notification_id;
  end if;

  insert into private.client_mutations (
    user_id,
    operation,
    mutation_key,
    result_id
  ) values (
    v_merchant_id,
    'request.reply',
    v_key,
    v_message.id
  );

  return jsonb_build_object(
    'id', v_message.id,
    'request_id', v_message.request_id,
    'sender_id', v_message.sender_id,
    'body', v_message.body,
    'response_code', v_message.response_code,
    'created_at', v_message.created_at,
    'requester_id', v_request.requester_id,
    'store_id', v_request.store_id,
    'store_name', coalesce(v_store_name, 'متجر عسلكم'),
    'request_status', 'answered',
    'notification_id', v_notification_id
  );
end;
$$;

revoke all on function public.merchant_reply_to_request(uuid, text, text, text) from public, anon;
grant execute on function public.merchant_reply_to_request(uuid, text, text, text) to authenticated;

create index if not exists request_messages_request_created_idx
  on public.request_messages(request_id, created_at desc);

commit;
