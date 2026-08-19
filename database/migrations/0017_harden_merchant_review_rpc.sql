-- Keep the administrative merchant-review RPC callable only by the local
-- Admin Backend through the service_role client. The customer app must never
-- be able to invoke this SECURITY DEFINER function directly.
revoke execute on function public.admin_review_merchant_application(uuid, text, text, uuid)
  from public, anon, authenticated;

grant execute on function public.admin_review_merchant_application(uuid, text, text, uuid)
  to service_role;

alter function public.admin_review_merchant_application(uuid, text, text, uuid)
  set search_path = public, pg_temp;
