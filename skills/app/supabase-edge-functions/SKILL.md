---
name: supabase-edge-functions
description: Write, deploy, and debug Supabase Edge Functions — Deno import constraints, CLI auth, LLM provider integration, and cache invalidation patterns
author: PowerData
version: 1.2.0
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
- **New-format Supabase PATs (`sbp_v0_…`) are rejected by older CLI versions.** PATs issued in 2026 start with `sbp_v0_`, and the Supabase CLI (v2.101.0) rejects them with "Invalid access token format". There is no CLI workaround — set Edge Function secrets directly via the Supabase dashboard (Edge Functions → function → Secrets) instead.
- **On Windows, `supabase login` stores credentials in Windows Credential Manager, not `~/.supabase/credentials`.** The token is saved under `LegacyGeneric:target=Supabase CLI:supabase` and can conflict with the `SUPABASE_ACCESS_TOKEN` environment variable or carry restricted permissions for management API operations. Remove it with `cmdkey /delete:"Supabase CLI:supabase"` if it causes auth conflicts.
- **The functions gateway rejects non-JWT bearer tokens before your code runs.** Any bearer that is not a JWT fails at the gateway with `UNAUTHORIZED_INVALID_JWT_FORMAT`. A function that must accept a non-JWT shared secret (a system or cron caller) has to set `verify_jwt = false` in `supabase/config.toml` and do its own authorization inside. Keep `verify_jwt = true` for functions only ever called with a real user JWT (e.g. a signed-in user submitting feedback); flip it to false only when a trusted non-JWT caller is involved.
- **Schedule server-side invocation with `pg_cron` + `pg_net` + a Vault secret.** A `pg_cron` job calls a `dispatch_*()` SQL function that fires due rows at the edge function via `pg_net`, authenticated with a Vault secret (`vault.create_secret`) that must equal the function's env-var secret. Because that bearer is not a JWT, the target function needs `verify_jwt = false`. Verify delivery by checking `net._http_response` for a `200`.
- **For account deletion, verify the JWT then use the service role — and de-identify rather than hard-delete.** In the function, verify the caller JWT, then call `auth.admin.deleteUser` (service role), which cascades `public.users` via its FK. To retain non-identifying activity, first snapshot coarse stats to an archive table keyed by the user's UUID; an `event_log` with no FK to `auth.users` survives keyed by UUID, so retained activity stays linkable without PII.

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
- [ ] New-format `sbp_v0_` PATs set via the dashboard if the CLI rejects them
- [ ] On Windows, no stale `supabase login` token in Credential Manager conflicting with `SUPABASE_ACCESS_TOKEN`
- [ ] `verify_jwt = false` set only for functions with non-JWT callers (cron/system), which authorize internally
- [ ] Scheduled functions use `pg_cron` + `pg_net` with a Vault secret matching the function's env-var secret
- [ ] Account-deletion functions verify the JWT, use the service role, and de-identify retained activity by UUID

## Avoid

- Importing npm SDK packages in Deno (`npm:@google/generative-ai` and similar) — they fail silently or throw at import time
- Reading `error.message` from `FunctionsHttpError` — it is always generic; the real error is in `error.context`
- Running `supabase login` in PowerShell or CI — it hangs waiting for input; use `SUPABASE_ACCESS_TOKEN`
- Using deprecated Gemini model names (`gemini-1.5-flash`) — they return 404 on the v1beta API
- Assuming a quota error with `limit: 0` means exhausted quota — it usually means the GCP project has no free tier enabled
- Fighting the CLI to accept a new-format `sbp_v0_` PAT — older CLI versions reject it; set secrets via the Supabase dashboard instead
- Overlooking Windows Credential Manager when `supabase login` auth misbehaves on Windows — the stored token can conflict with `SUPABASE_ACCESS_TOKEN`; clear it with `cmdkey /delete`
- Leaving `verify_jwt = true` on a function called by a non-JWT system/cron caller — the gateway rejects it before your code runs; set `verify_jwt = false` and authorize inside
- Hard-deleting a user's activity on account deletion when you need to retain aggregates — snapshot coarse stats keyed by UUID and de-identify instead

## Example usage

> Edge function calling Gemini REST API returns 404. `supabase login` hangs in PowerShell before deployment. Client keeps showing wrong data after the function was fixed.

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
