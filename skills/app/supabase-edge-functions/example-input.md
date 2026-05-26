# Example Input — Supabase Edge Functions

Building a Supabase Edge Function to call the Gemini API and cache results in a Supabase table.

Current issues:
- Tried importing `npm:@google/generative-ai@0.21.0` in the Deno function — throws at import
- Function deployed and invoked — client throws `FunctionsHttpError` with message "non-2xx status code", no useful detail
- Running `supabase login` in PowerShell before deployment — CLI hangs indefinitely
- Switched to `gemini-1.5-flash` model in the REST API call — returns 404
- Fixed an incorrect summary that was written to the cache table — client still shows the wrong data

What needs fixing?
