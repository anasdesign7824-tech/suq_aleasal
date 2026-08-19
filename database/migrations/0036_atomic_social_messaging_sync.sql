-- Atomic social, messaging, and request operations.
-- All public RPCs are authenticated-only and derive the acting user from auth.uid().

create or replace function private.sync_store_follower_count(p_store_id uuid)
returns void
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
begin
  update public.store_statistics
     set followers_count = (
           select count(*)::integer
           from public.store_followers
           where store_id = p_store_id
         ),
         updated_at = timezone('utc', now())
   where store_id = p_store_id;

  if not found then
    insert into public.store_statistics (store_id, followers_count)
    values (
      p_store_id,
      (select count(*)::integer from public.store_followers where store_id = p_store_id)
    )
    on conflict (store_id) do update
      set followers_count = excluded.followers_count,
          updated_at = timezone('utc', now());
  end if;
end;
$$;

create or replace function private.sync_product_social_counts(p_product_id uuid)
returns void
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
begin
  update public.products
     set metadata = jsonb_set(
       jsonb_set(
         jsonb_set(
           coalesce(metadata, '{}'::jsonb),
           '{likes_count}',
           to_jsonb((select count(*)::integer from public.product_likes where product_id = p_product_id)),
           true
         ),
         '{review_count}',
         to_jsonb((select count(*)::integer from public.reviews where product_id = p_product_id and status = 'approved')),
         true
       ),
       '{views_count}',
       to_jsonb((select count(*)::integer from public.product_view_events where product_id = p_product_id)),
       true
     ),
     updated_at = timezone('utc', now())
   where id = p_product_id;
end;
$$;

create or replace function private.trg_sync_store_follower_count()
returns trigger
language plpgsql
security invoker
set search_path = public, private, pg_temp
as $$
begin
  perform private.sync_store_follower_count(
    case when TG_OP = 'DELETE' then old.store_id else new.store_id end
  );
  return case when TG_OP = 'DELETE' then old else new end;
end;
$$;

create or replace function private.trg_sync_product_social_counts()
returns trigger
language plpgsql
security invoker
set search_path = public, private, pg_temp
as $$
begin
  perform private.sync_product_social_counts(
    case when TG_OP = 'DELETE' then old.product_id else new.product_id end
  );
  return case when TG_OP = 'DELETE' then old else new end;
end;
$$;

drop trigger if exists store_followers_sync_count on public.store_followers;
create trigger store_followers_sync_count
after insert or delete on public.store_followers
for each row execute function private.trg_sync_store_follower_count();

drop trigger if exists product_likes_sync_count on public.product_likes;
create trigger product_likes_sync_count
after insert or delete on public.product_likes
for each row execute function private.trg_sync_product_social_counts();

drop trigger if exists product_reviews_sync_count on public.reviews;
create trigger product_reviews_sync_count
after insert or update or delete on public.reviews
for each row execute function private.trg_sync_product_social_counts();

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
   where s.id = p_store_id;

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
  v_merchant_id uuid;
  v_store_id uuid;
  v_store_name text;
  v_recipient_id uuid;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'authentication_required';
  end if;
  if nullif(trim(p_body), '') is null then
    raise exception using errcode = '22023', message = 'message_empty';
  end if;

  select c.store_id, s.merchant_id, s.name_ar
    into v_store_id, v_merchant_id, v_store_name
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

  insert into public.messages (conversation_id, sender_id, body)
  values (p_conversation_id, v_user_id, trim(p_body))
  returning * into v_message;

  update public.conversations
     set last_message_at = v_message.created_at
   where id = p_conversation_id;

  v_recipient_id := case when v_user_id = v_merchant_id then null else v_merchant_id end;
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

create or replace function public.customer_create_request(
  p_store_id uuid,
  p_subject text,
  p_body text default null,
  p_preferred_handoff_option text default null,
  p_phone text default null,
  p_contact_channel text default null,
  p_delivery_note text default null,
  p_price_note text default null,
  p_handoff_details jsonb default null,
  p_product_id uuid default null,
  p_quantity integer default 1
)
returns jsonb
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_request public.requests%rowtype;
  v_store_merchant uuid;
  v_store_name text;
  v_quantity integer := greatest(coalesce(p_quantity, 1), 1);
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'authentication_required';
  end if;
  if nullif(trim(p_subject), '') is null then
    raise exception using errcode = '22023', message = 'request_subject_empty';
  end if;

  select s.merchant_id, s.name_ar
    into v_store_merchant, v_store_name
    from public.stores s
   where s.id = p_store_id;
  if v_store_merchant is null then
    raise exception using errcode = 'P0002', message = 'store_not_found';
  end if;

  if p_product_id is not null and not exists (
    select 1 from public.products p
     where p.id = p_product_id and p.store_id = p_store_id
  ) then
    raise exception using errcode = '23503', message = 'product_store_mismatch';
  end if;

  insert into public.requests (
    requester_id, store_id, subject, body, preferred_handoff_option,
    phone, contact_channel, delivery_note, price_note, handoff_details
  ) values (
    v_user_id, p_store_id, trim(p_subject), nullif(trim(p_body), ''),
    p_preferred_handoff_option, p_phone, p_contact_channel, p_delivery_note,
    p_price_note, p_handoff_details
  ) returning * into v_request;

  if p_product_id is not null then
    insert into public.request_items (request_id, product_id, quantity, note)
    values (v_request.id, p_product_id, v_quantity, coalesce(p_price_note, p_delivery_note));
  end if;

  if v_store_merchant <> v_user_id then
    insert into public.notifications (user_id, notification_type, title_ar, body_ar, payload)
    values (
      v_store_merchant,
      'request_created',
      'طلب تواصل جديد',
      'وصل طلب تواصل جديد إلى متجرك.',
      jsonb_build_object('request_id', v_request.id, 'store_id', p_store_id)
    );
  end if;

  return jsonb_build_object(
    'id', v_request.id,
    'requester_id', v_request.requester_id,
    'store_id', v_request.store_id,
    'subject', v_request.subject,
    'body', v_request.body,
    'status', v_request.status,
    'preferred_handoff_option', v_request.preferred_handoff_option,
    'created_at', v_request.created_at,
    'updated_at', v_request.updated_at,
    'store_name', coalesce(v_store_name, 'متجر عسلكم')
  );
