# Example Input

## Context

Northwind Analytics is launching its first outreach campaign for a training course. A `marketing.example.com` subdomain is verified with the email provider and DKIM/SPF/DMARC pass. The first template attempt breaks on phones and the founder wants course coordinators to run future sends themselves.

## Input provided

**Brand:** logo SVG, palette (`#1A2B3C` primary, `#E8734A` accent), display font "Sora" (Google Fonts)

**Copy:** subject "Data Foundations — March intake open", preheader, ~150-word body, one CTA ("View course dates" → `https://www.example.com/courses/data-foundations`)

**Template problems observed:**
- Card set to `width:600px; max-width:100%` still overflows on iPhone and Android
- Footer text sits on a `background-size:cover` wave graphic and collides with the colour boundary when text wraps
- The stakeholder preview at `www.example.com/email-preview` renders unstyled — serif text, blue links, preheader visible

**Audience:** 380 contacts from a conference list — roughly half private practices (Gmail/Outlook.com/own domains), half public-sector staff who all share one government email domain

**Compliance:** no prior relationship for most contacts; Australian audience; published privacy stance is **no tracking**

**Tooling:** sends go through an internal tool; coordinators should compose subject/preheader/body and pick a recipient group, nothing else

**Ask:** fix the template, make the campaign Spam Act compliant, define the seed test, and give me the warm-up plan and send-tool constraints.
