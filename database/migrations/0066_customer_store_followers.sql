-- UX-14: public-safe store follower summaries for active stores.
-- The function intentionally excludes email, phone, and user_id.

create or replace function public.customer_list_store_followers(
  p_store_id uuid,
  p_limit integer default 50,
  p_offset integer default 0
)
returns jsonb
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_total integer;
  v_items jsonb;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'authentication_required';
  end if;

  if p_limit < 1 or p_limit > 100 or p_offset < 0 then
    raise exception using errcode = '22023', message = 'invalid_pagination';
  end if;

  if not exists (
    select 1
      from public.stores s
     where s.id = p_store_id
       and s.status = 'active'
  ) then
    raise exception using errcode = 'P0002', message = 'store_not_found';
  end if;

  select count(*)::integer
    into v_total
    from public.store_followers sf
   where sf.store_id = p_store_id;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'display_name', coalesce(nullif(trim(p.display_name), ''), 'مستخدم عسلكم'),
        'avatar_url', p.avatar_url,
        'followed_at', sf.created_at
      ) order by sf.created_at desc
    ),
    '[]'::jsonb
  )
    into v_items
    from public.store_followers sf
    left join public.profiles p on p.user_id = sf.user_id
   where sf.store_id = p_store_id
   offset p_offset
   limit p_limit;

  return jsonb_build_object(
    'items', v_items,
    'total', v_total,
    'limit', p_limit,
    'offset', p_offset
  );
end;
$$;

revoke all on function public.customer_list_store_followers(uuid, integer, integer) from public, anon;
grant execute on function public.customer_list_store_followers(uuid, integer, integer) to authenticated;