end;
$$;

create or replace function public.customer_toggle_store_follow(p_store_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_merchant_id uuid;
  v_following boolean;
  v_count integer;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'authentication_required';
  end if;
  select merchant_id into v_merchant_id from public.stores where id = p_store_id for update;
  if v_merchant_id is null then
    raise exception using errcode = 'P0002', message = 'store_not_found';
  end if;

  if exists (select 1 from public.store_followers where store_id = p_store_id and user_id = v_user_id) then
    delete from public.store_followers where store_id = p_store_id and user_id = v_user_id;
    v_following := false;
  else
    insert into public.store_followers (store_id, user_id) values (p_store_id, v_user_id);
    v_following := true;
    if v_merchant_id <> v_user_id then
      insert into public.notifications (user_id, notification_type, title_ar, body_ar, payload)
      values (v_merchant_id, 'store_followed', 'متابع جديد', 'بدأ مستخدم متابعة متجرك.', jsonb_build_object('store_id', p_store_id));
    end if;
  end if;

  perform private.sync_store_follower_count(p_store_id);
  select followers_count into v_count from public.store_statistics where store_id = p_store_id;
  return jsonb_build_object('following', v_following, 'followers_count', coalesce(v_count, 0));
end;
$$;

create or replace function public.customer_toggle_product_like(p_product_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_store_id uuid;
  v_merchant_id uuid;
  v_liked boolean;
  v_count integer;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'authentication_required';
  end if;
  select p.store_id, s.merchant_id into v_store_id, v_merchant_id
    from public.products p join public.stores s on s.id = p.store_id
   where p.id = p_product_id for update;
  if v_store_id is null then
    raise exception using errcode = 'P0002', message = 'product_not_found';
  end if;

  if exists (select 1 from public.product_likes where product_id = p_product_id and user_id = v_user_id) then
    delete from public.product_likes where product_id = p_product_id and user_id = v_user_id;
    v_liked := false;
  else
    insert into public.product_likes (product_id, user_id) values (p_product_id, v_user_id);
    v_liked := true;
    if v_merchant_id <> v_user_id then
      insert into public.notifications (user_id, notification_type, title_ar, body_ar, payload)
      values (v_merchant_id, 'product_liked', 'إعجاب جديد', 'حصل أحد منتجاتك على إعجاب جديد.', jsonb_build_object('product_id', p_product_id, 'store_id', v_store_id));
    end if;
  end if;

  perform private.sync_product_social_counts(p_product_id);
  select coalesce((metadata ->> 'likes_count')::integer, 0) into v_count from public.products where id = p_product_id;
  return jsonb_build_object('liked', v_liked, 'likes_count', coalesce(v_count, 0));
end;
$$;

create or replace function public.customer_toggle_favorite(p_product_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_saved boolean;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'authentication_required';
  end if;
  if not exists (select 1 from public.products where id = p_product_id) then
    raise exception using errcode = 'P0002', message = 'product_not_found';
  end if;

  if exists (select 1 from public.favorites where user_id = v_user_id and product_id = p_product_id) then
    delete from public.favorites where user_id = v_user_id and product_id = p_product_id;
    v_saved := false;
  else
    insert into public.favorites (user_id, product_id) values (v_user_id, p_product_id);
    v_saved := true;
  end if;
  return jsonb_build_object('saved', v_saved);
end;
$$;

revoke all on function public.customer_create_conversation(uuid) from public, anon;
revoke all on function public.customer_send_message(uuid, text) from public, anon;
revoke all on function public.customer_create_request(uuid, text, text, text, text, text, text, text, jsonb, uuid, integer) from public, anon;
revoke all on function public.customer_toggle_store_follow(uuid) from public, anon;
revoke all on function public.customer_toggle_product_like(uuid) from public, anon;
revoke all on function public.customer_toggle_favorite(uuid) from public, anon;

grant execute on function public.customer_create_conversation(uuid) to authenticated;
grant execute on function public.customer_send_message(uuid, text) to authenticated;
grant execute on function public.customer_create_request(uuid, text, text, text, text, text, text, text, jsonb, uuid, integer) to authenticated;
grant execute on function public.customer_toggle_store_follow(uuid) to authenticated;
grant execute on function public.customer_toggle_product_like(uuid) to authenticated;
grant execute on function public.customer_toggle_favorite(uuid) to authenticated;

create index if not exists request_messages_request_created_idx on public.request_messages(request_id, created_at desc);
create index if not exists messages_conversation_created_idx on public.messages(conversation_id, created_at desc);
create index if not exists notifications_user_created_idx on public.notifications(user_id, created_at desc);
create index if not exists product_likes_product_created_idx on public.product_likes(product_id, created_at desc);
create index if not exists store_followers_store_created_idx on public.store_followers(store_id, created_at desc);
