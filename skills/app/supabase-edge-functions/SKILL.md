---
name: supabase-edge-functions
description: Write, deploy, secure, and debug Supabase Edge Functions — Deno import constraints, CLI auth, gateway JWT, CORS and shared secrets, monitored pg_cron jobs, LLM provider integration, and cache invalidation
author: PowerData
version: 1.6.0
license: MIT
---

# Supabase Edge Functions

## Purpose

Guide the authoring, deployment, and debugging of Supabase Edge Functions (Deno runtime), covering Deno-specific module constraints, non-interactive terminal auth, LLM provider REST API integration, error extraction from the client, gateway JWT/CORS/shared-secret hardening, monitored scheduled jobs, and cache invalidation when bad data is persisted by a function.

## When to use

When writing a new Supabase Edge Function or debugging a deployment, error, or data issue that originates from one. Apply before first deployment to avoid the class of Deno module failures and auth hangs that are non-obvious coming from a Node.js background. Also apply when integrating LLM providers (Gemini, OpenAI, Anthropic) via REST API, or exposing a function to a browser, a webhook, or a `pg_cron` caller.

## Inputs expected

- Edge function code or error message
- Deployment environment (local dev, CI, PowerShell)
- LLM provider in use (if applicable)
- Client-side caching strategy (if applicable)

---

## Guiding principles

- **Don't use npm SDK packages in Deno — use the provider's REST API directly.** npm-style imports (`npm:@google/generative-ai@0.21.0`) fail to resolve in Deno edge functions. Call the LLM provider's REST API via `fetch` — this is more stable, has no dependency on Deno's npm compatibility layer, and works across all providers with a single pattern.
- **`FunctionsHttpError` hides the real error — extract it from `error.context`.** On a non-2xx response `supabase.functions.invoke` returns a `FunctionsHttpError` with the fixed message "Edge Function returned a non-2xx status code" and `data` null, so string-matching the message for "404" never fires and the server's error body is lost. Check `error.context.status` and read the body with `await error.context.json()` (`.clone()` first if it may be read twice). Never swallow the error before telling the user an action (e.g. account deletion) succeeded.
- **Allow `x-client-info` in CORS.** supabase-js always sends an `X-Client-Info` header, so a function whose `Access-Control-Allow-Headers` lists only `authorization, apikey, content-type` fails the browser preflight on web and the call surfaces as a `FunctionsFetchError`. Use `authorization, x-client-info, apikey, content-type`, and test from a real browser origin, not only curl.
- **Build links and form actions from the public function URL.** An HTML form served by an edge function posted to the internal http function URL without `/functions/v1`, so submissions failed. Use `https://<project-ref>.supabase.co/functions/v1/<fn>`.
- **`supabase login` hangs in non-interactive terminals — use `SUPABASE_ACCESS_TOKEN` instead.** In PowerShell and CI environments, `supabase login` blocks waiting for user input. Set `SUPABASE_ACCESS_TOKEN` as an environment variable before running `supabase functions deploy` to authenticate without interaction.
- **Check LLM model names and quota settings when calls return 404 or `limit: 0`.** `gemini-1.5-flash` is deprecated on the v1beta REST API and returns 404. Use `gemini-2.0-flash` or `gemini-flash-lite-latest`. A quota error with `limit: 0` indicates the Google Cloud project has no free tier enabled — this is usually an org policy restriction, not exhausted quota.
- **Client-side caches will serve bad data even after the edge function is fixed — delete the bad row.** When an edge function writes incorrect data to a database cache table, the client will keep reading the bad row because stale checks typically only trigger when no row exists for the expected key. Delete the affected row directly in the Supabase SQL Editor to force a fresh fetch.
- **New-format Supabase PATs (`sbp_v0_…`) are rejected by older CLI versions.** PATs issued in 2026 start with `sbp_v0_`, and the Supabase CLI (v2.101.0) rejects them with "Invalid access token format". There is no CLI workaround — set Edge Function secrets directly via the Supabase dashboard (Edge Functions → function → Secrets) instead.
- **On Windows, `supabase login` stores credentials in Windows Credential Manager, not `~/.supabase/credentials`.** The token is saved under `LegacyGeneric:target=Supabase CLI:supabase` and can conflict with the `SUPABASE_ACCESS_TOKEN` environment variable or carry restricted permissions for management API operations. Remove it with `cmdkey /delete:"Supabase CLI:supabase"` if it causes auth conflicts.
- **If `supabase db push` or `supabase functions deploy` hangs connecting to the project, add `--dns-resolver https`.** Observed on Linux: both commands hung against the dev project and completed once the flag was added. The root cause is not confirmed and it was not Windows-specific, so treat it as a first thing to try rather than a known fault.
- **Baseline migration history before the first `db push` on a project whose schema was applied directly.** With no migration history, `db push` tries to re-apply migrations that already exist in the database. Mark each already-applied migration with `supabase migration repair --status applied <version>` first, then push only the genuinely new ones.
- **Updating a secret does not refresh already-warm function instances.** `supabase secrets set NAME=... --project-ref <ref>` leaves warm instances reading the stale value — redeploy the function (`supabase functions deploy <fn>`) so new instances boot with the new secret.
- **Listing secrets returns a digest, not the value.** Function secrets listed via the CLI or Management API come back as a SHA-256 digest, so a script that "reads back" a secret to reuse it stores the digest. Take the value from Vault or a masked prompt instead, and refuse anything that looks like a digest.
- **The functions gateway rejects non-JWT bearer tokens before your code runs.** Any bearer that is not a JWT fails at the gateway with `UNAUTHORIZED_INVALID_JWT_FORMAT`. A function that must accept a non-JWT shared secret (a system or cron caller) has to set `verify_jwt = false` in `supabase/config.toml` and do its own authorization inside. Keep `verify_jwt = true` for functions only ever called with a real user JWT (e.g. a signed-in user submitting feedback); flip it to false only when a trusted non-JWT caller is involved.
- **Self-authenticating functions must fail closed.** A guard written as `if (secret && header !== secret)` lets every caller through when the secret env var is unset — and the public anon key already passes the default `verify_jwt` check, so the gateway is no backstop. Refuse every request when the secret is unset, compare it in constant time, and don't echo upstream provider errors back to the caller.
- **Never pass `--no-verify-jwt` to `supabase functions deploy`.** It turns OFF the gateway JWT check (a silent security regression), and it applies to every function named in a multi-function deploy command, so one batch disables the check for all of them. Keep `verify_jwt` set per function in `config.toml` (only the intentionally-public functions listed as `false`), deploy WITHOUT the flag, and deploy JWT-protected and self-authenticating functions in separate commands. Verify the live state empirically: an unauthenticated POST returns the gateway body `{"code":"UNAUTHORIZED_NO_AUTH_HEADER"}` (401) when `verify_jwt=true`, versus the function's own JSON when it is off.
- **Key IP rate limits on `cf-connecting-ip`, not `X-Forwarded-For`.** Inside an Edge Function the rightmost `X-Forwarded-For` address is a shared gateway (AWS) IP, so an IP-keyed guess limit let anyone lock out every user routed through it. The real client address arrives in `cf-connecting-ip` (a throwaway header-echo function shows what actually arrives); key IP limits on that, or on the user or resource instead.
- **Schedule server-side invocation with `pg_cron` + `pg_net` + a Vault secret.** A `pg_cron` job calls a `dispatch_*()` SQL function that fires due rows at the edge function via `pg_net`, authenticated with a Vault secret (`vault.create_secret`) that must equal the function's env-var secret. Because that bearer is not a JWT, the target function needs `verify_jwt = false`. Verify delivery by checking `net._http_response` for a `200`.
- **Give every scheduled job a heartbeat and a staleness alert.** Jobs fired by `pg_cron` through `pg_net` fail silently, so have each run write a heartbeat and a separate daily job alert when it is stale. The checker must tell "could not read the record" (retry, then report the error) apart from "never ran" and "stale" — a failed read reported as "last ran never" caused a false production alert. Record every admin alert in the audit table (subject and outcome, never body or addresses).
- **For account deletion, verify the JWT then use the service role — and de-identify rather than hard-delete.** In the function, verify the caller JWT, then call `auth.admin.deleteUser` (service role), which cascades `public.users` via its FK. To retain non-identifying activity, first snapshot coarse stats to an archive table keyed by the user's UUID; an `event_log` with no FK to `auth.users` survives keyed by UUID, so retained activity stays linkable without PII.

