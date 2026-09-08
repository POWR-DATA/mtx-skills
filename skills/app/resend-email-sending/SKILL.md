---
name: resend-email-sending
description: Operate Resend as an application's email provider — API key and domain scoping, marketing vs transactional stream separation, and Svix-signed delivery webhooks with automatic suppression
author: PowerData
version: 1.0.0
license: MIT
---

# Resend Email Sending

## Purpose

Set up Resend for application email sending without the account-structure and verification traps: API keys scoped so they can actually send, domains consolidated where DKIM allows them to live, marketing separated from transactional mail so one stream cannot sink the other, and delivery webhooks verified and acted on so the list stays clean.

## When to use

When wiring Resend into an app for the first time, when a send returns a 403 authorisation error, when planning dev/prod or marketing/transactional domain structure, or when adding bounce/complaint handling. For Resend as Supabase auth SMTP specifically (confirm/reset emails), use `supabase-auth-email`; for campaign content and warm-up, use `marketing-email-campaign`.

## Inputs expected

Partial inputs are fine.

- The sending domain(s) and which mail is transactional vs marketing
- The Resend team/account layout (or the intent — one team vs split dev/prod)
- Where webhooks will land (e.g. a Supabase edge function) and where the suppression list lives

---

## Guiding principles

- **An API key sends only from domains verified in ITS OWN team.** A key scoped to a specific domain 403s with "This API key is not authorized to send emails from `<other-domain>`" — create an "All domains" key (or one covering every sending domain) for services that send from more than one.
- **A sending domain can be verified in only ONE Resend account at a time.** The `resend._domainkey` DKIM value is single-valued, so consolidate all sending into one team rather than splitting dev/prod across separate accounts — the second account can never verify the same domain.
- **Send marketing from a dedicated subdomain** (e.g. `marketing.example.com`), separate from the root domain used for transactional/auth mail, so a cold-list reputation hit can't sink password-reset or confirmation deliverability — standard stream separation (Mailgun/SendGrid/Postmark all recommend it). The org-level DMARC record at `_dmarc.example.com` automatically covers subdomains via DMARC's org-domain fallback — no per-subdomain DMARC record is needed.
- **Resend delivery webhooks are Svix-signed — verify them properly.** Compute HMAC-SHA256 over `${svix-id}.${svix-timestamp}.${rawBody}` using the base64-decoded secret (strip the `whsec_` prefix), base64-compare against each `v1,<sig>` entry in the `svix-signature` header, and reject events older than ~5 minutes.
- **Deploy the webhook function with `verify_jwt = false`** — Resend sends no JWT, so a Supabase edge function behind the JWT gateway never receives the event; the Svix signature is the authentication.
- **Auto-suppress on `email.bounced` and `email.complained`.** Write the address to the suppression list the moment the event verifies, and enforce the list at send time — a clean list is the cheapest deliverability asset.

## Process

1. **Plan the account layout** — one Resend team for all sending; list every domain/subdomain and which stream (transactional vs marketing) it carries.
2. **Verify domains** — root (transactional/auth) and `marketing.<domain>`; confirm org-level DMARC covers the subdomain via fallback (no new `_dmarc` record).
3. **Create keys deliberately** — an "All domains" key for multi-domain senders; note which service holds which key and what it may send from.
4. **Stand up the webhook** — endpoint (e.g. edge function) with `verify_jwt = false`; implement Svix verification exactly (id.timestamp.rawBody, decoded secret, v1 comparison, 5-minute window).
5. **Wire suppression** — on verified `email.bounced`/`email.complained`, insert into the suppression list; enforce it in every send path.
6. **Test end to end** — a send from each domain with each key (expect the 403 on any mis-scoped key), a webhook event verified and suppressed, and a suppressed address refused at send time.

## Output format

1. **Account/domain map** — team, domains, streams, DMARC coverage note
2. **Key register** — each key's scope, holder service, and permitted domains
3. **Webhook implementation** — verification steps, `verify_jwt` setting, event handling
4. **Suppression flow** — table, insert triggers, send-time enforcement
5. **Test results** — per-domain send, 403 scoping check, verified event, suppression round-trip

## Quality checklist

- [ ] All sending consolidated in one Resend team; no domain split across accounts
- [ ] Marketing on its own subdomain; transactional/auth on the root; DMARC fallback confirmed
- [ ] Keys scoped to cover every domain their holder sends from ("All domains" where needed)
- [ ] Webhook verifies the Svix signature over `id.timestamp.rawBody` with the decoded secret and rejects stale events
- [ ] Webhook function deployed with `verify_jwt = false`
- [ ] Bounces and complaints auto-suppress; suppression enforced at send time

## Avoid

- A domain-scoped key for a service that sends from two domains — it 403s on the second
- Splitting dev/prod into separate Resend accounts sharing a domain — DKIM is single-valued; the second account cannot verify it
- Sending cold marketing from the domain that carries password resets — one complaint wave hits both
- Adding a per-subdomain DMARC record "to be safe" — the org-domain fallback already covers it
- Trusting webhook payloads without Svix verification, or verifying with the raw `whsec_` string undecoded
- Leaving the webhook behind the JWT gateway — Resend sends no JWT and every event bounces at the gate

## Example usage

> "Our app sends confirmations from `example.com` via Resend and we're adding a marketing stream. Sends from the new subdomain are failing with a 403, and we want bounce handling into our Supabase suppression table. Set up the domains, keys and webhook properly."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
