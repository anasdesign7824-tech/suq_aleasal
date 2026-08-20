-- Trigger wrappers must run with their owner privileges so authenticated writes
-- can update denormalized counters without exposing private functions directly.
create or replace function private.trg_sync_store_follower_count()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
begin
  perform private.sync_store_follower_count(
    case when TG_OP = 'DELETE' then old.store_id else new.store_id end
  );
  if TG_OP = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

create or replace function private.trg_sync_product_social_counts()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
begin
  perform private.sync_product_social_counts(
    case when TG_OP = 'DELETE' then old.product_id else new.product_id end
  );
  if TG_OP = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;