## Process

1. **Write the edge function using `fetch` for external API calls.** Do not import npm SDK packages — use the provider's REST API endpoint directly. Structure the function to return a consistent JSON response with explicit status codes. Allow `x-client-info` in CORS, build any links or form actions from the public `/functions/v1/<fn>` URL, make shared-secret guards fail closed, and key rate limits on `cf-connecting-ip` or the user/resource.
2. **Authenticate for deployment without interactive login.** Set `SUPABASE_ACCESS_TOKEN` in the environment before deploying: `$env:SUPABASE_ACCESS_TOKEN = "sbp_..."` (PowerShell) or `export SUPABASE_ACCESS_TOKEN="sbp_..."` (bash). Then run `supabase functions deploy <function-name>` (add `--dns-resolver https` if it hangs connecting), deploying JWT-protected and self-authenticating functions in separate commands. Before the first `supabase db push` to a project whose schema was applied by hand, run `supabase migration repair --status applied <version>` for each migration already in the database.
3. **Test the deployed function and extract errors properly.** Call via `supabase.functions.invoke`, including from a real browser origin. On error, check `error.context.status` and read the body from `error.context` — not `error.message` — to see the actual response from the function. For scheduled functions, confirm the heartbeat is written and the staleness check fires.
4. **Verify LLM model availability and quota.** If calls return 404, check the model name against the provider's current API. If quota shows `limit: 0`, check GCP → APIs & Services → Quotas for org-level policy restrictions, not just per-project limits.
5. **Invalidate bad cached data by deleting the affected rows.** If incorrect data was written to a cache table, delete the row via the Supabase SQL Editor. Do not rely on the client's stale check — it only triggers on absence, not on bad data.

