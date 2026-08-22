-- UX-19: let the existing RLS decide visibility for comments.
-- Public callers still see approved rows; authors, merchants, and admins see
-- rows allowed by comments_select, including pending rows they own/manage.
create or replace view public.customer_comments
with (security_invoker = true)
as
select
  c.id,
  c.author_id,
  coalesce(c.product_id, c.review_id) as target_id,
  c.product_id,
  c.review_id,
  c.parent_comment_id,
  c.body,
  c.status,
  c.created_at,
  c.updated_at,
  coalesce(p.display_name, 'مستخدم عسلكم') as author_name
from public.comments c
left join public.profiles p on p.user_id = c.author_id;

grant select on public.customer_comments to anon, authenticated;
