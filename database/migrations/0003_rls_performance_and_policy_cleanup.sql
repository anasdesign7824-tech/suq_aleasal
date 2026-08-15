-- Souq Al Assal / عسلكم — RLS performance and policy cleanup
-- Preserve authorization semantics while avoiding duplicate permissive policies and per-row auth evaluation.

create or replace function private.prevent_profile_role_escalation()
returns trigger
language plpgsql
security invoker
set search_path = public, private
as $$
begin
  if new.role is distinct from old.role and not public.is_admin() then
    raise exception 'Only an admin may change profile roles';
  end if;
  return new;
end;
$$;

create or replace function private.prevent_merchant_verification_changes()
returns trigger
language plpgsql
security invoker
set search_path = public, private
as $$
begin
  if (new.verification_status is distinct from old.verification_status or new.verified_at is distinct from old.verified_at) and not public.is_admin() then
    raise exception 'Only an admin may change merchant verification';
  end if;
  return new;
end;
$$;

create or replace function private.prevent_store_moderation_changes()
returns trigger
language plpgsql
security invoker
set search_path = public, private
as $$
begin
  if (new.status is distinct from old.status or new.is_verified is distinct from old.is_verified) and not public.is_admin() then
    raise exception 'Only an admin may change store moderation fields';
  end if;
  return new;
end;
$$;

-- Remove the initial permissive policies before creating one policy per action.
do $$
declare
  policy_record record;
begin
  for policy_record in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname = 'public'
  loop
    execute format('drop policy if exists %I on %I.%I', policy_record.policyname, policy_record.schemaname, policy_record.tablename);
  end loop;
end;
$$;

