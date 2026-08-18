# Supabase Auth Email

Configure Supabase transactional auth email — custom SMTP, branded templates via the Management API, and reliable confirm/reset flows.

## What this skill does

Guides Supabase auth email end-to-end: custom SMTP (Resend) setup, applying branded templates through the Management API, sending-domain DNS/deliverability, and dependable sign-up confirmation and password-reset flows. It focuses on the silent gates and failures — template-editing lockouts on new projects, HTTP 500s that hide the real SMTP error, and confirmation links consumed by mail scanners.

## When to use it

- Setting up custom SMTP and branded auth emails for a Supabase project
- A sign-up returns HTTP 500 and no confirmation email arrives
- Template editing is silently locked on a newer project
- Confirmation links "work" but accounts never confirm (Safe Links)
- Password reset ignores your `redirectTo` and falls back to Site URL
- Users sign up but cannot log in (unconfirmed gate), or re-registering an email looks like success
- Hosting reset/confirm pages on the static site and switching them between dev and prod Supabase projects safely

## Example use cases

- Wire up Resend SMTP and push branded templates via the Management API
- Fix a signup 500 by reading `auth_logs` for the real SMTP error
- Replace the default confirm link with a client-side `verifyOtp` page
- Verify a new sending domain (DKIM/SPF/DMARC) and manage spam warm-up

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `reference.md` | SMTP/DNS/Management-API/confirm-page templates, loaded on demand |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |

## How to use

Load `SKILL.md` into your AI tool with your Supabase project ref, email provider, and sending domain. Pairs with `supabase-edge-functions` and `expo-react-native-app` / `flet-supabase-framework`.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
