---
name: supabase-auth-email
description: Configure Supabase transactional auth email — custom SMTP, branded templates via the Management API, and reliable confirm/reset flows
author: PowerData
version: 1.0.0
license: MIT
---

# Supabase Auth Email

## Purpose

Configure Supabase transactional auth email end-to-end — custom SMTP (e.g. Resend), branded templates applied via the Management API, deliverability, and reliable sign-up confirmation and password-reset flows — avoiding the silent gates, 500s, and consumed links that block auth emails in production.

## When to use

When setting up or debugging Supabase auth emails: sign-up confirmation, password reset, or magic links. Apply when configuring custom SMTP, applying branded templates, chasing an HTTP 500 on sign-up, or when confirm links "work" but accounts never confirm. Especially relevant on newer Supabase projects, which lock template editing until custom SMTP is set.

## Inputs expected

- Supabase project ref and a Management API access token
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
- **A password-reset `redirectTo` must be in the redirect allow-list.** Add it under Auth → URL Configuration → Redirect URLs (or `uri_allow_list` via the API). Otherwise Supabase ignores it and falls back to Site URL, so the reset link never reaches your page.
- **Don't use the default `{{ .ConfirmationURL }}` server-side confirm link.** Mail-security scanners (Outlook Safe Links, etc.) pre-fetch and *consume* it, so accounts never confirm. Instead link to a hosted page that completes confirmation client-side via `verifyOtp({ token_hash, type: 'signup' })`, then deep-links back into the app. See *Client-side confirm page* in `reference.md`.
- **A failed email send returns HTTP 500 on `/auth/v1/signup` but still creates the user row.** The real SMTP error (e.g. "535 Invalid username") is in the project's `auth_logs`, queryable via the Management API analytics logs endpoint — check there, not the HTTP response.
- **Verify the sending domain in DNS, and expect a warm-up period.** Resend needs DKIM on `resend._domainkey`, MX + SPF on a `send` subdomain, and DMARC on `_dmarc`, added at the domain's actual DNS host (which may differ from the registrar or web host). These sit on different hostnames than existing Microsoft 365 mail records, so they don't conflict. A brand-new sending domain has no reputation, so early emails often land in spam even when SPF/DKIM pass — expected, and it improves as the domain sends legitimate mail.
- **From PowerShell 5.1, send the Management API body as UTF-8 bytes.** The default string encoding is Latin-1, which mangles UTF-8 and returns 400 errors. Encode the JSON with `[System.Text.Encoding]::UTF8.GetBytes($json)` and read template files with `[System.IO.File]::ReadAllText($path,[Text.Encoding]::UTF8)`. See *reference.md*.

## Process

1. **Set up custom SMTP** — create the provider account and API key, verify the sending domain in DNS, then PATCH the full SMTP group to the Management API. See `reference.md`.
2. **Confirm template editing is unlocked** — on a newer project, editing stays locked until SMTP is set.
3. **Apply branded templates via the API**, substituting `__APP_NAME__`, *after* SMTP is configured. Set `smtp_sender_name` in the dashboard, then re-apply.
4. **Add redirect/confirm URLs to the allow-list** (`uri_allow_list`).
5. **Switch confirmation to a client-side `verifyOtp` page** so Safe Links cannot consume the link.
6. **Test sign-up and reset**; on a 500, read `auth_logs` for the real SMTP error.

## Output format

1. **SMTP configuration** — provider, the full PATCHed SMTP group, sender name
2. **DNS records** — DKIM/SPF/MX/DMARC entries added, verification status
3. **Templates applied** — which templates, app name baked in, applied after SMTP
4. **Flow config** — allow-listed redirect URLs, client-side confirm page in place
5. **Verification** — sign-up and reset tested; `auth_logs` clean

## Quality checklist

- [ ] Custom SMTP set via a single full-group PATCH (no partial `smtp_*` PATCH)
- [ ] Resend username is lowercase `resend`; password is a Sending-scope API key
- [ ] Branded templates applied via the API *after* SMTP; re-applied after any dashboard save
- [ ] `smtp_sender_name` set (separately) and current after any rename
- [ ] Confirm flow uses a client-side `verifyOtp` page, not the default `{{ .ConfirmationURL }}`
- [ ] Reset/confirm redirect URLs added to `uri_allow_list`
- [ ] Sending domain DKIM/SPF/MX/DMARC verified; spam warm-up expected
- [ ] Sign-up/reset tested; `auth_logs` checked on any HTTP 500

## Avoid

- Editing templates on a newer project before setting custom SMTP — editing is silently locked
- PATCHing a single `smtp_*` field — it clears the whole SMTP group; send the full config together
- Applying templates before SMTP, or forgetting to re-apply after a dashboard save — the dashboard reverts them
- Assuming `smtp_sender_name` updates with the template apply — it is separate and stays stale after a rename
- Using the default `{{ .ConfirmationURL }}` — Safe Links pre-fetch and consume it; use a client-side `verifyOtp` page
- Trusting the HTTP response on send failure — the 500 hides the real error; read `auth_logs`
- Sending the Management API body as a default PowerShell string — encode as UTF-8 bytes or get 400s
- Treating early spam-foldering on a new domain as a misconfiguration — it is reputation warm-up

## Example usage

> "New Supabase project — sign-up returns a 500 and no confirmation email arrives, and the dashboard won't let me edit the email templates. Set up Resend SMTP, apply branded templates via the Management API, fix the confirm flow so Outlook doesn't eat the link, and get password reset redirecting to my page."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
