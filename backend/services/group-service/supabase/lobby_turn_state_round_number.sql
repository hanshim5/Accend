-- Add backend-authoritative round counter for prompt sync.
-- Run once in Supabase SQL editor.

alter table public.lobby_turn_state
  add column if not exists round_number integer not null default 0;
