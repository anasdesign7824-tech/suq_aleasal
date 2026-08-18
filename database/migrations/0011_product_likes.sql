create table if not exists public.product_likes (
  product_id uuid not null references public.products(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (product_id, user_id)
);

alter table public.product_likes enable row level security;
create policy product_likes_select on public.product_likes for select using (user_id = (select auth.uid()) or (select public.is_admin()));
create policy product_likes_insert on public.product_likes for insert with check (user_id = (select auth.uid()) or (select public.is_admin()));
create policy product_likes_delete on public.product_likes for delete using (user_id = (select auth.uid()) or (select public.is_admin()));
create index if not exists product_likes_user_id_idx on public.product_likes(user_id, product_id);
