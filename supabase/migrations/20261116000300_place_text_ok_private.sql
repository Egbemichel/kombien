-- place_text_ok is only a helper the request functions call; riders need not
-- (and should not) be able to call it themselves. The functions that use it
-- run as their owner, so they are unaffected.
revoke all on function public.place_text_ok(text) from anon, authenticated;
