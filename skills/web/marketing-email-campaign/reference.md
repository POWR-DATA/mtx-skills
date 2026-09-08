# Marketing Email Campaign — Reference

Load-on-demand excerpts for [`SKILL.md`](SKILL.md). Illustrative — load-bearing lines only; replace `<...>` placeholders.

---

## Fluid-hybrid card (600px, Outlook-pinned)

```html
<!--[if mso]><table role="presentation" width="600" cellpadding="0" cellspacing="0"><tr><td><![endif]-->
<table role="presentation" width="100%" style="width:100%; max-width:600px; margin:0 auto;" cellpadding="0" cellspacing="0">
  <tr><td>
    <!-- card content -->
  </td></tr>
</table>
<!--[if mso]></td></tr></table><![endif]-->
```

Never `width:600px; max-width:100%` — inside nested tables the percentage max-width is circular and resolves back to 600px on phones.

## Footer transition strip (no text-over-cover)

```html
<tr><td><img src="<transition-strip.png>" width="100%" style="display:block; width:100%;" alt=""></td></tr>
<!-- strip's bottom edge ends in one flat colour, e.g. #1A2B3C -->
<tr><td bgcolor="#1A2B3C" style="padding:24px;">
  <!-- footer text lives here, legible at every width -->
</td></tr>
```

## Unsubscribe headers (RFC 8058)

```text
List-Unsubscribe: <https://<domain>/unsubscribe?token=<opaque>>
List-Unsubscribe-Post: List-Unsubscribe=One-Click
```

The visible link points at the confirm-on-GET page; these headers point at the endpoint directly.

## Decoding X-Microsoft-Antispam-Mailbox-Delivery

| Fragment | Meaning |
|---|---|
| `dest:I` | delivered to Inbox |
| `dest:J` | delivered to Junk |
| `OFR:TrustedSenderList` | recipient's own Not-Junk click whitelisted this mailbox (SCL may still be 5) |
| `OFR:SpamFilterAuthJ` | authenticated but junked on sender reputation |

A filtering gateway (relay MX) breaks SPF by forwarding; aligned DKIM keeps DMARC passing → junk-but-deliverable, not rejected.

## Warm-up run sheet shape

| Batch | Date | Size | Domain caps | Replies | Bounces | Complaints | Advance? |
|---|---|---|---|---|---|---|---|
| 1 | <date> | 20 (warmest) | ≤5 per shared/filtered domain | | | | manual |