## Output format

1. **Deployment checklist** — auth method confirmed, `verify_jwt` per function, function deployed, test call successful (including from a browser origin)
2. **Error diagnosis** — status and root cause read from `error.context`, not `error.message`
3. **LLM integration notes** — model name confirmed, quota verified, REST API endpoint used
4. **Cache state** — any bad rows deleted, fresh fetch confirmed

## Quality checklist

- [ ] No npm SDK packages imported — all external calls use `fetch` against REST APIs
- [ ] Deployment uses `SUPABASE_ACCESS_TOKEN`, not interactive `supabase login`
- [ ] Error handling checks `error.context.status` and reads the body from `error.context` on `FunctionsHttpError`; no success message after a swallowed error
- [ ] CORS `Access-Control-Allow-Headers` includes `x-client-info`; tested from a browser origin
- [ ] Links and form actions use the public `https://<project-ref>.supabase.co/functions/v1/<fn>` URL
- [ ] LLM model name verified against current provider API (not deprecated `gemini-1.5-flash`)
- [ ] Any bad cached rows deleted directly before verifying the fix
- [ ] New-format `sbp_v0_` PATs set via the dashboard if the CLI rejects them
- [ ] Hanging `db push`/`functions deploy` retried with `--dns-resolver https` before deeper debugging
- [ ] Directly applied migrations marked with `supabase migration repair --status applied` before the first `db push`
- [ ] On Windows, no stale `supabase login` token in Credential Manager conflicting with `SUPABASE_ACCESS_TOKEN`
- [ ] `verify_jwt = false` set only for functions with non-JWT callers (cron/system), which authorize internally
- [ ] Shared-secret guards refuse every request when the secret is unset, compare in constant time, and don't echo upstream errors
- [ ] Deployed without `--no-verify-jwt`; JWT-protected and self-authenticating functions deployed in separate commands; unauthenticated POST to a protected function returns `UNAUTHORIZED_NO_AUTH_HEADER` (401)
- [ ] Secrets reused from Vault or a masked prompt, never read back from a secrets listing
- [ ] IP rate limits keyed on `cf-connecting-ip` (or the user/resource), not `X-Forwarded-For`
- [ ] Scheduled functions use `pg_cron` + `pg_net` with a Vault secret matching the function's env-var secret
- [ ] Each scheduled job writes a heartbeat; the daily staleness check separates read failure, never ran, and stale; admin alerts are audited
- [ ] Account-deletion functions verify the JWT, use the service role, and de-identify retained activity by UUID

## Avoid

- Importing npm SDK packages in Deno (`npm:@google/generative-ai` and similar) — they fail silently or throw at import time
- Reading `error.message` from `FunctionsHttpError`, or string-matching it for a status — it is always generic; the status and body are in `error.context`
- Swallowing an invoke error and then telling the user the action succeeded
- A CORS allow-list without `x-client-info` — the browser preflight fails and the call surfaces as `FunctionsFetchError`
- Posting forms to the internal function URL without `/functions/v1`
- `if (secret && header !== secret)` — an unset secret lets every caller in, and the anon key already passes `verify_jwt`
- Reading a secret back from a secrets listing — it is a SHA-256 digest, not the value
- Keying IP limits on the rightmost `X-Forwarded-For` address — it is a shared gateway IP, so one caller can lock out everyone
- Reporting a failed heartbeat read as "never ran" — it raises false alerts
- Running `supabase login` in PowerShell or CI — it hangs waiting for input; use `SUPABASE_ACCESS_TOKEN`
- Using deprecated Gemini model names (`gemini-1.5-flash`) — they return 404 on the v1beta API
- Assuming a quota error with `limit: 0` means exhausted quota — it usually means the GCP project has no free tier enabled
- Fighting the CLI to accept a new-format `sbp_v0_` PAT — older CLI versions reject it; set secrets via the Supabase dashboard instead
- Running `supabase db push` against a schema applied outside the CLI without repairing the migration history first; it tries to re-apply existing migrations
- Overlooking Windows Credential Manager when `supabase login` auth misbehaves on Windows — the stored token can conflict with `SUPABASE_ACCESS_TOKEN`; clear it with `cmdkey /delete`
- Leaving `verify_jwt = true` on a function called by a non-JWT system/cron caller — the gateway rejects it before your code runs; set `verify_jwt = false` and authorize inside
- Deploying with `--no-verify-jwt` — it silently disables the gateway check for every function in the command; let `config.toml` decide and prove the live 401
- Hard-deleting a user's activity on account deletion when you need to retain aggregates — snapshot coarse stats keyed by UUID and de-identify instead

## Example usage

> Edge function calling Gemini REST API returns 404. `supabase login` hangs in PowerShell before deployment. Client keeps showing wrong data after the function was fixed.

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
