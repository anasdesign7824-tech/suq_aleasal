create table if not exists public.product_view_events (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  viewer_id uuid references public.users(id) on delete set null,
  viewed_at timestamptz not null default timezone('utc', now())
);

alter table public.product_view_events enable row level security;
create policy product_views_insert on public.product_view_events for insert with check (viewer_id is null or viewer_id = (select auth.uid()) or (select public.is_admin()));
create policy product_views_admin_select on public.product_view_events for select using ((select public.is_admin()));
create index if not exists product_view_events_product_idx on public.product_view_events(product_id, viewed_at desc);
create index if not exists product_view_events_viewer_idx on public.product_view_events(viewer_id, viewed_at desc);
