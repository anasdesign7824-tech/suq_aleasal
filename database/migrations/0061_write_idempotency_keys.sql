-- TASK 096: write idempotency for retries and double-submit recovery.
-- The ledger is private so it does not expand the public TypeScript relation contract.

begin;

create table if not exists private.client_mutations (
  user_id uuid not null,
  operation text not null,
  mutation_key text not null,
  result_id uuid not null,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, operation, mutation_key),
  check (char_length(operation) between 1 and 80),
  check (char_length(mutation_key) between 1 and 128)
);

create index if not exists client_mutations_created_idx
  on private.client_mutations(created_at desc);

revoke all on table private.client_mutations from public, anon, authenticated;

-- Requests: a retry with the same client key returns the original request row.
drop function if exists public.customer_create_request(uuid, text, text, text, text, text, text, text, jsonb, uuid, integer);
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
  p_quantity integer default 1,
  p_mutation_key text default null
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
  v_subject text := nullif(trim(coalesce(p_subject, '')), '');
  v_quantity integer := coalesce(p_quantity, 1);
  v_key text := nullif(trim(coalesce(p_mutation_key, '')), '');
  v_result_id uuid;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'authentication_required';
  end if;
  if v_key is null then
    v_key := md5(v_user_id::text || ':request.create:' || p_store_id::text || ':' || coalesce(p_product_id::text, '') || ':' || coalesce(p_subject, '') || ':' || coalesce(p_body, '') || ':' || coalesce(p_preferred_handoff_option, '') || ':' || coalesce(p_phone, '') || ':' || coalesce(p_contact_channel, '') || ':' || coalesce(p_delivery_note, '') || ':' || coalesce(p_price_note, '') || ':' || coalesce(p_handoff_details::text, '') || ':' || coalesce(p_quantity, 1)::text);
  end if;
  if v_key is not null and char_length(v_key) > 128 then
    raise exception using errcode = '22023', message = 'mutation_key_too_long';
  end if;
  if v_key is not null then
    perform pg_advisory_xact_lock(hashtextextended(v_user_id::text || ':request.create:' || v_key, 0));
    select result_id into v_result_id
      from private.client_mutations
     where user_id = v_user_id and operation = 'request.create' and mutation_key = v_key
     for update;
    if v_result_id is not null then
      select * into v_request from public.requests where id = v_result_id and requester_id = v_user_id;
      if not found then raise exception using errcode = 'P0002', message = 'mutation_result_unavailable'; end if;
      select name_ar into v_store_name from public.stores where id = v_request.store_id;
      return jsonb_build_object(
        'id', v_request.id, 'requester_id', v_request.requester_id, 'store_id', v_request.store_id,
        'subject', v_request.subject, 'body', v_request.body, 'status', v_request.status,
        'preferred_handoff_option', v_request.preferred_handoff_option, 'created_at', v_request.created_at,
        'updated_at', v_request.updated_at, 'store_name', coalesce(v_store_name, 'متجر عسلكم')
      );
    end if;
  end if;
  if v_subject is null then
    raise exception using errcode = '22023', message = 'request_subject_empty';
  end if;
  if char_length(v_subject) > 180 then
    raise exception using errcode = '22023', message = 'request_subject_too_long';
  end if;
  if p_body is not null and char_length(trim(p_body)) > 5000 then
    raise exception using errcode = '22023', message = 'request_body_too_long';
  end if;
  if p_preferred_handoff_option is not null and char_length(trim(p_preferred_handoff_option)) > 32 then
    raise exception using errcode = '22023', message = 'request_handoff_option_too_long';
  end if;
  if p_phone is not null and char_length(trim(p_phone)) > 40 then
    raise exception using errcode = '22023', message = 'request_phone_too_long';
  end if;
  if p_contact_channel is not null and char_length(trim(p_contact_channel)) > 64 then
    raise exception using errcode = '22023', message = 'request_contact_channel_too_long';
  end if;
  if p_delivery_note is not null and char_length(trim(p_delivery_note)) > 1000 then
    raise exception using errcode = '22023', message = 'request_delivery_note_too_long';
  end if;
  if p_price_note is not null and char_length(trim(p_price_note)) > 1000 then
    raise exception using errcode = '22023', message = 'request_price_note_too_long';
  end if;
  if p_handoff_details is not null and (jsonb_typeof(p_handoff_details) <> 'object' or pg_column_size(p_handoff_details) > 16384) then
    raise exception using errcode = '22023', message = 'request_handoff_details_invalid';
  end if;
  if v_quantity < 1 or v_quantity > 1000 then
    raise exception using errcode = '22023', message = 'request_quantity_invalid';
  end if;
  select s.merchant_id, s.name_ar into v_store_merchant, v_store_name
    from public.stores s where s.id = p_store_id;
  if v_store_merchant is null then
    raise exception using errcode = 'P0002', message = 'store_not_found';
  end if;
  if p_product_id is not null and not exists (
    select 1 from public.products p where p.id = p_product_id and p.store_id = p_store_id
  ) then
    raise exception using errcode = '23503', message = 'product_store_mismatch';
  end if;
  insert into public.requests (
    requester_id, store_id, subject, body, preferred_handoff_option,
    phone, contact_channel, delivery_note, price_note, handoff_details
  ) values (
    v_user_id, p_store_id, v_subject, nullif(trim(p_body), ''),
    nullif(trim(p_preferred_handoff_option), ''), nullif(trim(p_phone), ''),
    nullif(trim(p_contact_channel), ''), nullif(trim(p_delivery_note), ''),
    nullif(trim(p_price_note), ''), p_handoff_details
  ) returning * into v_request;
  if p_product_id is not null then
    insert into public.request_items (request_id, product_id, quantity, note)
    values (v_request.id, p_product_id, v_quantity, coalesce(p_price_note, p_delivery_note));
  end if;
  if v_store_merchant <> v_user_id then
    insert into public.notifications (user_id, notification_type, title_ar, body_ar, payload)
    values (v_store_merchant, 'request_created', 'طلب تواصل جديد', 'وصل طلب تواصل جديد إلى متجرك.',
      jsonb_build_object('request_id', v_request.id, 'store_id', p_store_id));
  end if;
  if v_key is not null then
    insert into private.client_mutations(user_id, operation, mutation_key, result_id)
    values (v_user_id, 'request.create', v_key, v_request.id);
  end if;
  return jsonb_build_object(
    'id', v_request.id, 'requester_id', v_request.requester_id, 'store_id', v_request.store_id,
    'subject', v_request.subject, 'body', v_request.body, 'status', v_request.status,
    'preferred_handoff_option', v_request.preferred_handoff_option, 'created_at', v_request.created_at,
    'updated_at', v_request.updated_at, 'store_name', coalesce(v_store_name, 'متجر عسلكم')
  );
