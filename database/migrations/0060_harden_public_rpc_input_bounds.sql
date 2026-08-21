-- TASK 092: Harden public RPC input bounds without changing public signatures.
-- Preserve existing behavior for valid app payloads; reject oversized, malformed,
-- or semantically invalid input before any write occurs.

begin;

create or replace function public.customer_create_review(
  p_product_id uuid,
  p_store_id uuid,
  p_rating integer,
  p_body text
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
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'authentication_required';
  end if;
  if p_rating is null or p_rating < 1 or p_rating > 5 or v_body is null then
    raise exception using errcode = '22023', message = 'invalid_review';
  end if;
  if char_length(v_body) > 5000 then
    raise exception using errcode = '22023', message = 'review_body_too_long';
  end if;

  select s.merchant_id into v_merchant_id
    from public.products p
    join public.stores s on s.id = p.store_id
   where p.id = p_product_id and p.store_id = p_store_id;
  if v_merchant_id is null then
    raise exception using errcode = '23503', message = 'product_store_mismatch';
  end if;

  insert into public.reviews (product_id, store_id, author_id, rating, body, status)
  values (p_product_id, p_store_id, v_user_id, p_rating, v_body, 'pending')
  on conflict (product_id, author_id) do update
    set store_id = excluded.store_id,
        rating = excluded.rating,
        body = excluded.body,
        status = 'pending',
        updated_at = timezone('utc', now())
  returning * into v_review;

  if v_merchant_id <> v_user_id then
    insert into public.notifications (user_id, notification_type, title_ar, body_ar, payload)
    values (
      v_merchant_id,
      'review_created',
      'تقييم جديد قيد المراجعة',
      'أرسل أحد العملاء تقييمًا جديدًا لمنتجك.',
      jsonb_build_object('review_id', v_review.id, 'product_id', p_product_id, 'store_id', p_store_id)
    );
  end if;

  return jsonb_build_object(
    'id', v_review.id,
    'product_id', v_review.product_id,
    'store_id', v_review.store_id,
    'author_id', v_review.author_id,
    'rating', v_review.rating,
    'body', v_review.body,
    'status', v_review.status,
    'created_at', v_review.created_at,
    'updated_at', v_review.updated_at,
    'author_name', 'عميل عسلكم'
  );
end;
$$;

create or replace function public.customer_create_comment(
  p_target_id uuid,
  p_body text
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
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'authentication_required';
  end if;
  if v_body is null then
    raise exception using errcode = '22023', message = 'comment_empty';
  end if;
  if char_length(v_body) > 5000 then
    raise exception using errcode = '22023', message = 'comment_body_too_long';
  end if;

  select p.store_id into v_store_id from public.products p where p.id = p_target_id;
  if v_store_id is not null then
    insert into public.comments (author_id, product_id, body, status)
    values (v_user_id, p_target_id, v_body, 'pending')
    returning * into v_comment;
  else
    select r.store_id into v_store_id
      from public.reviews r
     where r.id = p_target_id;
    if v_store_id is null then
      raise exception using errcode = 'P0002', message = 'comment_target_not_found';
    end if;
    insert into public.comments (author_id, review_id, body, status)
    values (v_user_id, p_target_id, v_body, 'pending')
    returning * into v_comment;
  end if;

  select merchant_id into v_merchant_id from public.stores where id = v_store_id;
  if v_merchant_id is not null and v_merchant_id <> v_user_id then
    insert into public.notifications (user_id, notification_type, title_ar, body_ar, payload)
    values (
      v_merchant_id,
      'comment_created',
      'تعليق جديد قيد المراجعة',
      'أضاف أحد العملاء تعليقًا جديدًا على محتوى متجرك.',
      jsonb_build_object('comment_id', v_comment.id, 'target_id', p_target_id, 'store_id', v_store_id)
    );
  end if;

  return jsonb_build_object(
    'id', v_comment.id,
    'author_id', v_comment.author_id,
    'product_id', v_comment.product_id,
    'review_id', v_comment.review_id,
    'target_id', p_target_id,
    'body', v_comment.body,
    'status', v_comment.status,
    'created_at', v_comment.created_at,
    'updated_at', v_comment.updated_at,
    'author_name', 'عميل عسلكم'
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
  v_body text := nullif(trim(coalesce(p_body, '')), '');
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'authentication_required';
  end if;
  if v_body is null then
    raise exception using errcode = '22023', message = 'message_empty';
  end if;
  if char_length(v_body) > 5000 then
    raise exception using errcode = '22023', message = 'message_body_too_long';
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
  values (p_conversation_id, v_user_id, v_body)
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
  v_subject text := nullif(trim(coalesce(p_subject, '')), '');
  v_quantity integer := coalesce(p_quantity, 1);
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'authentication_required';
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
  if p_handoff_details is not null then
    if jsonb_typeof(p_handoff_details) <> 'object' or pg_column_size(p_handoff_details) > 16384 then
      raise exception using errcode = '22023', message = 'request_handoff_details_invalid';
    end if;
  end if;
  if v_quantity < 1 or v_quantity > 1000 then
    raise exception using errcode = '22023', message = 'request_quantity_invalid';
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

create or replace function public.merchant_open_workspace(
  p_business_name text,
  p_description text default null,
  p_region_id uuid default null,
  p_phone text default null,
  p_logo_url text default null,
  p_cover_url text default null
)
returns jsonb
language plpgsql
security invoker
set search_path = pg_catalog, public, private, auth
as $$
declare
  v_user_id uuid := auth.uid();
  v_name text := nullif(trim(coalesce(p_business_name, '')), '');
  v_store public.stores%rowtype;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;
  if v_name is null or char_length(v_name) < 2 then
    raise exception 'Business name is required';
  end if;
  if char_length(v_name) > 180 then
    raise exception 'Business name is too long';
  end if;
  if p_description is not null and char_length(trim(p_description)) > 5000 then
    raise exception 'Business description is too long';
  end if;
  if p_phone is not null and char_length(trim(p_phone)) > 40 then
    raise exception 'Business phone is too long';
  end if;
  if p_logo_url is not null and char_length(trim(p_logo_url)) > 2048 then
    raise exception 'Business logo URL is too long';
  end if;
  if p_cover_url is not null and char_length(trim(p_cover_url)) > 2048 then
    raise exception 'Business cover URL is too long';
  end if;

  insert into public.merchant_profiles (
    user_id, business_name, description, verification_status
  ) values (
    v_user_id, v_name, nullif(trim(coalesce(p_description, '')), ''), 'pending'
  )
  on conflict (user_id) do update set
    business_name = excluded.business_name,
    description = coalesce(excluded.description, public.merchant_profiles.description),
    updated_at = timezone('utc', now());

  insert into public.stores (
    merchant_id, region_id, name_ar, slug, description, phone,
    logo_url, cover_url, status, is_verified
  ) values (
    v_user_id,
    p_region_id,
    v_name,
    'merchant-' || substring(v_user_id::text from 1 for 8),
    nullif(trim(coalesce(p_description, '')), ''),
    nullif(trim(coalesce(p_phone, '')), ''),
    nullif(trim(coalesce(p_logo_url, '')), ''),
    nullif(trim(coalesce(p_cover_url, '')), ''),
    'pending',
    false
  )
  on conflict (merchant_id) do update set
    region_id = coalesce(excluded.region_id, public.stores.region_id),
    name_ar = excluded.name_ar,
    description = coalesce(excluded.description, public.stores.description),
    phone = coalesce(excluded.phone, public.stores.phone),
    logo_url = coalesce(excluded.logo_url, public.stores.logo_url),
    cover_url = coalesce(excluded.cover_url, public.stores.cover_url),
    updated_at = timezone('utc', now());

  select * into v_store from public.stores where merchant_id = v_user_id;
  return jsonb_build_object(
    'store', to_jsonb(v_store),
    'verification_status', 'pending',
    'public_status', v_store.status,
    'can_edit', true,
    'can_publish', v_store.status = 'active'
  );
end;
$$;

create or replace function public.merchant_submit_payment_proof(
  p_payment_request_id uuid,
  p_payment_reference text,
  p_proof_path text,
  p_proof_file_name text,
  p_proof_mime_type text,
  p_proof_byte_size bigint,
  p_transfer_date date,
  p_submitted_amount numeric,
  p_sender_name text,
  p_sender_phone text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  v_request public.payment_requests%rowtype;
  v_path_prefix text := auth.uid()::text || '/payment-proofs/';
  v_reference text := nullif(trim(coalesce(p_payment_reference, '')), '');
  v_file_name text := nullif(trim(coalesce(p_proof_file_name, '')), '');
  v_sender_name text := nullif(trim(coalesce(p_sender_name, '')), '');
  v_sender_phone text := nullif(trim(coalesce(p_sender_phone, '')), '');
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode = '28000'; end if;
  if p_proof_path is null or left(p_proof_path, char_length(v_path_prefix)) <> v_path_prefix
     or char_length(p_proof_path) > 512
     or position('..' in p_proof_path) > 0
     or position('//' in p_proof_path) > 0 then
    raise exception 'payment_proof_path_invalid';
  end if;
  if p_proof_mime_type not in ('application/pdf', 'image/jpeg', 'image/png') then raise exception 'payment_proof_type_invalid'; end if;
  if p_proof_byte_size is null or p_proof_byte_size <= 0 or p_proof_byte_size > 10485760 then raise exception 'payment_proof_size_invalid'; end if;
  if v_reference is null or char_length(v_reference) < 3 or char_length(v_reference) > 120 then raise exception 'payment_reference_invalid'; end if;
  if v_file_name is not null and char_length(v_file_name) > 180 then raise exception 'payment_proof_file_name_too_long'; end if;
  if v_sender_name is not null and char_length(v_sender_name) > 180 then raise exception 'payment_sender_name_too_long'; end if;
  if v_sender_phone is not null and char_length(v_sender_phone) > 40 then raise exception 'payment_sender_phone_too_long'; end if;

  select * into v_request from public.payment_requests where id = p_payment_request_id and merchant_id = auth.uid() for update;
  if not found then raise exception 'payment_request_not_found'; end if;
  if v_request.status not in ('not_started', 'failed') then raise exception 'payment_proof_not_allowed'; end if;
  update public.payment_requests set status = 'proof_uploaded', payment_reference = v_reference, proof_path = p_proof_path, proof_file_name = v_file_name, proof_mime_type = p_proof_mime_type, proof_byte_size = p_proof_byte_size, transfer_date = p_transfer_date, submitted_amount = p_submitted_amount, sender_name = v_sender_name, sender_phone = v_sender_phone, updated_at = timezone('utc', now()) where id = p_payment_request_id;
  insert into public.payment_events (payment_request_id, actor_user_id, from_status, to_status, note, metadata) values (p_payment_request_id, auth.uid(), v_request.status, 'proof_uploaded', 'رفع التاجر مستند الحوالة.', jsonb_build_object('payment_method', 'bank_transfer'));
  return (select to_jsonb(p) from public.payment_requests p where p.id = p_payment_request_id);
end;
$$;

create or replace function public.merchant_create_design_request(
  p_store_id uuid,
  p_title text,
  p_description text,
  p_brand_name text default null,
  p_brand_colors jsonb default '[]'::jsonb,
  p_product_scope jsonb default '{}'::jsonb
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
begin
  if v_merchant_id is null then raise exception 'not_authenticated' using errcode = '28000'; end if;
  if v_title is null or char_length(v_title) > 180 then raise exception 'design_title_invalid'; end if;
  if v_description is null or char_length(v_description) > 5000 then raise exception 'design_description_invalid'; end if;
  if v_brand_name is not null and char_length(v_brand_name) > 180 then raise exception 'design_brand_name_too_long'; end if;
  if p_brand_colors is not null and (jsonb_typeof(p_brand_colors) <> 'array' or pg_column_size(p_brand_colors) > 32768) then raise exception 'design_brand_colors_invalid'; end if;
  if p_product_scope is not null and (jsonb_typeof(p_product_scope) <> 'object' or pg_column_size(p_product_scope) > 32768) then raise exception 'design_product_scope_invalid'; end if;

  select ms.* into v_subscription
  from public.merchant_subscriptions ms
  where ms.merchant_id = v_merchant_id and ms.status = 'active' and ms.ends_at > timezone('utc', now()) and ms.plan_id is not null order by ms.ends_at desc limit 1;
  if not found then raise exception 'active_plan_required'; end if;
  select sp.* into v_plan from public.subscription_plans sp where sp.id = v_subscription.plan_id and sp.is_active;
  if not found then raise exception 'subscription_plan_not_found'; end if;
  if not exists (select 1 from public.stores s where s.id = p_store_id and s.merchant_id = v_merchant_id) then raise exception 'store_not_owned'; end if;
  v_limit := coalesce((v_plan.entitlements ->> 'design_requests_per_cycle')::integer, 0);
  select count(*)::integer into v_used from public.design_requests dr where dr.subscription_id = v_subscription.id and dr.created_at >= v_subscription.starts_at and dr.status <> 'cancelled';
  if v_used >= v_limit then raise exception 'design_request_limit_reached'; end if;
  insert into public.design_requests (merchant_id, store_id, subscription_id, status, title, description, brand_name, brand_colors, product_scope) values (v_merchant_id, p_store_id, v_subscription.id, 'submitted', v_title, v_description, v_brand_name, coalesce(p_brand_colors, '[]'::jsonb), coalesce(p_product_scope, '{}'::jsonb)) returning * into v_request;
  return to_jsonb(v_request);
end;
$$;

revoke all on function public.customer_create_review(uuid, uuid, integer, text) from public, anon;
revoke all on function public.customer_create_comment(uuid, text) from public, anon;
revoke all on function public.customer_send_message(uuid, text) from public, anon;
revoke all on function public.customer_create_request(uuid, text, text, text, text, text, text, text, jsonb, uuid, integer) from public, anon;
revoke all on function public.merchant_open_workspace(text, text, uuid, text, text, text) from public, anon;
revoke all on function public.merchant_submit_payment_proof(uuid, text, text, text, text, bigint, date, numeric, text, text) from public, anon;
revoke all on function public.merchant_create_design_request(uuid, text, text, text, jsonb, jsonb) from public, anon;

grant execute on function public.customer_create_review(uuid, uuid, integer, text) to authenticated;
grant execute on function public.customer_create_comment(uuid, text) to authenticated;
grant execute on function public.customer_send_message(uuid, text) to authenticated;
grant execute on function public.customer_create_request(uuid, text, text, text, text, text, text, text, jsonb, uuid, integer) to authenticated;
grant execute on function public.merchant_open_workspace(text, text, uuid, text, text, text) to authenticated;
grant execute on function public.merchant_submit_payment_proof(uuid, text, text, text, text, bigint, date, numeric, text, text) to authenticated;
grant execute on function public.merchant_create_design_request(uuid, text, text, text, jsonb, jsonb) to authenticated;

commit;
