begin;

update public.admin_roles
set permissions = permissions || '{"merchant.review": true}'::jsonb
where code in ('admin', 'moderator');

commit;