end;
$$;
revoke all on function public.customer_create_request(uuid, text, text, text, text, text, text, text, jsonb, uuid, integer, text) from public, anon;
grant execute on function public.customer_create_request(uuid, text, text, text, text, text, text, text, jsonb, uuid, integer, text) to authenticated;

-- Comments: a retry with the same key returns the original comment and suppresses a second notification.
drop function if exists public.customer_create_comment(uuid, text);
create or replace function public.customer_create_comment(
  p_target_id uuid,
  p_body text,
  p_mutation_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_store_id uuid;
  v_merchant_id uuid;
  v_comment public.comments%rowtype;
  v_body text := nullif(trim(coalesce(p_body, '')), '');
  v_key text := nullif(trim(coalesce(p_mutation_key, '')), '');
  v_result_id uuid;
begin
  if v_user_id is null then raise exception using errcode = '42501', message = 'authentication_required'; end if;
  if v_key is null then v_key := md5(v_user_id::text || ':comment.create:' || p_target_id::text || ':' || coalesce(p_body, '')); end if;
  if v_key is not null and char_length(v_key) > 128 then raise exception using errcode = '22023', message = 'mutation_key_too_long'; end if;
  if v_key is not null then
    perform pg_advisory_xact_lock(hashtextextended(v_user_id::text || ':comment.create:' || v_key, 0));
    select result_id into v_result_id from private.client_mutations where user_id=v_user_id and operation='comment.create' and mutation_key=v_key for update;
    if v_result_id is not null then
      select * into v_comment from public.comments where id=v_result_id and author_id=v_user_id;
      if not found then raise exception using errcode='P0002', message='mutation_result_unavailable'; end if;
      return jsonb_build_object('id',v_comment.id,'author_id',v_comment.author_id,'product_id',v_comment.product_id,'review_id',v_comment.review_id,'target_id',coalesce(v_comment.product_id,v_comment.review_id),'body',v_comment.body,'status',v_comment.status,'created_at',v_comment.created_at,'updated_at',v_comment.updated_at,'author_name','عميل عسلكم');
    end if;
  end if;
  if v_body is null then raise exception using errcode = '22023', message = 'comment_empty'; end if;
  if char_length(v_body) > 5000 then raise exception using errcode = '22023', message = 'comment_body_too_long'; end if;
  select p.store_id into v_store_id from public.products p where p.id=p_target_id;
  if v_store_id is not null then
    insert into public.comments(author_id, product_id, body, status) values(v_user_id,p_target_id,v_body,'pending') returning * into v_comment;
  else
    select r.store_id into v_store_id from public.reviews r where r.id=p_target_id;
    if v_store_id is null then raise exception using errcode='P0002', message='comment_target_not_found'; end if;
    insert into public.comments(author_id, review_id, body, status) values(v_user_id,p_target_id,v_body,'pending') returning * into v_comment;
  end if;
  select merchant_id into v_merchant_id from public.stores where id=v_store_id;
  if v_merchant_id is not null and v_merchant_id <> v_user_id then
    insert into public.notifications(user_id,notification_type,title_ar,body_ar,payload) values(v_merchant_id,'comment_created','تعليق جديد قيد المراجعة','أضاف أحد العملاء تعليقًا جديدًا على محتوى متجرك.',jsonb_build_object('comment_id',v_comment.id,'target_id',p_target_id,'store_id',v_store_id));
  end if;
  if v_key is not null then insert into private.client_mutations(user_id,operation,mutation_key,result_id) values(v_user_id,'comment.create',v_key,v_comment.id); end if;
  return jsonb_build_object('id',v_comment.id,'author_id',v_comment.author_id,'product_id',v_comment.product_id,'review_id',v_comment.review_id,'target_id',p_target_id,'body',v_comment.body,'status',v_comment.status,'created_at',v_comment.created_at,'updated_at',v_comment.updated_at,'author_name','عميل عسلكم');
end;
$$;
revoke all on function public.customer_create_comment(uuid,text) from public, anon;
grant execute on function public.customer_create_comment(uuid,text,text) to authenticated;

-- Messages: same key returns the original message and suppresses a second notification.
drop function if exists public.customer_send_message(uuid, text);
create or replace function public.customer_send_message(
  p_conversation_id uuid,
  p_body text,
  p_mutation_key text default null
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
  v_body text := nullif(trim(coalesce(p_body, '')), '');
  v_key text := nullif(trim(coalesce(p_mutation_key, '')), '');
  v_result_id uuid;
begin
  if v_user_id is null then raise exception using errcode = '42501', message = 'authentication_required'; end if;
  if v_key is null then v_key := md5(v_user_id::text || ':message.create:' || p_conversation_id::text || ':' || coalesce(p_body, '')); end if;
  if v_key is not null and char_length(v_key) > 128 then raise exception using errcode = '22023', message = 'mutation_key_too_long'; end if;
  if v_key is not null then
    perform pg_advisory_xact_lock(hashtextextended(v_user_id::text || ':message.create:' || v_key, 0));
    select result_id into v_result_id from private.client_mutations where user_id=v_user_id and operation='message.create' and mutation_key=v_key for update;
    if v_result_id is not null then
      select m.* into v_message from public.messages m where m.id=v_result_id and m.sender_id=v_user_id;
      if not found then raise exception using errcode='P0002', message='mutation_result_unavailable'; end if;
      return jsonb_build_object('id',v_message.id,'conversation_id',v_message.conversation_id,'sender_id',v_message.sender_id,'body',v_message.body,'read_at',v_message.read_at,'created_at',v_message.created_at,'sent_at',v_message.created_at,'is_mine',true,'store_name','متجر عسلكم');
    end if;
  end if;
  if v_body is null then raise exception using errcode = '22023', message = 'message_empty'; end if;
  if char_length(v_body) > 5000 then raise exception using errcode = '22023', message = 'message_body_too_long'; end if;
  select c.store_id,s.merchant_id,s.name_ar into v_store_id,v_merchant_id,v_store_name
    from public.conversations c join public.stores s on s.id=c.store_id
   where c.id=p_conversation_id and exists(select 1 from public.conversation_participants cp where cp.conversation_id=c.id and cp.user_id=v_user_id) for update;
  if v_store_id is null then raise exception using errcode='42501', message='conversation_not_owned'; end if;
  insert into public.messages(conversation_id,sender_id,body) values(p_conversation_id,v_user_id,v_body) returning * into v_message;
  update public.conversations set last_message_at=v_message.created_at where id=p_conversation_id;
  v_recipient_id := case when v_user_id=v_merchant_id then null else v_merchant_id end;
  if v_recipient_id is not null then
    insert into public.notifications(user_id,notification_type,title_ar,body_ar,payload) values(v_recipient_id,'message_received','رسالة جديدة','وصلت رسالة جديدة من أحد أطراف المحادثة.',jsonb_build_object('conversation_id',p_conversation_id,'store_id',v_store_id));
  end if;
  if v_key is not null then insert into private.client_mutations(user_id,operation,mutation_key,result_id) values(v_user_id,'message.create',v_key,v_message.id); end if;
  return jsonb_build_object('id',v_message.id,'conversation_id',v_message.conversation_id,'sender_id',v_message.sender_id,'body',v_message.body,'read_at',v_message.read_at,'created_at',v_message.created_at,'sent_at',v_message.created_at,'is_mine',true,'store_name',coalesce(v_store_name,'متجر عسلكم'));
end;
$$;
revoke all on function public.customer_send_message(uuid,text) from public, anon;
grant execute on function public.customer_send_message(uuid,text,text) to authenticated;

-- Review: optional key makes a retry return the same row and avoids a second notification.
drop function if exists public.customer_create_review(uuid, uuid, integer, text);
create or replace function public.customer_create_review(
  p_product_id uuid,
  p_store_id uuid,
  p_rating integer,
  p_body text,
  p_mutation_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_merchant_id uuid;
  v_review public.reviews%rowtype;
  v_body text := nullif(trim(coalesce(p_body, '')), '');
  v_key text := nullif(trim(coalesce(p_mutation_key, '')), '');
  v_result_id uuid;
begin
  if v_user_id is null then raise exception using errcode = '42501', message = 'authentication_required'; end if;
  if v_key is null then v_key := md5(v_user_id::text || ':review.create:' || p_product_id::text || ':' || p_store_id::text || ':' || coalesce(p_rating, 0)::text || ':' || coalesce(p_body, '')); end if;
  if v_key is not null and char_length(v_key) > 128 then raise exception using errcode = '22023', message = 'mutation_key_too_long'; end if;
  if v_key is not null then
    perform pg_advisory_xact_lock(hashtextextended(v_user_id::text || ':review.create:' || v_key, 0));
    select result_id into v_result_id from private.client_mutations where user_id=v_user_id and operation='review.create' and mutation_key=v_key for update;
    if v_result_id is not null then
      select * into v_review from public.reviews where id=v_result_id and author_id=v_user_id;
      if not found then raise exception using errcode='P0002', message='mutation_result_unavailable'; end if;
      return jsonb_build_object('id',v_review.id,'product_id',v_review.product_id,'store_id',v_review.store_id,'author_id',v_review.author_id,'rating',v_review.rating,'body',v_review.body,'status',v_review.status,'created_at',v_review.created_at,'updated_at',v_review.updated_at,'author_name','عميل عسلكم');
    end if;
  end if;
  if p_rating is null or p_rating < 1 or p_rating > 5 or v_body is null then raise exception using errcode='22023', message='invalid_review'; end if;
  if char_length(v_body) > 5000 then raise exception using errcode='22023', message='review_body_too_long'; end if;
  select s.merchant_id into v_merchant_id from public.products p join public.stores s on s.id=p.store_id where p.id=p_product_id and p.store_id=p_store_id;
  if v_merchant_id is null then raise exception using errcode='23503', message='product_store_mismatch'; end if;
  insert into public.reviews(product_id,store_id,author_id,rating,body,status) values(p_product_id,p_store_id,v_user_id,p_rating,v_body,'pending')
  on conflict(product_id,author_id) do update set store_id=excluded.store_id,rating=excluded.rating,body=excluded.body,status='pending',updated_at=timezone('utc',now()) returning * into v_review;
  if v_merchant_id <> v_user_id then
    insert into public.notifications(user_id,notification_type,title_ar,body_ar,payload) values(v_merchant_id,'review_created','تقييم جديد قيد المراجعة','أرسل أحد العملاء تقييمًا جديدًا لمنتجك.',jsonb_build_object('review_id',v_review.id,'product_id',p_product_id,'store_id',p_store_id));
  end if;
  if v_key is not null then insert into private.client_mutations(user_id,operation,mutation_key,result_id) values(v_user_id,'review.create',v_key,v_review.id); end if;
  return jsonb_build_object('id',v_review.id,'product_id',v_review.product_id,'store_id',v_review.store_id,'author_id',v_review.author_id,'rating',v_review.rating,'body',v_review.body,'status',v_review.status,'created_at',v_review.created_at,'updated_at',v_review.updated_at,'author_name','عميل عسلكم');
end;
$$;
revoke all on function public.customer_create_review(uuid,uuid,integer,text) from public, anon;
grant execute on function public.customer_create_review(uuid,uuid,integer,text,text) to authenticated;

-- Design requests: same key returns the original request and does not consume a second entitlement.
drop function if exists public.merchant_create_design_request(uuid,text,text,text,jsonb,jsonb);
create or replace function public.merchant_create_design_request(
  p_store_id uuid,
  p_title text,
  p_description text,
  p_brand_name text default null,
  p_brand_colors jsonb default '[]'::jsonb,
  p_product_scope jsonb default '{}'::jsonb,
  p_mutation_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  v_merchant_id uuid := auth.uid();
  v_subscription public.merchant_subscriptions%rowtype;
  v_plan public.subscription_plans%rowtype;
  v_limit integer;
  v_used integer;
  v_request public.design_requests%rowtype;
  v_title text := nullif(trim(coalesce(p_title, '')), '');
  v_description text := nullif(trim(coalesce(p_description, '')), '');
  v_brand_name text := nullif(trim(coalesce(p_brand_name, '')), '');
  v_key text := nullif(trim(coalesce(p_mutation_key, '')), '');
  v_result_id uuid;
begin
  if v_merchant_id is null then raise exception 'not_authenticated' using errcode='28000'; end if;
  if v_key is null then v_key := md5(v_merchant_id::text || ':design_request.create:' || p_store_id::text || ':' || coalesce(p_title, '') || ':' || coalesce(p_description, '') || ':' || coalesce(p_brand_name, '') || ':' || coalesce(p_brand_colors::text, '') || ':' || coalesce(p_product_scope::text, '')); end if;
  if v_key is not null and char_length(v_key)>128 then raise exception 'mutation_key_too_long'; end if;
  if v_key is not null then
    perform pg_advisory_xact_lock(hashtextextended(v_merchant_id::text || ':design_request.create:' || v_key,0));
    select result_id into v_result_id from private.client_mutations where user_id=v_merchant_id and operation='design_request.create' and mutation_key=v_key for update;
    if v_result_id is not null then
      select * into v_request from public.design_requests where id=v_result_id and merchant_id=v_merchant_id;
      if not found then raise exception 'mutation_result_unavailable'; end if;
      return to_jsonb(v_request);
    end if;
  end if;
  if v_title is null or char_length(v_title)>180 then raise exception 'design_title_invalid'; end if;
  if v_description is null or char_length(v_description)>5000 then raise exception 'design_description_invalid'; end if;
  if v_brand_name is not null and char_length(v_brand_name)>180 then raise exception 'design_brand_name_too_long'; end if;
  if p_brand_colors is not null and (jsonb_typeof(p_brand_colors)<>'array' or pg_column_size(p_brand_colors)>32768) then raise exception 'design_brand_colors_invalid'; end if;
  if p_product_scope is not null and (jsonb_typeof(p_product_scope)<>'object' or pg_column_size(p_product_scope)>32768) then raise exception 'design_product_scope_invalid'; end if;
  select ms.* into v_subscription from public.merchant_subscriptions ms where ms.merchant_id=v_merchant_id and ms.status='active' and ms.ends_at>timezone('utc',now()) and ms.plan_id is not null order by ms.ends_at desc limit 1;
  if not found then raise exception 'active_plan_required'; end if;
  select sp.* into v_plan from public.subscription_plans sp where sp.id=v_subscription.plan_id and sp.is_active;
  if not found then raise exception 'subscription_plan_not_found'; end if;
  if not exists(select 1 from public.stores s where s.id=p_store_id and s.merchant_id=v_merchant_id) then raise exception 'store_not_owned'; end if;
  v_limit := coalesce((v_plan.entitlements->>'design_requests_per_cycle')::integer,0);
  select count(*)::integer into v_used from public.design_requests dr where dr.subscription_id=v_subscription.id and dr.created_at>=v_subscription.starts_at and dr.status<>'cancelled';
  if v_used>=v_limit then raise exception 'design_request_limit_reached'; end if;
  insert into public.design_requests(merchant_id,store_id,subscription_id,status,title,description,brand_name,brand_colors,product_scope) values(v_merchant_id,p_store_id,v_subscription.id,'submitted',v_title,v_description,v_brand_name,coalesce(p_brand_colors,'[]'::jsonb),coalesce(p_product_scope,'{}'::jsonb)) returning * into v_request;
  if v_key is not null then insert into private.client_mutations(user_id,operation,mutation_key,result_id) values(v_merchant_id,'design_request.create',v_key,v_request.id); end if;
  return to_jsonb(v_request);
end;
$$;
revoke all on function public.merchant_create_design_request(uuid,text,text,text,jsonb,jsonb) from public, anon;
grant execute on function public.merchant_create_design_request(uuid,text,text,text,jsonb,jsonb,text) to authenticated;

commit;
