-- One-query comment read model with author display names.
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
left join public.profiles p on p.user_id = c.author_id
where c.status = 'approved';

grant select on public.customer_comments to anon, authenticated;
create index if not exists comments_product_status_created_idx
  on public.comments(product_id, status, created_at desc);
create index if not exists comments_review_status_created_idx
  on public.comments(review_id, status, created_at desc);
