-- Atomic review and comment creation with merchant notifications.
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
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'authentication_required';
  end if;
  if p_rating < 1 or p_rating > 5 or nullif(trim(p_body), '') is null then
    raise exception using errcode = '22023', message = 'invalid_review';
  end if;

  select s.merchant_id into v_merchant_id
    from public.products p
    join public.stores s on s.id = p.store_id
   where p.id = p_product_id and p.store_id = p_store_id;
  if v_merchant_id is null then
    raise exception using errcode = '23503', message = 'product_store_mismatch';
  end if;

  insert into public.reviews (product_id, store_id, author_id, rating, body, status)
  values (p_product_id, p_store_id, v_user_id, p_rating, trim(p_body), 'pending')
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
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'authentication_required';
  end if;
  if nullif(trim(p_body), '') is null then
    raise exception using errcode = '22023', message = 'comment_empty';
  end if;

  select p.store_id into v_store_id from public.products p where p.id = p_target_id;
  if v_store_id is not null then
    insert into public.comments (author_id, product_id, body, status)
    values (v_user_id, p_target_id, trim(p_body), 'pending')
    returning * into v_comment;
  else
    select r.store_id into v_store_id
      from public.reviews r
     where r.id = p_target_id;
    if v_store_id is null then
      raise exception using errcode = 'P0002', message = 'comment_target_not_found';
    end if;
    insert into public.comments (author_id, review_id, body, status)
    values (v_user_id, p_target_id, trim(p_body), 'pending')
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

revoke all on function public.customer_create_review(uuid, uuid, integer, text) from public, anon;
revoke all on function public.customer_create_comment(uuid, text) from public, anon;
grant execute on function public.customer_create_review(uuid, uuid, integer, text) to authenticated;
grant execute on function public.customer_create_comment(uuid, text) to authenticated;
