begin;

-- These RPCs perform owner-scoped writes and must never be callable anonymously.
revoke execute on function public.merchant_create_subscription_payment_request(uuid, uuid) from public, anon;
revoke execute on function public.merchant_submit_payment_proof(uuid, text, text, text, text, bigint, date, numeric, text, text) from public, anon;
revoke execute on function public.merchant_create_design_request(uuid, text, text, text, jsonb, jsonb) from public, anon;
grant execute on function public.merchant_create_subscription_payment_request(uuid, uuid) to authenticated;
grant execute on function public.merchant_submit_payment_proof(uuid, text, text, text, text, bigint, date, numeric, text, text) to authenticated;
grant execute on function public.merchant_create_design_request(uuid, text, text, text, jsonb, jsonb) to authenticated;

commit;
