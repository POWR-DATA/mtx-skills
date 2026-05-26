# Supabase Edge Functions

Write, deploy, and debug Supabase Edge Functions — Deno import constraints, CLI auth, LLM provider integration, and cache invalidation patterns

## What this skill does

Covers the authoring and operational concerns of Supabase Edge Functions running on the Deno runtime: how to call LLM providers without npm SDK imports, how to authenticate the Supabase CLI in non-interactive terminals, how to extract real error detail from client-side errors, how to identify deprecated model names and quota issues, and how to fix client caches that have bad data written into them.

## When to use it

- Writing a Supabase Edge Function that calls an LLM provider (Gemini, OpenAI, Anthropic)
- Deploying a function from PowerShell or CI where `supabase login` hangs
- Debugging a `FunctionsHttpError` where the error message gives no useful detail
- Investigating why the client keeps showing stale or incorrect data after a function fix

## Example use cases

- Calling the Gemini REST API from a Deno edge function without importing the Google AI SDK
- Authenticating the Supabase CLI via `SUPABASE_ACCESS_TOKEN` in a PowerShell session
- Extracting the real error body from a `FunctionsHttpError` via `error.context.clone().json()`
- Deleting a bad cached row in the Supabase SQL Editor to force a fresh edge function fetch

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |

## How to use

Load `SKILL.md` into Claude Code when writing or debugging a Supabase Edge Function. Use alongside `expo-react-native-app` if the function is being called from an Expo app, or `flet-supabase-framework` if called from a Flet app.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
