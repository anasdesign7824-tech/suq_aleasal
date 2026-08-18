-- Preserve the customer request UX contract in Production without encoding structured data into body.
alter table public.requests
  add column if not exists phone text,
  add column if not exists contact_channel text,
  add column if not exists delivery_note text,
  add column if not exists price_note text,
  add column if not exists handoff_details jsonb not null default '{}'::jsonb;

comment on column public.requests.handoff_details is 'Structured handoff details supplied by the requester; never contains secrets.';

create index if not exists requests_contact_channel_idx on public.requests(contact_channel);
