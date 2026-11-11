-- search_misses is reached only through log_search_miss(). Row security already
-- stops the API reading or writing it (no policies), but Supabase also grants
-- table privileges to the API roles by default; take those away too, so the
-- table is closed even if a policy were ever added by mistake.

revoke all on public.search_misses from anon, authenticated;
