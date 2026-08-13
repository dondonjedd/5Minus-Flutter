-- Seat writes no longer patch matches, so the host's Match Realtime
-- subscription never saw joins/ready. Touch updated_at so that channel fires.

create or replace function private.touch_match_from_seat()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.matches
  set updated_at = now()
  where game_code = coalesce(new.game_code, old.game_code);
  return coalesce(new, old);
end;
$$;

drop trigger if exists touch_match_on_seat_change on public.match_players;
create trigger touch_match_on_seat_change
  after insert or update or delete on public.match_players
  for each row
  execute function private.touch_match_from_seat();
