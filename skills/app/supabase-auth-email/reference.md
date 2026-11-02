# Supabase Auth Email — Reference Templates

Load-on-demand config and snippets for [`SKILL.md`](SKILL.md). Illustrative excerpts — replace `<project-ref>`, `<your-domain>`, `<APP_NAME>` placeholders.

---

## Resend SMTP

| Field | Value |
|---|---|
| Host | `smtp.resend.com` |
| Port | `465` |
| Username | `resend` (literal, lowercase — a capital fails with "535 Invalid username") |
| Password | a Resend API key with **Sending** scope |

## Resend DNS records

Add at the sending domain's actual DNS host (different hostnames than M365 mail records, so no conflict):

| Type | Host | Purpose |
|---|---|---|
| TXT | `resend._domainkey` | DKIM |
| MX + TXT (SPF) | `send` (subdomain) | bounce/return-path |
| TXT | `_dmarc` | DMARC policy |

## Management API — full SMTP PATCH

Send the **whole** SMTP group in one PATCH (a partial `smtp_*` PATCH clears the rest):

```
PATCH /v1/projects/<project-ref>/config/auth
{
  "smtp_host": "smtp.resend.com",
  "smtp_port": 465,
  "smtp_user": "resend",
  "smtp_pass": "<resend-api-key>",
  "smtp_sender_name": "<APP_NAME>",
  "smtp_admin_email": "noreply@<your-domain>"
}
```

`mailer_*` fields and `uri_allow_list` can be PATCHed independently.

## PowerShell 5.1 — UTF-8 body

Default string encoding is Latin-1 and returns 400s; send bytes and read files as UTF-8:

```powershell
$bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
Invoke-RestMethod -Method Patch -Uri $uri -Headers $headers -Body $bytes
$tpl = [System.IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
```

## Per-environment `auth-config.js`

One file per environment; a CI config check fails the build if a page carries another environment's scheme or project ref:

```js
window.<APP>_AUTH = {
  supabaseUrl: "https://<dev-project-ref>.supabase.co",
  anonKey: "<dev-anon-key>",          // anon/publishable key only
  appScheme: "<app>-dev",             // never the store app's scheme on DEV pages
};
```

## Client-side confirm page (avoids Safe Links consuming the link)

Point the sign-up template at a hosted page instead of `{{ .ConfirmationURL }}`. The page does nothing on load (scanners open it too), allow-lists the OTP type, verifies on a button tap, then deep-links into the app:

```js
const cfg = window.<APP>_AUTH;
const p = new URLSearchParams(location.search);
const token_hash = p.get("token_hash"), type = p.get("type");
if (!token_hash || !["signup", "email"].includes(type)) showError(); // login-CSRF guard
confirmButton.onclick = async () => {
  const { data, error } = await supabase.auth.verifyOtp({ token_hash, type });
  if (error) return showRefused();
  localStorage.setItem("<app>-confirmed", "1");
  showSignedInAs(data.user.email);                    // which account is now signed in
  location.href = `${cfg.appScheme}://<path>`;
};
async function showRefused() {                         // otp_expired / not found / invalid
  const { data } = await supabase.auth.getSession();
  const confirmed = data.session?.user?.email_confirmed_at || localStorage.getItem("<app>-confirmed");
  confirmed ? show("Already confirmed? Sign in")
            : show("This link was already used or has expired", ["Sign in", "Send a new link"]);
}
```

The password-reset page follows the same tap-to-continue pattern; word its instructions to what the live recovery email contains.
