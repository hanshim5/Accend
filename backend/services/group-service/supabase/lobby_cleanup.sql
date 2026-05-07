-- Group-session lobby cleanup triggers.
--
-- Run this in Supabase SQL editor after creating:
-- - public.lobby_items
-- - public.lobby_turn_state
--
-- It deletes lobby-scoped rows once the last member leaves either
-- private_lobbies or public_lobbies.

create or replace function public.cleanup_group_lobby_state_on_empty()
returns trigger
language plpgsql
as $$
declare
  v_lobby_kind text;
  v_remaining_members integer;
begin
  v_lobby_kind := case
    when TG_TABLE_NAME = 'private_lobbies' then 'private'
    when TG_TABLE_NAME = 'public_lobbies' then 'public'
    else null
  end;

  if v_lobby_kind is null then
    return null;
  end if;

  if TG_TABLE_NAME = 'private_lobbies' then
    select count(*)
      into v_remaining_members
      from public.private_lobbies
     where lobby_id = OLD.lobby_id;
  else
    select count(*)
      into v_remaining_members
      from public.public_lobbies
     where lobby_id = OLD.lobby_id;
  end if;

  -- Only cleanup when this was the last member row for that lobby.
  if v_remaining_members = 0 then
    delete from public.lobby_items
     where lobby_kind = v_lobby_kind
       and lobby_id = OLD.lobby_id;

    delete from public.lobby_turn_state
     where lobby_kind = v_lobby_kind
       and lobby_id = OLD.lobby_id;
  end if;

  return null;
end;
$$;

drop trigger if exists trg_cleanup_group_lobby_state_private on public.private_lobbies;
create trigger trg_cleanup_group_lobby_state_private
after delete on public.private_lobbies
for each row
execute function public.cleanup_group_lobby_state_on_empty();

drop trigger if exists trg_cleanup_group_lobby_state_public on public.public_lobbies;
create trigger trg_cleanup_group_lobby_state_public
after delete on public.public_lobbies
for each row
execute function public.cleanup_group_lobby_state_on_empty();
