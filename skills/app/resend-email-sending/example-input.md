# Example Input

## Context

A subscription app sends confirmation and password-reset email from `example.com` through Resend, configured months ago. A marketing stream is now being added for course announcements, and the first test send from the new subdomain fails. Dev and prod were originally set up as two separate Resend accounts.

## Input provided

**Domains and streams:**
- `example.com` — transactional/auth (sign-up confirmation, password reset), already verified
- `marketing.example.com` — new, for campaign sends

**Account layout:** two Resend teams — "Northwind Dev" and "Northwind Prod". The dev team cannot verify `example.com` (the DKIM record won't take).

**Failure observed:** the campaign send returns `403 — This API key is not authorized to send emails from marketing.example.com`. The key in use was created on the transactional domain.

**Authentication:** `_dmarc.example.com` exists at `p=quarantine` with `rua`; no `_dmarc.marketing.example.com` record.

**Webhooks:** none yet. Bounces are currently invisible. A Supabase edge function is the intended endpoint, and a `suppressions` table already exists.

**Other send paths:** a one-off thank-you email after a user's first lesson (a catch-up run for earlier users is planned), and a "share this course" endpoint where the caller supplies the recipient address.

**Ask:** fix the 403, sort out the account/domain structure, confirm whether the subdomain needs its own DMARC record, wire bounce/complaint handling, and make sure the other send paths cannot double-send or be abused.
