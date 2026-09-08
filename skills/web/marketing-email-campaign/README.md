# Marketing Email Campaign

Design, test and send a marketing email campaign — bulletproof HTML template, seed-test protocol, Spam Act compliance, scanner-safe unsubscribe, deliverability forensics, and warm-up batching.

## What this skill does

Takes a campaign from template to delivered: an HTML card that holds together in Outlook, Gmail and on phones; a footer that never collides with its artwork; an unsubscribe flow that mail scanners can't trigger; a seed-test pass that proves authentication and content assembly before the real send; Microsoft placement-header forensics when something lands in junk; and a sector-aware warm-up plan for a new sending domain.

## When to use it

- First campaign from a new sending domain or subdomain
- The email template overflows on phones, loses its backgrounds, or previews unstyled on the site
- A send landed in junk and you need to know whether it's reputation, a gateway, or the recipient's own filters
- Cold outreach needs to be Spam Act compliant (sender ID + functional opt-out)
- Speccing the tool a stakeholder will use to send campaigns themselves

## Example use cases

- Build a fluid-hybrid 600px template with an MSO ghost table and a footer transition strip
- Run the three-mailbox seed test and fix the double-greeting the send tool introduced
- Decode `X-Microsoft-Antispam-Mailbox-Delivery` to explain why one recipient's mail went to junk
- Produce a warm-up run sheet for a mixed private-practice / public-sector list

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |
| `reference.md` | Load-on-demand excerpts — fluid-hybrid card, footer strip, unsubscribe headers, antispam-header decode, run-sheet shape |

## How to use

Copy `SKILL.md` into your AI tool as an instruction or system prompt. Provide brand assets, copy blocks, the sending domain's authentication state and the audience shape, then work through the structured output. Pair with [Resend Email Sending](../../app/resend-email-sending/) for the provider layer and [M365 Email Authentication](../../infra/m365-email-authentication/) for DKIM/DMARC.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
