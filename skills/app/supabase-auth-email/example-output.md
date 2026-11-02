# Example Output — Supabase Auth Email

## 1. SMTP configuration

Root cause of the 500: the SMTP username was `Resend` (capitalised) → "535 Invalid username", surfaced as an HTTP 500 on sign-up (the user row was still created). Fixed via a **single full-group PATCH**:

```
PATCH /v1/projects/<project-ref>/config/auth
{ "smtp_host": "smtp.resend.com", "smtp_port": 465,
  "smtp_user": "resend", "smtp_pass": "<resend-api-key>",
  "smtp_sender_name": "TrackMyPlants", "smtp_admin_email": "noreply@mail.example.com" }
```

> The earlier partial PATCH of just `smtp_pass` had blanked host/user — that is why templates stayed locked.

## 2. DNS records (Resend, at the domain host)

| Type | Host | Status |
|---|---|---|
| TXT (DKIM) | `resend._domainkey` | Verified |
| MX + SPF | `send` | Verified |
| TXT (DMARC) | `_dmarc` | Verified |

Early test emails landed in spam despite passing SPF/DKIM — expected warm-up, improved over the next day.

## 3. Templates applied

- Template editing unlocked once custom SMTP was set (newer-project gate).
- Branded templates pushed via the Management API **after** SMTP, with `__APP_NAME__` → `TrackMyPlants`.
- `smtp_sender_name` set in the dashboard, then the template apply re-run (dashboard saves revert pushed templates).

## 4. Flow config

- **Confirmation:** switched from `{{ .ConfirmationURL }}` to a hosted page that does nothing on load and calls `verifyOtp({ token_hash, type: 'signup' })` only when the user taps **Confirm** → deep-links into the app. Outlook Safe Links opens the page but no longer spends the link; the email also carries the 6-digit code as a fallback.
- **Confirm page guards:** only `signup` and `email` OTP types are accepted (anything else is a login-CSRF vector), and the page shows which account is now signed in. A refused link shows "Already confirmed? Sign in" when the account is confirmed, otherwise "This link was already used or has expired" with **Sign in** and **Send a new link**.
- **Reset:** added the reset page URL to `uri_allow_list`, so `redirectTo` is honoured instead of falling back to Site URL. The page waits for a tap, and its wording matches the live recovery email (button only, no code).
- **Hosted pages:** `/reset-password` and `/confirm-email` are static pages reading `window.TRACKMYPLANTS_AUTH` from `auth-config.js` (URL, anon key and app scheme only); a CI check pins DEV pages to the DEV scheme and project ref; CSP `connect-src https://*.supabase.co`; supabase-js pinned from the CDN with SRI and a fail-closed guard; `persistSession: false`; no `redirect_to`; both paths excluded from AASA/intent filters.
- **Unconfirmed state:** `mailer_autoconfirm = false` stays on, so the app shows a "check your inbox, then sign in" screen with a resend button; sign-up on an existing email (empty `identities`) is shown as "already registered — sign in or reset". Session refresh runs only when `getUser()` reports confirmed but the JWT does not, debounced, so two open tabs no longer loop into a 429.

## 5. Verification

- Sign-up now returns 200 and the confirmation email arrives and completes.
- Opening the confirm link a second time shows "Already confirmed? Sign in", not an expiry error.
- Password reset lands on the correct page.
- `auth_logs` (Management API analytics) clean — no more "535" entries.