-- Public and owner/admin SELECT policies: one policy per table/action.
create policy users_select on public.users for select using (id = (select auth.uid()) or (select public.is_admin()));
create policy profiles_select on public.profiles for select using (is_active or user_id = (select auth.uid()) or (select public.is_admin()));
create policy merchant_profiles_select on public.merchant_profiles for select using (user_id = (select auth.uid()) or (select public.is_admin()));
create policy regions_select on public.regions for select using (is_active or (select public.is_admin()));
create policy categories_select on public.categories for select using (is_active or (select public.is_admin()));
create policy taxonomy_select on public.honey_taxonomy for select using (is_active or (select public.is_admin()));
create policy stores_select on public.stores for select using (status = 'active' or merchant_id = (select auth.uid()) or (select public.is_admin()));
create policy store_followers_select on public.store_followers for select using (user_id = (select auth.uid()) or exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy store_gallery_select on public.store_gallery for select using (exists (select 1 from public.stores s where s.id = store_id and (s.status = 'active' or s.merchant_id = (select auth.uid()) or (select public.is_admin()))));
create policy store_statistics_select on public.store_statistics for select using (exists (select 1 from public.stores s where s.id = store_id and (s.status = 'active' or s.merchant_id = (select auth.uid()) or (select public.is_admin()))));
create policy products_select on public.products for select using ((status = 'active' and exists (select 1 from public.stores s where s.id = store_id and s.status = 'active')) or exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy product_images_select on public.product_images for select using (exists (select 1 from public.products p join public.stores s on s.id = p.store_id where p.id = product_id and ((p.status = 'active' and s.status = 'active') or s.merchant_id = (select auth.uid()) or (select public.is_admin()))));
create policy product_categories_select on public.product_categories for select using (exists (select 1 from public.products p join public.stores s on s.id = p.store_id where p.id = product_id and (p.status = 'active' or s.merchant_id = (select auth.uid()) or (select public.is_admin()))));
create policy certifications_select on public.certifications for select using (true);
create policy product_certifications_select on public.product_certifications for select using (exists (select 1 from public.products p join public.stores s on s.id = p.store_id where p.id = product_id and ((p.status = 'active' and s.status = 'active') or s.merchant_id = (select auth.uid()) or (select public.is_admin()))));
create policy reviews_select on public.reviews for select using (status = 'approved' or author_id = (select auth.uid()) or exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy review_likes_select on public.review_likes for select using (user_id = (select auth.uid()) or (select public.is_admin()));
create policy comments_select on public.comments for select using (status = 'approved' or author_id = (select auth.uid()) or exists (select 1 from public.products p join public.stores s on s.id = p.store_id where p.id = product_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy comment_likes_select on public.comment_likes for select using (user_id = (select auth.uid()) or (select public.is_admin()));
create policy favorites_select on public.favorites for select using (user_id = (select auth.uid()));
create policy requests_select on public.requests for select using (requester_id = (select auth.uid()) or exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy request_items_select on public.request_items for select using (exists (select 1 from public.requests r where r.id = request_id and (r.requester_id = (select auth.uid()) or exists (select 1 from public.stores s where s.id = r.store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()))));
create policy request_messages_select on public.request_messages for select using (sender_id = (select auth.uid()) or exists (select 1 from public.requests r join public.stores s on s.id = r.store_id where r.id = request_id and (r.requester_id = (select auth.uid()) or s.merchant_id = (select auth.uid()))) or (select public.is_admin()));
create policy notifications_select on public.notifications for select using (user_id = (select auth.uid()));
create policy banners_select on public.banners for select using ((is_active and (starts_at is null or starts_at <= now()) and (ends_at is null or ends_at >= now())) or (select public.is_admin()));
create policy delivery_methods_select on public.delivery_methods for select using (is_active or (select public.is_admin()));
create policy pickup_locations_select on public.merchant_pickup_locations for select using (exists (select 1 from public.stores s where s.id = store_id and (s.status = 'active' or s.merchant_id = (select auth.uid()) or (select public.is_admin()))));
create policy delivery_options_select on public.merchant_delivery_options for select using (exists (select 1 from public.stores s where s.id = store_id and (s.status = 'active' or s.merchant_id = (select auth.uid()) or (select public.is_admin()))));
create policy handoff_options_select on public.handoff_options for select using (exists (select 1 from public.stores s where s.id = store_id and (s.status = 'active' or s.merchant_id = (select auth.uid()) or (select public.is_admin()))));
create policy social_links_select on public.social_links for select using (exists (select 1 from public.stores s where s.id = store_id and (s.status = 'active' or s.merchant_id = (select auth.uid()) or (select public.is_admin()))));
create policy admin_roles_select on public.admin_roles for select using ((select public.is_admin()));
create policy admin_users_select on public.admin_users for select using (user_id = (select auth.uid()) or (select public.is_admin()));
create policy audit_logs_select on public.audit_logs for select using ((select public.is_admin()));

-- Ownership/admin write policies use initplan-safe auth calls.
create policy profiles_update on public.profiles for update using (user_id = (select auth.uid()) or (select public.is_admin())) with check (user_id = (select auth.uid()) or (select public.is_admin()));
create policy merchant_profiles_insert on public.merchant_profiles for insert with check (user_id = (select auth.uid()) or (select public.is_admin()));
create policy merchant_profiles_update on public.merchant_profiles for update using (user_id = (select auth.uid()) or (select public.is_admin())) with check (user_id = (select auth.uid()) or (select public.is_admin()));

create policy regions_insert on public.regions for insert with check ((select public.is_admin()));
create policy regions_update on public.regions for update using ((select public.is_admin())) with check ((select public.is_admin()));
create policy regions_delete on public.regions for delete using ((select public.is_admin()));
create policy categories_insert on public.categories for insert with check ((select public.is_admin()));
create policy categories_update on public.categories for update using ((select public.is_admin())) with check ((select public.is_admin()));
create policy categories_delete on public.categories for delete using ((select public.is_admin()));
create policy taxonomy_insert on public.honey_taxonomy for insert with check ((select public.is_admin()));
create policy taxonomy_update on public.honey_taxonomy for update using ((select public.is_admin())) with check ((select public.is_admin()));
create policy taxonomy_delete on public.honey_taxonomy for delete using ((select public.is_admin()));

create policy stores_insert on public.stores for insert with check (merchant_id = (select auth.uid()) or (select public.is_admin()));
create policy stores_update on public.stores for update using (merchant_id = (select auth.uid()) or (select public.is_admin())) with check (merchant_id = (select auth.uid()) or (select public.is_admin()));
create policy stores_delete on public.stores for delete using (merchant_id = (select auth.uid()) or (select public.is_admin()));
create policy store_followers_insert on public.store_followers for insert with check (user_id = (select auth.uid()));
create policy store_followers_delete on public.store_followers for delete using (user_id = (select auth.uid()));
create policy store_gallery_insert on public.store_gallery for insert with check (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy store_gallery_update on public.store_gallery for update using (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin())) with check (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy store_gallery_delete on public.store_gallery for delete using (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy store_statistics_insert on public.store_statistics for insert with check ((select public.is_admin()));
create policy store_statistics_update on public.store_statistics for update using ((select public.is_admin())) with check ((select public.is_admin()));
create policy store_statistics_delete on public.store_statistics for delete using ((select public.is_admin()));

create policy products_insert on public.products for insert with check (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy products_update on public.products for update using (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin())) with check (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy products_delete on public.products for delete using (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy product_images_insert on public.product_images for insert with check (exists (select 1 from public.products p join public.stores s on s.id = p.store_id where p.id = product_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy product_images_update on public.product_images for update using (exists (select 1 from public.products p join public.stores s on s.id = p.store_id where p.id = product_id and s.merchant_id = (select auth.uid())) or (select public.is_admin())) with check (exists (select 1 from public.products p join public.stores s on s.id = p.store_id where p.id = product_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy product_images_delete on public.product_images for delete using (exists (select 1 from public.products p join public.stores s on s.id = p.store_id where p.id = product_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy product_categories_insert on public.product_categories for insert with check (exists (select 1 from public.products p join public.stores s on s.id = p.store_id where p.id = product_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy product_categories_update on public.product_categories for update using (exists (select 1 from public.products p join public.stores s on s.id = p.store_id where p.id = product_id and s.merchant_id = (select auth.uid())) or (select public.is_admin())) with check (exists (select 1 from public.products p join public.stores s on s.id = p.store_id where p.id = product_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy product_categories_delete on public.product_categories for delete using (exists (select 1 from public.products p join public.stores s on s.id = p.store_id where p.id = product_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy certifications_insert on public.certifications for insert with check ((select public.is_admin()));
create policy certifications_update on public.certifications for update using ((select public.is_admin())) with check ((select public.is_admin()));
create policy certifications_delete on public.certifications for delete using ((select public.is_admin()));
create policy product_certifications_insert on public.product_certifications for insert with check (exists (select 1 from public.products p join public.stores s on s.id = p.store_id where p.id = product_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy product_certifications_update on public.product_certifications for update using (exists (select 1 from public.products p join public.stores s on s.id = p.store_id where p.id = product_id and s.merchant_id = (select auth.uid())) or (select public.is_admin())) with check (exists (select 1 from public.products p join public.stores s on s.id = p.store_id where p.id = product_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy product_certifications_delete on public.product_certifications for delete using (exists (select 1 from public.products p join public.stores s on s.id = p.store_id where p.id = product_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));

create policy reviews_insert on public.reviews for insert with check (author_id = (select auth.uid()));
create policy reviews_update on public.reviews for update using (author_id = (select auth.uid()) or (select public.is_admin())) with check (author_id = (select auth.uid()) or (select public.is_admin()));
create policy review_likes_insert on public.review_likes for insert with check (user_id = (select auth.uid()));
create policy review_likes_delete on public.review_likes for delete using (user_id = (select auth.uid()));
create policy comments_insert on public.comments for insert with check (author_id = (select auth.uid()));
create policy comments_update on public.comments for update using (author_id = (select auth.uid()) or (select public.is_admin())) with check (author_id = (select auth.uid()) or (select public.is_admin()));
create policy comments_delete on public.comments for delete using (author_id = (select auth.uid()) or (select public.is_admin()));
create policy comment_likes_insert on public.comment_likes for insert with check (user_id = (select auth.uid()));
create policy comment_likes_delete on public.comment_likes for delete using (user_id = (select auth.uid()));
create policy favorites_insert on public.favorites for insert with check (user_id = (select auth.uid()));
create policy favorites_update on public.favorites for update using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy favorites_delete on public.favorites for delete using (user_id = (select auth.uid()));

create policy requests_insert on public.requests for insert with check (requester_id = (select auth.uid()));
create policy requests_update on public.requests for update using (requester_id = (select auth.uid()) or exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin())) with check (requester_id = (select auth.uid()) or exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy request_items_insert on public.request_items for insert with check (exists (select 1 from public.requests r where r.id = request_id and (r.requester_id = (select auth.uid()) or exists (select 1 from public.stores s where s.id = r.store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()))));
create policy request_items_update on public.request_items for update using (exists (select 1 from public.requests r where r.id = request_id and (r.requester_id = (select auth.uid()) or exists (select 1 from public.stores s where s.id = r.store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin())))) with check (exists (select 1 from public.requests r where r.id = request_id and (r.requester_id = (select auth.uid()) or exists (select 1 from public.stores s where s.id = r.store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()))));
create policy request_items_delete on public.request_items for delete using (exists (select 1 from public.requests r where r.id = request_id and (r.requester_id = (select auth.uid()) or exists (select 1 from public.stores s where s.id = r.store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()))));
create policy request_messages_insert on public.request_messages for insert with check (sender_id = (select auth.uid()) and exists (select 1 from public.requests r join public.stores s on s.id = r.store_id where r.id = request_id and (r.requester_id = (select auth.uid()) or s.merchant_id = (select auth.uid()))));
create policy request_messages_update on public.request_messages for update using (sender_id = (select auth.uid()) or (select public.is_admin())) with check (sender_id = (select auth.uid()) or (select public.is_admin()));
create policy request_messages_delete on public.request_messages for delete using (sender_id = (select auth.uid()) or (select public.is_admin()));
create policy notifications_update on public.notifications for update using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create policy banners_insert on public.banners for insert with check ((select public.is_admin()));
create policy banners_update on public.banners for update using ((select public.is_admin())) with check ((select public.is_admin()));
create policy banners_delete on public.banners for delete using ((select public.is_admin()));
create policy delivery_methods_insert on public.delivery_methods for insert with check ((select public.is_admin()));
create policy delivery_methods_update on public.delivery_methods for update using ((select public.is_admin())) with check ((select public.is_admin()));
create policy delivery_methods_delete on public.delivery_methods for delete using ((select public.is_admin()));
create policy pickup_locations_insert on public.merchant_pickup_locations for insert with check (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy pickup_locations_update on public.merchant_pickup_locations for update using (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin())) with check (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy pickup_locations_delete on public.merchant_pickup_locations for delete using (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy delivery_options_insert on public.merchant_delivery_options for insert with check (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy delivery_options_update on public.merchant_delivery_options for update using (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin())) with check (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy delivery_options_delete on public.merchant_delivery_options for delete using (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy handoff_options_insert on public.handoff_options for insert with check (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy handoff_options_update on public.handoff_options for update using (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin())) with check (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy handoff_options_delete on public.handoff_options for delete using (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy social_links_insert on public.social_links for insert with check (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy social_links_update on public.social_links for update using (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin())) with check (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));
create policy social_links_delete on public.social_links for delete using (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = (select auth.uid())) or (select public.is_admin()));

create policy admin_roles_insert on public.admin_roles for insert with check ((select public.is_admin()));
create policy admin_roles_update on public.admin_roles for update using ((select public.is_admin())) with check ((select public.is_admin()));
create policy admin_roles_delete on public.admin_roles for delete using ((select public.is_admin()));
create policy admin_users_insert on public.admin_users for insert with check ((select public.is_admin()));
create policy admin_users_update on public.admin_users for update using ((select public.is_admin())) with check ((select public.is_admin()));
create policy admin_users_delete on public.admin_users for delete using ((select public.is_admin()));
create policy audit_logs_insert on public.audit_logs for insert with check (actor_user_id = (select auth.uid()) or (select public.is_admin()));

-- Cover all foreign keys reported by Supabase performance advisors.
create index if not exists admin_users_role_id_idx on public.admin_users(role_id);
create index if not exists audit_logs_actor_user_id_idx on public.audit_logs(actor_user_id);
create index if not exists categories_parent_id_idx on public.categories(parent_id);
create index if not exists comment_likes_user_id_idx on public.comment_likes(user_id);
create index if not exists comments_author_id_idx on public.comments(author_id);
create index if not exists comments_parent_comment_id_idx on public.comments(parent_comment_id);
create index if not exists favorites_product_id_idx on public.favorites(product_id);
create index if not exists favorites_store_id_idx on public.favorites(store_id);
create index if not exists merchant_delivery_options_delivery_method_id_idx on public.merchant_delivery_options(delivery_method_id);
create index if not exists merchant_delivery_options_region_id_idx on public.merchant_delivery_options(region_id);
create index if not exists merchant_pickup_locations_region_id_idx on public.merchant_pickup_locations(region_id);
create index if not exists merchant_pickup_locations_store_id_idx on public.merchant_pickup_locations(store_id);
create index if not exists product_categories_category_id_idx on public.product_categories(category_id);
create index if not exists product_certifications_certification_id_idx on public.product_certifications(certification_id);
create index if not exists regions_parent_region_id_idx on public.regions(parent_region_id);
create index if not exists request_items_product_id_idx on public.request_items(product_id);
create index if not exists request_messages_sender_id_idx on public.request_messages(sender_id);
create index if not exists review_likes_user_id_idx on public.review_likes(user_id);
create index if not exists reviews_author_id_idx on public.reviews(author_id);
create index if not exists reviews_store_id_idx on public.reviews(store_id);
create index if not exists store_followers_user_id_idx on public.store_followers(user_id);
create index if not exists store_gallery_store_id_idx on public.store_gallery(store_id);
