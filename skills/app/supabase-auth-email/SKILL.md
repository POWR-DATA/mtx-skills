---
name: supabase-auth-email
description: Configure Supabase transactional auth email — custom SMTP, branded templates via the Management API, and reliable confirm/reset flows
author: PowerData
version: 1.4.0
license: MIT
---

# Supabase Auth Email

## Purpose

Configure Supabase transactional auth email end-to-end — custom SMTP (e.g. Resend), branded templates applied via the Management API, deliverability, and reliable sign-up confirmation and password-reset flows — avoiding the silent gates, 500s, and consumed links that block auth emails in production.

## When to use

When setting up or debugging Supabase auth emails: sign-up confirmation, password reset, or magic links. Apply when configuring custom SMTP, applying branded templates, chasing an HTTP 500 on sign-up, or when confirm links "work" but accounts never confirm. Especially relevant on newer Supabase projects, which lock template editing until custom SMTP is set.

## Inputs expected

- Supabase project ref and a Management API **personal access token** (the CLI login token cannot be reused for the API — see principles)
- Email provider account and API key (Resend assumed; any SMTP works)
- The sending domain and access to its DNS host
- App name and the confirm/reset redirect URLs

---

## Guiding principles

- **Custom auth-email template editing is gated by project *creation date*, not plan.** A restriction added ~mid-2026 locks template editing (via *both* the Management API and the dashboard) on newly created free projects until custom SMTP is configured or the org is on Pro. Projects created before it keep free dashboard editing. If template edits silently do nothing, this is why.
- **Configure custom SMTP first — it unlocks templates and improves deliverability.** For Resend: host `smtp.resend.com`, port `465`, username the literal lowercase `resend`, password a Resend API key with Sending scope. A capitalised `Resend` username fails auth with "535 Invalid username" — which surfaces only at send time as an HTTP 500 on sign-up. See *Resend SMTP* in [`reference.md`](reference.md).
- **PATCH the full SMTP group together — a single `smtp_*` field clears the rest.** On the Management API (`/v1/projects/{ref}/config/auth`), PATCHing one `smtp_*` field empties the whole SMTP group (host/user/pass go blank). Send the complete SMTP config in one PATCH. Flat fields like `mailer_*` and `uri_allow_list` patch independently and safely.
- **Apply branded templates via the API *last*, and re-apply after any dashboard change.** Saving the dashboard Emails/SMTP page overwrites Management-API-pushed templates with the dashboard's stale defaults. Apply templates via the API after SMTP is set, and re-run the apply after any dashboard email/SMTP edit.
- **Templates have no runtime app-name variable — bake it at apply time.** Templates expose only Go tokens (`{{ .ConfirmationURL }}`, `{{ .SiteURL }}`, `{{ .Email }}`). Substitute the app name via `__APP_NAME__` when applying; on a rebrand, re-run the apply. The "From" display name is a *separate* `smtp_sender_name` field in the SMTP group that the template apply does not touch — change it in the dashboard, then re-run the template apply.
- **`supabase config push` sends the local `[auth]` block to the hosted project.** A `config.toml` with `site_url = http://localhost:8081` and `enable_confirmations = false` would point every confirm and reset link at localhost and switch off email confirmation in production. Set production values in the file, push only the templates via the Management API, or drop the `[auth]` block.
- **With `mailer_autoconfirm = false`, email confirmation is a hard sign-in gate.** An unconfirmed account exists but cannot log in, so the app must surface a "confirm then sign in" state plus a resend action. A sign-up on an already-registered email is detected client-side by an empty `identities` array on the returned user (anti-enumeration otherwise makes it look like success) — surface that rather than silently "succeeding".
- **Don't refresh the session on every cross-tab storage event.** Calling `refreshSession()` on each storage event for a key ending `-auth-token` makes two open tabs on an unconfirmed account refresh each other in a loop until the per-IP token rate limit returns 429. supabase-js already shares the session across tabs; call `getUser()` first and refresh only when the server says confirmed but the JWT does not, debounced.
- **Carry sign-up hints across email confirmation yourself.** A `?plan=` hint on the sign-up link is lost after confirmation, because the confirm page sends the user to sign-in without it. Persist it at sign-up in localStorage (with a timestamp, cleared on sign-out) and in the auth user's metadata, and read it back at the onboarding plan step.
- **Host reset-password / confirm-email as static pages driven by one same-origin config script.** Read every environment value — project URL, anon key, app deep-link scheme — from a tiny `auth-config.js` (`window.<APP>_AUTH`) so a dev-to-prod Supabase project switch is a one-file change; widen those pages' CSP `connect-src` to `https://*.supabase.co` so the project swap needs no CSP edits. Only the anon/publishable key ever goes in the file.
- **Each environment's pages deep-link with that environment's own app scheme.** DEV pages carrying the store app's scheme opened the production app, which signed in against PROD ("Invalid login credentials" for a valid DEV account) and resumed a stale session for another user. Add a CI config check that pins each environment's pages to its scheme and project ref.
- **Harden the hosted auth pages.** Load supabase-js from a version-pinned CDN URL with SRI and guard for the library being absent so the page fails closed to an error state; create the client with `persistSession: false` so no session is written to the visitor's browser; implement no `redirect_to` handling (open-redirect vector) — navigation targets stay hardcoded to the portal origin and the app scheme.
- **Accept only `signup` and `email` OTP types on `/confirm-email`.** A page that takes any `type` from the query string (magiclink, recovery, invite, email_change) is a login-CSRF: an attacker sends a victim a link carrying the attacker's own `token_hash` and signs the victim into the attacker's account. Reject every other type, and show which account is now signed in.
- **Exclude the hosted auth page paths from mobile deep-link scopes** (`/reset-password`, `/confirm-email` out of AASA `components` and Android `intentFilters`); if the app captures those URLs, the browser-based reset/confirm flows break mid-flight.
- **Guard the app side of the confirmation deep link.** If it arrives while the app holds a session for a different account, sign that session out before showing sign-in, or the new user lands in someone else's account. URL-encode any email prefill parameter — a raw `+` can decode as a space, so a plus-addressed email failed to prefill even though the app's parser handled it in isolation — and test with a plus-addressed email on a real device before relying on the prefill.
- **A password-reset `redirectTo` must be in the redirect allow-list.** Add it under Auth → URL Configuration → Redirect URLs (or `uri_allow_list` via the API). Otherwise Supabase ignores it and falls back to Site URL, so the reset link never reaches your page.
- **Don't use the default `{{ .ConfirmationURL }}` server-side confirm link, and don't verify on page load.** Mail-security scanners (Outlook Safe Links, etc.) open and *spend* one-time links before the user clicks — the default link, and equally a hosted page that verifies as soon as it opens. Link to a hosted page that does nothing on load and completes confirmation client-side via `verifyOtp({ token_hash, type: 'signup' })` only when the user taps a button, then deep-links back into the app; build the password-reset page the same way, and carry the 6-digit code in the email as a fallback. See *Client-side confirm page* in `reference.md`.
- **Don't assume a refused confirm link has expired.** Because scanners and repeat clicks spend links, when `verifyOtp` refuses (otp_expired, not found, expired or invalid) check first: if there is a live session with `email_confirmed_at`, or this device already saw the confirm succeed, show "Already confirmed? Sign in". Otherwise show a single message that the link was already used or has expired, with both **Sign in** and **Send a new link** buttons.
- **Build confirm/reset UI from what the live email actually contains.** Repo templates can drift from the live ones: a repo recovery template still had `{{ .Token }}` while the live recovery email had only a button, so the reset UI asked for a 6-digit code the user never received. Word the UI to the live email ("check your email and tap Reset password"); pushing the repo templates to bring the code back is a production auth config change, not part of a UI fix.
- **A failed email send returns HTTP 500 on `/auth/v1/signup` but still creates the user row.** The real SMTP error (e.g. "535 Invalid username") is in the project's `auth_logs`, queryable via the Management API analytics logs endpoint — check there, not the HTTP response.
- **Verify the sending domain in DNS, and expect a warm-up period.** Resend needs DKIM on `resend._domainkey`, MX + SPF on a `send` subdomain, and DMARC on `_dmarc`, added at the domain's actual DNS host (which may differ from the registrar or web host). These sit on different hostnames than existing Microsoft 365 mail records, so they don't conflict. A brand-new sending domain has no reputation, so early emails often land in spam even when SPF/DKIM pass — expected, and it improves as the domain sends legitimate mail.
- **The Supabase CLI login token is not a Management API token.** It lives in Windows Credential Manager (LegacyGeneric target "Supabase CLI:supabase") and cannot be reused for the Management API, which needs a personal access token (optionally at `%USERPROFILE%\.supabase\access-token`); ask the project owner for a token rather than trying to extract vault credentials. `supabase projects list` prints "Cannot find project ref. Have you run supabase link?" to stderr yet still lists every project, and truncating its output (`Select-Object -First N`) hid the production row and produced a wrong "different org" conclusion — filter noise instead of truncating.
- **From PowerShell 5.1, send the Management API body as UTF-8 bytes.** The default string encoding is Latin-1, which mangles UTF-8 and returns 400 errors. Encode the JSON with `[System.Text.Encoding]::UTF8.GetBytes($json)` and read template files with `[System.IO.File]::ReadAllText($path,[Text.Encoding]::UTF8)`. See *reference.md*.
- **Create demo and video accounts on a subdomain you control.** Never a made-up Gmail address (a real person receives the confirmation and any later reset) and never `example.com`, which fails at sign-up with "Error sending confirmation email" once custom SMTP is configured. Use `demo.<your-domain>`, then confirm the account server-side by setting `auth.users.email_confirmed_at` and `email_verified: true` in the email identity's `identity_data` — scoped to an allow-listed address that is still unconfirmed and was created in the last 24 hours, so the email-confirmed audit trigger still fires.
- **Leaked-password protection rejects famous quotes.** With it enabled, plain-form quotes are in the breach corpus and fail at sign-up ("ThereIsNoSpoon" had 193 hits, "FollowTheWhiteRabbit" 124). Check any demo password against the Have I Been Pwned range API first — k-anonymity means only the first five SHA-1 characters leave the machine — and expect hyphenated variants with a number ("There-Is-No-Spoon-1999") to return zero hits.

