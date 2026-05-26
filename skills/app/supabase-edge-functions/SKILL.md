---
name: supabase-edge-functions
description: Write, deploy, and debug Supabase Edge Functions — Deno import constraints, CLI auth, LLM provider integration, and cache invalidation patterns
author: PowerData
version: 1.0.0
license: MIT
---

# Supabase Edge Functions

## Purpose

Guide the authoring, deployment, and debugging of Supabase Edge Functions (Deno runtime), covering Deno-specific module constraints, non-interactive terminal auth, LLM provider REST API integration, error extraction from the client, and cache invalidation when bad data is persisted by a function.

## When to use

When writing a new Supabase Edge Function or debugging a deployment, error, or data issue that originates from one. Apply before first deployment to avoid the class of Deno module failures and auth hangs that are non-obvious coming from a Node.js background. Also apply when integrating LLM providers (Gemini, OpenAI, Anthropic) via REST API.

## Inputs expected

- Edge function code or error message
- Deployment environment (local dev, CI, PowerShell)
- LLM provider in use (if applicable)
- Client-side caching strategy (if applicable)

---

## Guiding principles

- **Don't use npm SDK packages in Deno — use the provider's REST API directly.** npm-style imports (`npm:@google/generative-ai@0.21.0`) fail to resolve in Deno edge functions. Call the LLM provider's REST API via `fetch` — this is more stable, has no dependency on Deno's npm compatibility layer, and works across all providers with a single pattern.
- **`FunctionsHttpError` hides the real error — extract it from `error.context`.** When `supabase.functions.invoke` throws `FunctionsHttpError`, the `.message` is always "non-2xx status code". The actual error body from the edge function is in `error.context` — call `error.context.clone().json()` to read it.
- **`supabase login` hangs in non-interactive terminals — use `SUPABASE_ACCESS_TOKEN` instead.** In PowerShell and CI environments, `supabase login` blocks waiting for user input. Set `SUPABASE_ACCESS_TOKEN` as an environment variable before running `supabase functions deploy` to authenticate without interaction.
- **Check LLM model names and quota settings when calls return 404 or `limit: 0`.** `gemini-1.5-flash` is deprecated on the v1beta REST API and returns 404. Use `gemini-2.0-flash` or `gemini-flash-lite-latest`. A quota error with `limit: 0` indicates the Google Cloud project has no free tier enabled — this is usually an org policy restriction, not exhausted quota.
- **Client-side caches will serve bad data even after the edge function is fixed — delete the bad row.** When an edge function writes incorrect data to a database cache table, the client will keep reading the bad row because stale checks typically only trigger when no row exists for the expected key. Delete the affected row directly in the Supabase SQL Editor to force a fresh fetch.

## Process

1. **Write the edge function using `fetch` for external API calls.** Do not import npm SDK packages — use the provider's REST API endpoint directly. Structure the function to return a consistent JSON response with explicit status codes.
2. **Authenticate for deployment without interactive login.** Set `SUPABASE_ACCESS_TOKEN` in the environment before deploying: `$env:SUPABASE_ACCESS_TOKEN = "sbp_..."` (PowerShell) or `export SUPABASE_ACCESS_TOKEN="sbp_..."` (bash). Then run `supabase functions deploy <function-name>`.
3. **Test the deployed function and extract errors properly.** Call via `supabase.functions.invoke`. On error, read `error.context.clone().json()` — not `error.message` — to see the actual response from the function.
4. **Verify LLM model availability and quota.** If calls return 404, check the model name against the provider's current API. If quota shows `limit: 0`, check GCP → APIs & Services → Quotas for org-level policy restrictions, not just per-project limits.
5. **Invalidate bad cached data by deleting the affected rows.** If incorrect data was written to a cache table, delete the row via the Supabase SQL Editor. Do not rely on the client's stale check — it only triggers on absence, not on bad data.

## Output format

1. **Deployment checklist** — auth method confirmed, function deployed, test call successful
2. **Error diagnosis** — root cause identified from `error.context`, not `error.message`
3. **LLM integration notes** — model name confirmed, quota verified, REST API endpoint used
4. **Cache state** — any bad rows deleted, fresh fetch confirmed

## Quality checklist

- [ ] No npm SDK packages imported — all external calls use `fetch` against REST APIs
- [ ] Deployment uses `SUPABASE_ACCESS_TOKEN`, not interactive `supabase login`
- [ ] Error handling reads `error.context.clone().json()` on `FunctionsHttpError`
- [ ] LLM model name verified against current provider API (not deprecated `gemini-1.5-flash`)
- [ ] Any bad cached rows deleted directly before verifying the fix

## Avoid

- Importing npm SDK packages in Deno (`npm:@google/generative-ai` and similar) — they fail silently or throw at import time
- Reading `error.message` from `FunctionsHttpError` — it is always generic; the real error is in `error.context`
- Running `supabase login` in PowerShell or CI — it hangs waiting for input; use `SUPABASE_ACCESS_TOKEN`
- Using deprecated Gemini model names (`gemini-1.5-flash`) — they return 404 on the v1beta API
- Assuming a quota error with `limit: 0` means exhausted quota — it usually means the GCP project has no free tier enabled

## Example usage

> Edge function calling Gemini REST API returns 404. `supabase login` hangs in PowerShell before deployment. Client keeps showing wrong data after the function was fixed.

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
