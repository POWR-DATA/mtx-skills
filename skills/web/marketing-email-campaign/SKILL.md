---
name: marketing-email-campaign
description: Design, test and send a marketing email campaign — bulletproof HTML template, seed-test protocol, Spam Act compliance, scanner-safe unsubscribe, deliverability forensics, and warm-up batching
author: PowerData
version: 1.0.0
license: MIT
---

# Marketing Email Campaign

## Purpose

Run a marketing email campaign end to end: an HTML template that renders correctly in Outlook, Gmail and mobile clients, a compliance layer that satisfies Australia's Spam Act, a seed-test protocol that validates the exact construction before the real send, header-level deliverability diagnosis, and a warm-up plan that builds sender reputation without burning it.

## When to use

Before the first campaign from a new sending domain, when building or fixing an email template (layout breaking on phones, backgrounds misbehaving, unstyled previews), when a send lands in junk and you need to know why, or when speccing the tool stakeholders will use to send. Pair with `resend-email-sending` for the provider layer, `m365-email-authentication` for DKIM/DMARC, and `supabase-marketing-backend` for the forms campaigns point at.

## Inputs expected

Partial inputs are fine — state assumptions.

- Brand assets (logo, palette, display font) and the campaign's copy blocks (subject, preheader, body, CTAs)
- The sending domain/subdomain, provider, and authentication state (SPF/DKIM/DMARC)
- The audience: list source, sectors (consumer vs corporate/public-sector domains), and expected volume
- The published privacy stance (tracking or no tracking) and who operates the send tool

---

## Guiding principles

- **Size the card with the fluid-hybrid pattern, never percentage max-width.** A table sized `width:600px; max-width:100%` resolves back to 600px on phones inside nested tables (percentage max-width is circular in auto table layout) and overflows the viewport — confirmed on both iOS and Android. Use `width="100%" style="width:100%; max-width:600px"` on the card, wrapped in an MSO conditional ghost table so desktop Outlook stays pinned at 600. See *Fluid-hybrid card* in [`reference.md`](reference.md).
- **Never overlay text on a `background-size:cover` cell.** The artwork re-proportions whenever content height changes (mobile text wrap grows the cell and the colour boundary slides into the text), so it will collide at some width. Structure it as a normal full-width `<img>` transition strip whose bottom edge ends in one flat solid colour, followed by a separate `bgcolor` cell of that exact colour holding the text: seamless join, legible at every width, Outlook-safe.
- **Draw flat-vector brand splash art programmatically; bake the wordmark, keep sublines live.** Exact hex values and compositing the real logo beat AI generation for flat art (exact palette, crisp small-size rendering, reproducible from a committed script); AI art wins only for organic complexity on large canvases. Bake the wordmark into the header image using the brand's display font (a Google Fonts link helps Apple Mail only; everyone else gets the fallback stack), and keep audience-specific sublines as live text so campaigns can vary them.
- **A preview page on the product site needs its own CSP.** A site CSP of `style-src 'self'` blocks ALL inline style attributes — the entirety of an email template's styling — so the preview renders unstyled (serif, blue links, visible preheader) while real sends are unaffected (email clients never see the site's headers). Give the preview route a CSP allowing `'unsafe-inline'` styles, mark it noindex, and keep any analytics beacon off it.
- **The Spam Act attaches to every commercial email sent, not to having "subscribers".** Cold outreach still requires sender identification (legal entity line) and a functional opt-out — a reply-"unsubscribe" line is the minimal compliant form, and the regulator's largest fines have been for unsubscribe failures specifically. If the owner directs removing it for a one-off send, record the direction and date in the template's comments, and keep unsubscribe mandatory in any repeatable sending tool (unique signed link, suppression list enforced at send time, `List-Unsubscribe` header).
- **The visible unsubscribe link goes to a page that only confirms on GET and acts on POST.** Mail-security scanners (Outlook Safe Links) prefetch every link with a GET and would silently unsubscribe recipients — render only a confirmation button, fire the unsubscribe POST on explicit click. Make the endpoint idempotent (200 for unknown or already-removed tokens, no info leak), treat the token as opaque and never log it, and serve the page with `Referrer-Policy: no-referrer`. The RFC 8058 `List-Unsubscribe` header keeps pointing at the endpoint directly; one-click needs no page.
- **Seed-test the exact construction before any campaign.** Send the real email through the real tool to a Gmail, an Outlook.com and a corporate-tenant address, then read the raw source for SPF/DKIM/DMARC verdicts, `multipart/alternative`, and the `List-Unsubscribe` headers. In the same pass verify content assembly: subject appears once, preheader is independent of the subject, and there is exactly one greeting — tools that prepend their own greeting mean the body copy must not include one (and check what renders when the recipient name is blank). Run a second seed after any fix so the send validates the exact construction the campaign will use.
- **Read Microsoft's placement header before blaming content.** `X-Microsoft-Antispam-Mailbox-Delivery` states WHY placement happened: `dest:I` vs `dest:J` plus an OFR reason, where `TrustedSenderList` means the recipient's own Not-Junk click whitelisted that one mailbox (global SCL can still be 5) and `SpamFilterAuthJ` means authenticated-but-junked on reputation. Third-party filtering gateways (relay MX in front of a tenant) break SPF by forwarding, but an aligned DKIM signature keeps DMARC passing, so mail lands junk-but-deliverable instead of rejected; gateways also stamp bulk classification and shared-IP ratings you cannot fix. For high-value targets, a personal one-to-one email from the normal org mailbox carries none of the bulk fingerprints and bypasses that entire classification path.
- **Warm up in small sector-aware batches with a human on the button.** Batches of 20–30 per day, warmest recipients first; audience sector maps directly to gateway risk (private practices sit on consumer domains that accept early sends; public-sector bodies share one strictly-filtered domain — cap around 5 recipients per email domain per batch and let the batch fill from the next group). Watch three signals between batches: replies (answer them, they build reputation), bounces (a cluster means pause), and complaints (report-spam via feedback loop — the single most damaging signal, which frictionless unsubscribe exists to divert). Prefer a manual send-next-batch button plus a run sheet over automated scheduling until reputation is established and auto-pause guardrails exist.
- **A stakeholder-operable send tool needs exactly this shape:** a vendored template whose header/footer are not editable in the UI; compose limited to subject, preheader, constrained rich-text body and 0–2 CTA pill buttons (label plus URL restricted to https on owned domains); recipient groups from CSV with validation, case-insensitive dedupe and visible counts; `[TEST]`-prefixed test sends to configurable addresses before an explicit confirmed real send; a per-recipient delivery audit storing the exact rendered email; and open/click tracking disabled when the published privacy stance is no tracking.

