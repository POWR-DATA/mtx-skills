# Resend Email Sending

Operate Resend as an application's email provider — API key and domain scoping, marketing vs transactional stream separation, and Svix-signed delivery webhooks with automatic suppression.

## What this skill does

Sets up Resend so sends actually work and keep working: keys scoped to every domain their holder sends from, all domains consolidated in one team (DKIM only allows a domain to live in one account), marketing on its own subdomain so a cold-list reputation hit cannot sink password resets, and delivery webhooks verified the way Svix requires with bounces and complaints auto-suppressed.

## When to use it

- Wiring Resend into an app for the first time
- A send fails with "This API key is not authorized to send emails from `<domain>`"
- Planning dev/prod or marketing/transactional domain structure
- Adding bounce and complaint handling to keep a list clean

## Example use cases

- Consolidate a split dev/prod Resend setup into one team after the second account cannot verify the domain
- Stand up `marketing.example.com` alongside the transactional root domain and confirm DMARC fallback covers it
- Implement Svix signature verification in a Supabase edge function deployed with `verify_jwt = false`
- Auto-suppress bounced and complained addresses and enforce the list at send time

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |

## How to use

Copy `SKILL.md` into your AI tool as an instruction or system prompt. Provide the sending domains, the stream each carries and where webhooks land, then follow the structured output. Pairs with [Supabase Auth Email](../supabase-auth-email/) for auth SMTP and [Marketing Email Campaign](../../web/marketing-email-campaign/) for campaign content and warm-up.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