## Process

1. **Set up custom SMTP** — create the provider account and API key, verify the sending domain in DNS, then PATCH the full SMTP group to the Management API. See `reference.md`.
2. **Confirm template editing is unlocked** — on a newer project, editing stays locked until SMTP is set.
3. **Apply branded templates via the API**, substituting `__APP_NAME__`, *after* SMTP is configured. Set `smtp_sender_name` in the dashboard, then re-apply. Never `supabase config push` an `[auth]` block holding local values.
4. **Add redirect/confirm URLs to the allow-list** (`uri_allow_list`).
5. **Switch confirmation to a client-side `verifyOtp` page** so Safe Links cannot consume the link — nothing on load, verify on a button tap, `signup`/`email` types only, already-confirmed handling for refused links, hosted statically, config (including this environment's app scheme) from `auth-config.js`, pinned+SRI supabase-js, `persistSession: false`, no `redirect_to`, and excluded from app deep-link scopes. Build the reset page the same way, worded to the live recovery email.
6. **Handle the unconfirmed state in the app** — a "confirm then sign in" screen with resend; treat an empty `identities` array on sign-up as "already registered"; refresh only when `getUser()` says confirmed but the JWT does not; sign out a different account's session when a confirm deep link arrives; restore sign-up hints (e.g. `?plan=`) at onboarding.
7. **Test sign-up and reset**, including a link opened twice and a plus-addressed email on a real device; on a 500, read `auth_logs` for the real SMTP error.
8. **Provision demo accounts deliberately** — address on a controlled subdomain, password pre-checked against HIBP, confirmation applied server-side under the allow-list/recency guard.

## Output format

1. **SMTP configuration** — provider, the full PATCHed SMTP group, sender name
2. **DNS records** — DKIM/SPF/MX/DMARC entries added, verification status
3. **Templates applied** — which templates, app name baked in, applied after SMTP
4. **Flow config** — allow-listed redirect URLs, client-side confirm/reset pages in place (tap to verify, type allow-list, refused-link handling, per-environment scheme), unconfirmed/already-registered states handled in the app
5. **Verification** — sign-up and reset tested; `auth_logs` clean

## Quality checklist

- [ ] Custom SMTP set via a single full-group PATCH (no partial `smtp_*` PATCH)
- [ ] Resend username is lowercase `resend`; password is a Sending-scope API key
- [ ] Branded templates applied via the API *after* SMTP; re-applied after any dashboard save
- [ ] `smtp_sender_name` set (separately) and current after any rename
- [ ] Confirm flow uses a client-side `verifyOtp` page, not the default `{{ .ConfirmationURL }}`; confirm and reset pages do nothing on load and verify on a button tap; the email carries the 6-digit code as a fallback
- [ ] `/confirm-email` accepts only `signup` and `email` OTP types and shows which account is now signed in
- [ ] Refused links show "Already confirmed? Sign in" when confirmed, otherwise one "already used or expired" message with Sign in and Send a new link
- [ ] Reset UI wording matches the live recovery email, not the repo template
- [ ] Hosted auth pages: one `auth-config.js` (anon key only), CSP `connect-src https://*.supabase.co`, pinned CDN + SRI with fail-closed guard, `persistSession: false`, no `redirect_to`, paths excluded from AASA/intent-filter scopes
- [ ] Each environment's pages carry its own app scheme and project ref, pinned by a CI config check
- [ ] `config.toml` `[auth]` block holds production values, or is absent, before any `supabase config push`
- [ ] No `refreshSession()` on raw storage events — `getUser()` first, debounced
- [ ] Confirm deep link signs out a different account's session; email prefill is URL-encoded and tested with a plus-addressed email
- [ ] Sign-up hints persisted in localStorage (timestamped, cleared on sign-out) and user metadata, read back at onboarding
- [ ] Management API calls use a personal access token, not the CLI login token; `supabase projects list` output filtered, not truncated
- [ ] Reset/confirm redirect URLs added to `uri_allow_list`
- [ ] App shows "confirm then sign in" + resend for unconfirmed accounts; empty `identities` on sign-up surfaced as already-registered
- [ ] Sending domain DKIM/SPF/MX/DMARC verified; spam warm-up expected
- [ ] Sign-up/reset tested; `auth_logs` checked on any HTTP 500
- [ ] Demo/video accounts use `demo.<your-domain>` addresses, never invented Gmail or `example.com`
- [ ] Demo passwords checked against the HIBP range API before being filmed or handed out

## Avoid

- Editing templates on a newer project before setting custom SMTP — editing is silently locked
- PATCHing a single `smtp_*` field — it clears the whole SMTP group; send the full config together
- Applying templates before SMTP, or forgetting to re-apply after a dashboard save — the dashboard reverts them
- Assuming `smtp_sender_name` updates with the template apply — it is separate and stays stale after a rename
- Using the default `{{ .ConfirmationURL }}`, or verifying on page load — scanners open and spend the link; wait for a button tap
- Taking the OTP `type` from the query string on `/confirm-email` — it signs a victim into the attacker's account
- Showing "link expired" for every refused link — a scanner may have spent it on an account that is already confirmed
- Wording reset UI from the repo template, or pushing templates as part of a UI fix — the live email is the source of truth
- Running `supabase config push` with a localhost `site_url` or `enable_confirmations = false` in `[auth]`
- `refreshSession()` on every `-auth-token` storage event — two tabs loop until the token rate limit returns 429
- Trusting the HTTP response on send failure — the 500 hides the real error; read `auth_logs`
- Hardcoding the Supabase URL/key into each hosted auth page, or honouring a `redirect_to` parameter on them — one config script, fixed navigation targets
- DEV pages carrying the store app's scheme — they open the production app against PROD
- Showing sign-in from a confirm deep link while another account's session is live, or sending an email prefill with a raw `+`
- Letting the app's App Links / Universal Links capture `/reset-password` or `/confirm-email` — the browser flow breaks mid-flight
- Reusing the CLI login token for the Management API, or `Select-Object -First N` on `supabase projects list` — use a PAT and filter, don't truncate
- Sending the Management API body as a default PowerShell string — encode as UTF-8 bytes or get 400s
- Treating early spam-foldering on a new domain as a misconfiguration — it is reputation warm-up
- Treating a sign-up response with an empty `identities` array as a fresh account — the email is already registered; anti-enumeration hides the error
- Signing demo accounts up on `example.com` or an invented Gmail address — one fails at send, the other mails a real stranger
- Handing out a memorable quote as a demo password without a HIBP check — leaked-password protection rejects it at sign-up

## Example usage

> "New Supabase project — sign-up returns a 500 and no confirmation email arrives, and the dashboard won't let me edit the email templates. Set up Resend SMTP, apply branded templates via the Management API, fix the confirm flow so Outlook doesn't eat the link, and get password reset redirecting to my page."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
