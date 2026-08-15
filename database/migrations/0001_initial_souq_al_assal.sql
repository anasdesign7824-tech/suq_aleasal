-- Souq Al Assal / عسلكم — initial production schema
-- Phase 4: schema is production-ready but does not drive Demo Mode.

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
security invoker
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  last_seen_at timestamptz
);

create table public.profiles (
  user_id uuid primary key references public.users(id) on delete cascade,
  display_name text not null default 'مستخدم عسلكم',
  phone text,
  avatar_url text,
  bio text,
  role text not null default 'customer' check (role in ('customer', 'merchant', 'admin')),
  locale text not null default 'ar',
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.merchant_profiles (
  user_id uuid primary key references public.users(id) on delete cascade,
  business_name text not null,
  legal_name text,
  description text,
  verification_status text not null default 'pending' check (verification_status in ('pending', 'verified', 'rejected', 'suspended')),
  verified_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.regions (
  id uuid primary key default gen_random_uuid(),
  parent_region_id uuid references public.regions(id) on delete set null,
  name_ar text not null,
  name_en text,
  code text unique,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now())
);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid references public.categories(id) on delete set null,
  name_ar text not null,
  name_en text,
  slug text not null unique,
  category_kind text not null default 'honey' check (category_kind in ('honey', 'wax', 'mix', 'raw', 'gift')),
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.honey_taxonomy (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name_ar text not null,
  name_en text,
  description text,
  metadata jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.stores (
  id uuid primary key default gen_random_uuid(),
  merchant_id uuid not null references public.merchant_profiles(user_id) on delete cascade,
  region_id uuid references public.regions(id) on delete set null,
  name_ar text not null,
  slug text not null unique,
  description text,
  phone text,
  logo_url text,
  cover_url text,
  status text not null default 'pending' check (status in ('pending', 'active', 'paused', 'rejected', 'suspended')),
  is_verified boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.store_followers (
  store_id uuid not null references public.stores(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (store_id, user_id)
);

create table public.store_gallery (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  media_url text not null,
  alt_text_ar text,
  sort_order integer not null default 0,
  created_at timestamptz not null default timezone('utc', now())
);

create table public.store_statistics (
  store_id uuid primary key references public.stores(id) on delete cascade,
  followers_count integer not null default 0 check (followers_count >= 0),
  product_count integer not null default 0 check (product_count >= 0),
  rating_average numeric(3,2) not null default 0 check (rating_average >= 0 and rating_average <= 5),
  review_count integer not null default 0 check (review_count >= 0),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  taxonomy_id uuid references public.honey_taxonomy(id) on delete set null,
  name_ar text not null,
  name_en text,
  description text,
  product_type text not null default 'honey' check (product_type in ('honey', 'wax', 'mix', 'raw', 'gift')),
  grade_level smallint check (grade_level between 1 and 4),
  status text not null default 'draft' check (status in ('draft', 'pending', 'active', 'paused', 'rejected')),
  is_featured boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  image_url text not null,
  alt_text_ar text,
  sort_order integer not null default 0,
  created_at timestamptz not null default timezone('utc', now())
);

create table public.product_categories (
  product_id uuid not null references public.products(id) on delete cascade,
  category_id uuid not null references public.categories(id) on delete cascade,
  primary key (product_id, category_id)
);

create table public.certifications (
  id uuid primary key default gen_random_uuid(),
  name_ar text not null,
  issuer text,
  description text,
  icon_key text,
  created_at timestamptz not null default timezone('utc', now())
);

create table public.product_certifications (
  product_id uuid not null references public.products(id) on delete cascade,
  certification_id uuid not null references public.certifications(id) on delete cascade,
  primary key (product_id, certification_id)
);

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  store_id uuid not null references public.stores(id) on delete cascade,
  author_id uuid not null references public.users(id) on delete cascade,
  rating smallint not null check (rating between 1 and 5),
  body text,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected', 'hidden')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (product_id, author_id)
);

create table public.review_likes (
  review_id uuid not null references public.reviews(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (review_id, user_id)
);

create table public.comments (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.users(id) on delete cascade,
  product_id uuid references public.products(id) on delete cascade,
  review_id uuid references public.reviews(id) on delete cascade,
  parent_comment_id uuid references public.comments(id) on delete cascade,
  body text not null,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected', 'hidden')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (product_id is not null or review_id is not null)
);

create table public.comment_likes (
  comment_id uuid not null references public.comments(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (comment_id, user_id)
);

create table public.favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  product_id uuid references public.products(id) on delete cascade,
  store_id uuid references public.stores(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  check ((product_id is not null and store_id is null) or (product_id is null and store_id is not null)
));

create unique index favorites_user_product_idx on public.favorites(user_id, product_id) where product_id is not null;
create unique index favorites_user_store_idx on public.favorites(user_id, store_id) where store_id is not null;

create table public.requests (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.users(id) on delete cascade,
  store_id uuid not null references public.stores(id) on delete cascade,
  subject text not null,
  body text,
  status text not null default 'open' check (status in ('open', 'in_progress', 'answered', 'closed', 'cancelled')),
  preferred_handoff_option text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.request_items (
  request_id uuid not null references public.requests(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete restrict,
  quantity integer not null default 1 check (quantity > 0),
  note text,
  primary key (request_id, product_id)
);

create table public.request_messages (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.requests(id) on delete cascade,
  sender_id uuid not null references public.users(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default timezone('utc', now())
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  notification_type text not null,
  title_ar text not null,
  body_ar text,
  payload jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default timezone('utc', now())
);

create table public.banners (
  id uuid primary key default gen_random_uuid(),
  title_ar text not null,
  body_ar text,
  image_url text,
  cta_label_ar text,
  cta_url text,
  starts_at timestamptz,
  ends_at timestamptz,
  sort_order integer not null default 0,
  is_active boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.delivery_methods (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name_ar text not null,
  description text,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now())
);

create table public.merchant_pickup_locations (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  region_id uuid references public.regions(id) on delete set null,
  name_ar text not null,
  address text,
  geo_lat numeric(9,6),
  geo_lng numeric(9,6),
  phone text,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.merchant_delivery_options (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  delivery_method_id uuid not null references public.delivery_methods(id) on delete restrict,
  region_id uuid references public.regions(id) on delete set null,
  fee_amount numeric(12,2) check (fee_amount >= 0),
  currency text not null default 'YER',
  estimated_days smallint check (estimated_days >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  unique (store_id, delivery_method_id, region_id)
);

create table public.handoff_options (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  code text not null,
  name_ar text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  unique (store_id, code)
);

create table public.social_links (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  platform text not null,
  url text not null,
  created_at timestamptz not null default timezone('utc', now()),
  unique (store_id, platform)
);

create table public.admin_roles (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name_ar text not null,
  permissions jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create table public.admin_users (
  user_id uuid primary key references public.users(id) on delete cascade,
  role_id uuid not null references public.admin_roles(id) on delete restrict,
  created_at timestamptz not null default timezone('utc', now())
);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references public.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (select 1 from public.admin_users where user_id = auth.uid());
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id) values (new.id) on conflict (id) do nothing;
  insert into public.profiles (user_id, display_name) values (new.id, coalesce(new.raw_user_meta_data->>'name', 'مستخدم عسلكم')) on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create or replace function public.prevent_profile_role_escalation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.role is distinct from old.role and not public.is_admin() then
    raise exception 'Only an admin may change profile roles';
  end if;
  return new;
end;
$$;

create or replace function public.prevent_merchant_verification_changes()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if (new.verification_status is distinct from old.verification_status or new.verified_at is distinct from old.verified_at) and not public.is_admin() then
    raise exception 'Only an admin may change merchant verification';
  end if;
  return new;
end;
$$;

create or replace function public.prevent_store_moderation_changes()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if (new.status is distinct from old.status or new.is_verified is distinct from old.is_verified) and not public.is_admin() then
    raise exception 'Only an admin may change store moderation fields';
  end if;
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

create trigger profiles_role_guard before update on public.profiles for each row execute procedure public.prevent_profile_role_escalation();
create trigger merchant_verification_guard before update on public.merchant_profiles for each row execute procedure public.prevent_merchant_verification_changes();
create trigger store_moderation_guard before update on public.stores for each row execute procedure public.prevent_store_moderation_changes();

create trigger profiles_updated_at before update on public.profiles for each row execute procedure public.set_updated_at();
create trigger merchant_profiles_updated_at before update on public.merchant_profiles for each row execute procedure public.set_updated_at();
create trigger categories_updated_at before update on public.categories for each row execute procedure public.set_updated_at();
create trigger honey_taxonomy_updated_at before update on public.honey_taxonomy for each row execute procedure public.set_updated_at();
create trigger stores_updated_at before update on public.stores for each row execute procedure public.set_updated_at();
create trigger products_updated_at before update on public.products for each row execute procedure public.set_updated_at();
create trigger reviews_updated_at before update on public.reviews for each row execute procedure public.set_updated_at();
create trigger comments_updated_at before update on public.comments for each row execute procedure public.set_updated_at();
create trigger requests_updated_at before update on public.requests for each row execute procedure public.set_updated_at();
create trigger banners_updated_at before update on public.banners for each row execute procedure public.set_updated_at();
create trigger pickup_locations_updated_at before update on public.merchant_pickup_locations for each row execute procedure public.set_updated_at();

create index stores_merchant_idx on public.stores(merchant_id);
create index stores_region_idx on public.stores(region_id);
create index products_store_idx on public.products(store_id);
create index products_taxonomy_idx on public.products(taxonomy_id);
create index products_status_idx on public.products(status);
create index product_images_product_idx on public.product_images(product_id, sort_order);
create index reviews_product_idx on public.reviews(product_id, status);
create index comments_product_idx on public.comments(product_id, status);
create index comments_review_idx on public.comments(review_id, status);
create index requests_requester_idx on public.requests(requester_id, status);
create index requests_store_idx on public.requests(store_id, status);
create index request_messages_request_idx on public.request_messages(request_id, created_at);
create index notifications_user_idx on public.notifications(user_id, read_at, created_at desc);
create index banners_active_idx on public.banners(is_active, starts_at, ends_at, sort_order);
create index audit_logs_entity_idx on public.audit_logs(entity_type, entity_id, created_at desc);

alter table public.users enable row level security;
alter table public.profiles enable row level security;
alter table public.merchant_profiles enable row level security;
alter table public.regions enable row level security;
alter table public.categories enable row level security;
alter table public.honey_taxonomy enable row level security;
alter table public.stores enable row level security;
alter table public.store_followers enable row level security;
alter table public.store_gallery enable row level security;
alter table public.store_statistics enable row level security;
alter table public.products enable row level security;
alter table public.product_images enable row level security;
alter table public.product_categories enable row level security;
alter table public.certifications enable row level security;
alter table public.product_certifications enable row level security;
alter table public.reviews enable row level security;
alter table public.review_likes enable row level security;
alter table public.comments enable row level security;
alter table public.comment_likes enable row level security;
alter table public.favorites enable row level security;
alter table public.requests enable row level security;
alter table public.request_items enable row level security;
alter table public.request_messages enable row level security;
alter table public.notifications enable row level security;
alter table public.banners enable row level security;
alter table public.delivery_methods enable row level security;
alter table public.merchant_pickup_locations enable row level security;
alter table public.merchant_delivery_options enable row level security;
alter table public.handoff_options enable row level security;
alter table public.social_links enable row level security;
alter table public.admin_roles enable row level security;
alter table public.admin_users enable row level security;
alter table public.audit_logs enable row level security;

create policy regions_public_read on public.regions for select using (is_active);
create policy categories_public_read on public.categories for select using (is_active);
create policy taxonomy_public_read on public.honey_taxonomy for select using (is_active);
create policy stores_public_read on public.stores for select using (status = 'active');
create policy store_gallery_public_read on public.store_gallery for select using (exists (select 1 from public.stores s where s.id = store_id and s.status = 'active'));
create policy store_stats_public_read on public.store_statistics for select using (exists (select 1 from public.stores s where s.id = store_id and s.status = 'active'));
create policy products_public_read on public.products for select using (status = 'active' and exists (select 1 from public.stores s where s.id = store_id and s.status = 'active'));
create policy product_images_public_read on public.product_images for select using (exists (select 1 from public.products p join public.stores s on s.id = p.store_id where p.id = product_id and p.status = 'active' and s.status = 'active'));
create policy product_categories_public_read on public.product_categories for select using (exists (select 1 from public.products p where p.id = product_id and p.status = 'active'));
create policy certifications_public_read on public.certifications for select using (true);
create policy product_certifications_public_read on public.product_certifications for select using (exists (select 1 from public.products p where p.id = product_id and p.status = 'active'));
create policy reviews_public_read on public.reviews for select using (status = 'approved');
create policy comments_public_read on public.comments for select using (status = 'approved');
create policy banners_public_read on public.banners for select using (is_active and (starts_at is null or starts_at <= now()) and (ends_at is null or ends_at >= now()));
create policy delivery_methods_public_read on public.delivery_methods for select using (is_active);
create policy pickup_public_read on public.merchant_pickup_locations for select using (is_active and exists (select 1 from public.stores s where s.id = store_id and s.status = 'active'));
create policy delivery_options_public_read on public.merchant_delivery_options for select using (is_active and exists (select 1 from public.stores s where s.id = store_id and s.status = 'active'));
create policy handoff_public_read on public.handoff_options for select using (is_active and exists (select 1 from public.stores s where s.id = store_id and s.status = 'active'));
create policy social_links_public_read on public.social_links for select using (exists (select 1 from public.stores s where s.id = store_id and s.status = 'active'));

create policy users_self_read on public.users for select using (id = auth.uid() or public.is_admin());
create policy regions_admin_read on public.regions for select using (public.is_admin());
create policy categories_admin_read on public.categories for select using (public.is_admin());
create policy taxonomy_admin_read on public.honey_taxonomy for select using (public.is_admin());
create policy stores_owner_read on public.stores for select using (merchant_id = auth.uid() or public.is_admin());
create policy store_stats_owner_read on public.store_statistics for select using (exists (select 1 from public.stores s where s.id = store_id and (s.merchant_id = auth.uid() or public.is_admin())));
create policy products_owner_read on public.products for select using (exists (select 1 from public.stores s where s.id = store_id and (s.merchant_id = auth.uid() or public.is_admin())));
create policy product_images_owner_read on public.product_images for select using (exists (select 1 from public.products p join public.stores s on s.id = p.store_id where p.id = product_id and (s.merchant_id = auth.uid() or public.is_admin())));
create policy product_categories_admin_read on public.product_categories for select using (public.is_admin());
create policy certifications_admin_write on public.certifications for all using (public.is_admin()) with check (public.is_admin());
create policy reviews_author_read on public.reviews for select using (author_id = auth.uid() or public.is_admin() or exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = auth.uid()));
create policy comments_author_read on public.comments for select using (author_id = auth.uid() or public.is_admin() or exists (select 1 from public.products p join public.stores s on s.id = p.store_id where p.id = product_id and s.merchant_id = auth.uid()));
create policy pickup_owner_read on public.merchant_pickup_locations for select using (exists (select 1 from public.stores s where s.id = store_id and (s.merchant_id = auth.uid() or public.is_admin())));
create policy delivery_options_owner_read on public.merchant_delivery_options for select using (exists (select 1 from public.stores s where s.id = store_id and (s.merchant_id = auth.uid() or public.is_admin())));
create policy handoff_owner_read on public.handoff_options for select using (exists (select 1 from public.stores s where s.id = store_id and (s.merchant_id = auth.uid() or public.is_admin())));
create policy social_links_owner_read on public.social_links for select using (exists (select 1 from public.stores s where s.id = store_id and (s.merchant_id = auth.uid() or public.is_admin())));
create policy profiles_public_read on public.profiles for select using (is_active or user_id = auth.uid() or public.is_admin());
create policy profiles_self_update on public.profiles for update using (user_id = auth.uid() or public.is_admin()) with check (user_id = auth.uid() or public.is_admin());
create policy merchant_profiles_self_read on public.merchant_profiles for select using (user_id = auth.uid() or public.is_admin());
create policy merchant_profiles_self_insert on public.merchant_profiles for insert with check (user_id = auth.uid() or public.is_admin());
create policy merchant_profiles_self_update on public.merchant_profiles for update using (user_id = auth.uid() or public.is_admin()) with check (user_id = auth.uid() or public.is_admin());

create policy stores_owner_insert on public.stores for insert with check (merchant_id = auth.uid() or public.is_admin());
create policy stores_owner_update on public.stores for update using (merchant_id = auth.uid() or public.is_admin()) with check (merchant_id = auth.uid() or public.is_admin());
create policy stores_owner_delete on public.stores for delete using (merchant_id = auth.uid() or public.is_admin());
create policy store_followers_self_read on public.store_followers for select using (user_id = auth.uid() or exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = auth.uid()) or public.is_admin());
create policy store_followers_self_insert on public.store_followers for insert with check (user_id = auth.uid());
create policy store_followers_self_delete on public.store_followers for delete using (user_id = auth.uid());
create policy store_gallery_owner_write on public.store_gallery for all using (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = auth.uid()) or public.is_admin()) with check (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = auth.uid()) or public.is_admin());
create policy store_stats_admin_write on public.store_statistics for all using (public.is_admin()) with check (public.is_admin());
create policy products_owner_insert on public.products for insert with check (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = auth.uid()) or public.is_admin());
create policy products_owner_update on public.products for update using (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = auth.uid()) or public.is_admin()) with check (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = auth.uid()) or public.is_admin());
create policy products_owner_delete on public.products for delete using (exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = auth.uid()) or public.is_admin());
create policy product_images_owner_write on public.product_images for all using (exists (select 1 from public.products p join public.stores s on s.id = p.store_id where p.id = product_id and s.merchant_id = auth.uid()) or public.is_admin()) with check (exists (select 1 from public.products p join public.stores s on s.id = p.store_id where p.id = product_id and s.merchant_id = auth.uid()) or public.is_admin());
create policy product_categories_owner_write on public.product_categories for all using (exists (select 1 from public.products p join public.stores s on s.id = p.store_id where p.id = product_id and s.merchant_id = auth.uid()) or public.is_admin()) with check (exists (select 1 from public.products p join public.stores s on s.id = p.store_id where p.id = product_id and s.merchant_id = auth.uid()) or public.is_admin());
create policy product_certifications_owner_write on public.product_certifications for all using (exists (select 1 from public.products p join public.stores s on s.id = p.store_id where p.id = product_id and s.merchant_id = auth.uid()) or public.is_admin()) with check (exists (select 1 from public.products p join public.stores s on s.id = p.store_id where p.id = product_id and s.merchant_id = auth.uid()) or public.is_admin());
create policy reviews_self_insert on public.reviews for insert with check (author_id = auth.uid());
create policy reviews_self_update on public.reviews for update using (author_id = auth.uid() or public.is_admin()) with check (author_id = auth.uid() or public.is_admin());
create policy review_likes_self_write on public.review_likes for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy comments_self_insert on public.comments for insert with check (author_id = auth.uid());
create policy comments_self_update on public.comments for update using (author_id = auth.uid() or public.is_admin()) with check (author_id = auth.uid() or public.is_admin());
create policy comment_likes_self_write on public.comment_likes for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy favorites_self_write on public.favorites for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy requests_participant_read on public.requests for select using (requester_id = auth.uid() or exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = auth.uid()) or public.is_admin());
create policy requests_customer_insert on public.requests for insert with check (requester_id = auth.uid());
create policy requests_participant_update on public.requests for update using (requester_id = auth.uid() or exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = auth.uid()) or public.is_admin()) with check (requester_id = auth.uid() or exists (select 1 from public.stores s where s.id = store_id and s.merchant_id = auth.uid()) or public.is_admin());
create policy request_items_participant on public.request_items for all using (exists (select 1 from public.requests r where r.id = request_id and (r.requester_id = auth.uid() or exists (select 1 from public.stores s where s.id = r.store_id and s.merchant_id = auth.uid()) or public.is_admin()))) with check (exists (select 1 from public.requests r where r.id = request_id and (r.requester_id = auth.uid() or exists (select 1 from public.stores s where s.id = r.store_id and s.merchant_id = auth.uid()) or public.is_admin())));
create policy request_messages_participant on public.request_messages for all using (sender_id = auth.uid() or exists (select 1 from public.requests r join public.stores s on s.id = r.store_id where r.id = request_id and (r.requester_id = auth.uid() or s.merchant_id = auth.uid())) or public.is_admin()) with check (sender_id = auth.uid() or exists (select 1 from public.requests r join public.stores s on s.id = r.store_id where r.id = request_id and (r.requester_id = auth.uid() or s.merchant_id = auth.uid())) or public.is_admin());
create policy notifications_self_read on public.notifications for select using (user_id = auth.uid());
create policy notifications_self_update on public.notifications for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy banners_admin_write on public.banners for all using (public.is_admin()) with check (public.is_admin());
create policy admin_roles_admin_read on public.admin_roles for select using (public.is_admin());
create policy admin_users_admin_read on public.admin_users for select using (public.is_admin() or user_id = auth.uid());
create policy admin_users_admin_write on public.admin_users for all using (public.is_admin()) with check (public.is_admin());
create policy audit_logs_admin_read on public.audit_logs for select using (public.is_admin());
create policy audit_logs_admin_insert on public.audit_logs for insert with check (actor_user_id = auth.uid() or public.is_admin());

insert into public.admin_roles (code, name_ar, permissions) values
  ('super_admin', 'مدير عام', '{"all": true}'::jsonb),
  ('admin', 'مدير', '{"content": true, "users": true, "merchants": true}'::jsonb),
  ('moderator', 'مشرف', '{"reviews": true, "comments": true, "reports": true}')
on conflict (code) do nothing;

insert into public.delivery_methods (code, name_ar, description) values
  ('pickup', 'استلام من المتجر', 'استلام مباشر من موقع التاجر'),
  ('merchant_delivery', 'توصيل التاجر', 'توصيل يحدده التاجر حسب المنطقة'),
  ('courier', 'شركة توصيل', 'توصيل عبر شركة أو طرف ثالث')
on conflict (code) do nothing;

comment on schema public is 'Souq Al Assal / سوق العسل — production schema for عسلكم; Demo Mode remains repository-backed and independent.';
