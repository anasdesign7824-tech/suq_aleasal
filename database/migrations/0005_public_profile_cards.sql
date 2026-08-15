-- Souq Al Assal / عسلكم — public profile projection without private contact fields.

drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles for select using (user_id = (select auth.uid()) or (select public.is_admin()));

create or replace view public.profile_cards as
select user_id, display_name, avatar_url, bio, role
from public.profiles
where is_active;

grant select on public.profile_cards to anon, authenticated;
