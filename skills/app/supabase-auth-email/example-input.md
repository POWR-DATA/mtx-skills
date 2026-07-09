# Example Input — Supabase Auth Email

> New Supabase project. Sign-up returns a 500, no confirmation email arrives, and the dashboard won't let me edit the email templates. I need branded auth emails and a working confirm + reset flow.

**Project details:**
- Supabase project (created 2026, free plan)
- Management API access token available
- App name: `TrackMyPlants`
- Frontend: Expo React Native + a hosted web page for auth callbacks

**Email provider:**
- Resend account, API key created (Sending scope)
- Sending domain: `mail.example.com` (DNS managed at the domain host)

**Symptoms:**
- Editing email templates in the dashboard silently does nothing
- `POST /auth/v1/signup` returns HTTP 500, but a user row appears
- When a confirmation email does arrive, clicking the link never confirms the account (corporate Outlook)
- Password reset emails link to the site root, not my reset page

**What I need:**
- Custom SMTP configured correctly
- Branded templates applied and surviving dashboard saves
- Confirmation and reset flows that actually complete
