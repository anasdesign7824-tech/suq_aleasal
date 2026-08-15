-- Souq Al Assal / عسلكم — remove public security-definer view.
-- Public profile reading is intentionally restricted to owner/admin policies until a safe API projection is introduced.

revoke all on public.profile_cards from anon, authenticated;
drop view if exists public.profile_cards;
