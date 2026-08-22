-- REQ-10: owner-controlled store contact and handoff settings.
-- Inputs are canonical JSON values so the merchant UI can use dropdowns rather than free text.

begin;

create or replace function public.merchant_save_store_channels(
  p_store_id uuid,
  p_social_links jsonb default '{}'::jsonb,
  p_delivery_codes jsonb default '[]'::jsonb,
  p_pickup_locations jsonb default '[]'::jsonb
)
returns jsonb
language plpgsql
security invoker
set search_path = pg_catalog, public, private, auth
as $$
declare
  v_user_id uuid := auth.uid();
  v_store public.stores%rowtype;
  v_item jsonb;
  v_key text;
  v_value text;
  v_code text;
  v_method_id uuid;
  v_view jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;
  if jsonb_typeof(coalesce(p_social_links, '{}'::jsonb)) <> 'object' then
    raise exception 'social_links must be a JSON object';
  end if;
  if jsonb_typeof(coalesce(p_delivery_codes, '[]'::jsonb)) <> 'array' then
    raise exception 'delivery_codes must be a JSON array';
  end if;
  if jsonb_typeof(coalesce(p_pickup_locations, '[]'::jsonb)) <> 'array' then
    raise exception 'pickup_locations must be a JSON array';
  end if;

  select * into v_store
  from public.stores
  where id = p_store_id and merchant_id = v_user_id
  for update;
  if not found then
    raise exception 'Store is not owned by the authenticated merchant';
  end if;

  delete from public.social_links where store_id = p_store_id;
  for v_key, v_value in
    select key, nullif(trim(value), '')
    from jsonb_each_text(coalesce(p_social_links, '{}'::jsonb))
  loop
    if v_key not in ('whatsapp', 'telegram', 'facebook', 'instagram', 'website') then
      raise exception 'Unsupported social platform';
    end if;
    if v_value is null or char_length(v_value) > 1024 or v_value !~* '^https?://' then
      raise exception 'Invalid social link';
    end if;
    insert into public.social_links(store_id, platform, url)
    values (p_store_id, v_key, v_value);
  end loop;

  delete from public.merchant_delivery_options where store_id = p_store_id;
  for v_item in select value from jsonb_array_elements(coalesce(p_delivery_codes, '[]'::jsonb))
  loop
    v_code := nullif(trim(v_item #>> '{}'), '');
    if v_code is null then
      raise exception 'Delivery code is required';
    end if;
    select id into v_method_id
    from public.delivery_methods
    where code = v_code and is_active;
    if not found then
      raise exception 'Unsupported delivery method';
    end if;
    insert into public.merchant_delivery_options(
      store_id, delivery_method_id, fee_amount, currency, estimated_days, is_active
    ) values (
      p_store_id, v_method_id, null, 'YER', null, true
    );
  end loop;

  delete from public.merchant_pickup_locations where store_id = p_store_id;
  for v_item in select value from jsonb_array_elements(coalesce(p_pickup_locations, '[]'::jsonb))
  loop
    v_value := nullif(trim(v_item #>> '{}'), '');
    if v_value is null or char_length(v_value) > 160 then
      raise exception 'Pickup location name is required';
    end if;
    insert into public.merchant_pickup_locations(store_id, name_ar, is_active)
    values (p_store_id, v_value, true);
  end loop;

  select to_jsonb(cs) into v_view
  from public.customer_stores cs
  where cs.id = p_store_id;

  return coalesce(v_view, jsonb_build_object('id', p_store_id));
end;
$$;

revoke all on function public.merchant_save_store_channels(uuid, jsonb, jsonb, jsonb) from public;
grant execute on function public.merchant_save_store_channels(uuid, jsonb, jsonb, jsonb) to authenticated;

commit;
