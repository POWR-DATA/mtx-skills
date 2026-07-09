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

## Client-side confirm page (avoids Safe Links consuming the link)

Point the sign-up template at a hosted page instead of `{{ .ConfirmationURL }}`; the page completes confirmation client-side, then deep-links into the app:

```js
const { token_hash, type } = Object.fromEntries(new URLSearchParams(location.search));
const { error } = await supabase.auth.verifyOtp({ token_hash, type }); // type: 'signup'
if (!error) location.href = "<app-deep-link>";
```
