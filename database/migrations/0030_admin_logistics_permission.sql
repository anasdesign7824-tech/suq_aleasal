-- Allow the operational admin role to manage store delivery and pickup entities.
-- Super admin already bypasses permission checks; moderators remain read-only.

begin;

update public.admin_roles
set permissions = permissions || '{"logistics.manage": true}'::jsonb
where code = 'admin';

commit;