## Process

1. **Build the template** — fluid-hybrid card in an MSO ghost table, `<img>` transition strip + solid-colour text cell for the footer, programmatic header art with baked wordmark, live sublines.
2. **Host the preview** — stable URL on the product site with its own `'unsafe-inline'`-styles CSP, noindex, no beacon.
3. **Compliance pass** — sender identification line, functional opt-out (page + RFC 8058 header for a tool; reply-line minimum for one-offs), any owner direction recorded in template comments.
4. **Stand up the unsubscribe endpoint** — confirm-on-GET page, act-on-POST, idempotent, opaque unlogged token, `Referrer-Policy: no-referrer`.
5. **Seed test** — real tool → Gmail + Outlook.com + corporate tenant; check auth verdicts, multipart, headers, single subject/greeting, independent preheader, blank-name rendering; fix and re-seed.
6. **Plan the warm-up** — batch sizes, sector caps, run sheet, the three watch signals, manual send button.
7. **Send and watch** — advance batches only after replies/bounces/complaints review; divert complaints with frictionless unsubscribe.
8. **Audit** — per-recipient record of the exact rendered email; placement notes (headers) for any junked seed or report.

## Output format

1. **Template** — the HTML with structural notes (card, ghost table, footer strip)
2. **Preview config** — URL, route CSP, noindex confirmation
3. **Compliance block** — sender ID line, opt-out mechanism, recorded directions
4. **Seed-test report** — per-client auth verdicts, rendering checks, fixes applied, second-seed result
5. **Warm-up run sheet** — batches, caps, dates, watch-signal log
6. **Send-tool spec** (when tooling is in scope) — the constrained-compose shape above
7. **Delivery audit** — where the per-recipient rendered copies and placement notes live

## Quality checklist

- [ ] Card uses `width="100%" ... max-width:600px` + MSO ghost table — no percentage max-width sizing
- [ ] No text overlaid on `background-size:cover`; footer is img strip + solid `bgcolor` cell
- [ ] Preview route has its own CSP, noindex, no beacon
- [ ] Sender identification present; opt-out functional; any removal direction recorded with date
- [ ] Unsubscribe page confirms on GET, acts on POST, idempotent, token never logged, `no-referrer`
- [ ] Seed test passed on Gmail + Outlook.com + corporate tenant, re-run after fixes
- [ ] Exactly one subject, one greeting; preheader independent; blank-name rendering checked
- [ ] Warm-up batched 20–30/day with per-domain caps; manual advance; replies/bounces/complaints reviewed between batches
- [ ] Tracking disabled if the published privacy stance is no tracking

## Avoid

- `max-width:100%` sizing on nested email tables — it resolves to fixed width on phones and overflows
- Text over `background-size:cover` artwork — it collides at some width; use the strip + solid cell
- Judging deliverability without reading `X-Microsoft-Antispam-Mailbox-Delivery` — `TrustedSenderList` and `SpamFilterAuthJ` mean different fixes
- A GET-acting unsubscribe endpoint — Safe Links prefetch will silently unsubscribe recipients
- Shipping a campaign whose only test was a self-send — seed across Gmail, Outlook.com and a corporate tenant
- Automated warm-up scheduling before reputation and auto-pause guardrails exist
- Letting stakeholders edit header/footer or paste arbitrary URLs in the send tool
- Removing unsubscribe from a repeatable sending tool, whatever a one-off direction said

## Example usage

> "New `marketing.example.com` subdomain is authenticated and verified with the provider. Build the campaign template (our card design breaks on iPhones and the footer artwork slides into the text), get us Spam-Act compliant, seed-test it against Gmail and a corporate tenant, and give me the warm-up run sheet for a 400-contact list that's half public-sector."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
