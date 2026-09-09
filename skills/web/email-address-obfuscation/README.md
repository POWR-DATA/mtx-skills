# Email Address Obfuscation

Protect published email addresses from scrapers on a static site — JavaScript-assembled mailto links with an XOR-hex payload, accessible fallbacks, CSP-clean implementation, and payload verification.

## What this skill does

Implements the one anti-scraping technique that blocked 100% of live harvesters in 2026 honeypot testing: addresses stored as XOR-hex payloads that a tiny same-origin script rebuilds into normal mailto links at load, with a screen-reader-friendly noscript fallback. Covers the full sweep — anchors, JavaScript string literals, error messages — and the verification pass proving no served file still contains a plain address.

## When to use it

- Publishing a contact email on any public page of a static site
- Auditing a site where addresses sit in HTML, JS literals, or auth-page error strings
- A published address has started attracting spam and needs re-protecting
- The site runs a strict `script-src 'self'` CSP and inline tricks are off the table

## Example use cases

- Replace a plain `mailto:` on the contact page with the XOR-hex span + decoder pattern
- Convert a support address embedded in a password-reset error message to runtime `join('@')` assembly
- Decode-verify a batch of payloads before deploy and curl-grep the live site for leaks
- Decide when a contact form should be the primary channel instead of any mailto

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |

## How to use

Copy `SKILL.md` into your AI tool as an instruction or system prompt. Provide the addresses, the pages that reference them, and the site's CSP, then follow the structured output. Pairs with [Static Website Config and CSP](../static-website-config-and-csp/) for the CSP side.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
