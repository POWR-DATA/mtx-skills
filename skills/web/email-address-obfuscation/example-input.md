# Example Input

## Context

Northwind Analytics' five-page static site (Azure Static Web Apps, `script-src 'self'` CSP) currently publishes `hello@example.com` as a plain `mailto:` link on the contact page and in the footer of every page. The team has started seeing spam that quotes the site's wording, so the address has clearly been harvested at least once.

## Input provided

**Addresses:**
- `hello@example.com` — contact page anchor + footer link on all five pages
- `support@example.com` — appears only inside `/account/reset-password` JavaScript, in the error string "contact support@example.com if this keeps happening"

**Files that must keep a plain address:** `email-templates/welcome.html` (a transactional email template served from the repo for the send tool) — currently linked from an internal docs page

**CSP:** `default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'`

**Contact form:** none yet; one is planned next quarter

**Constraints:**
- No CSP changes if avoidable
- Must remain usable with JavaScript disabled and with screen readers
- Prove after deploy that neither address appears in plain form in anything served

**Ask:** obfuscate both addresses site-wide, handle the template file sensibly, and give me the verification steps.
