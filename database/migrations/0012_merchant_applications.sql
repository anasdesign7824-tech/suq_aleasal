create table if not exists public.merchant_applications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  display_name text not null,
  phone text not null,
  experience text not null,
  location text not null,
  specialties text not null,
  certificate_note text,
  status text not null default 'submitted' check (status in ('submitted', 'under_review', 'approved', 'rejected', 'withdrawn')),
  submitted_at timestamptz not null default timezone('utc', now()),
  reviewed_at timestamptz,
  reviewed_by uuid references public.users(id) on delete set null,
  review_note text,
  unique (user_id)
);

create table if not exists public.merchant_application_drafts (
  user_id uuid primary key references public.users(id) on delete cascade,
  display_name text not null default '',
  phone text not null default '',
  experience text not null default '',
  location text not null default '',
  specialties text not null default '',
  certificate_note text,
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.merchant_applications enable row level security;
alter table public.merchant_application_drafts enable row level security;
create policy merchant_applications_select on public.merchant_applications for select using (user_id = (select auth.uid()) or (select public.is_admin()));
create policy merchant_applications_insert on public.merchant_applications for insert with check (user_id = (select auth.uid()) or (select public.is_admin()));
create policy merchant_applications_update on public.merchant_applications for update using (user_id = (select auth.uid()) or (select public.is_admin())) with check (user_id = (select auth.uid()) or (select public.is_admin()));
create policy merchant_application_drafts_self on public.merchant_application_drafts for all using (user_id = (select auth.uid()) or (select public.is_admin())) with check (user_id = (select auth.uid()) or (select public.is_admin()));
create index if not exists merchant_applications_status_idx on public.merchant_applications(status, submitted_at desc);
