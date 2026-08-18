---
name: app-terms-and-policies
description: Draft and publish Terms of Service and policy pages for a subscription app — unlisted preview publishing, billing wording that survives price changes, insurance-aware liability terms, and versioned in-app acceptance flows
author: PowerData
version: 1.0.0
license: MIT
---

# App Terms and Policies

## Purpose

Take a subscription app's Terms of Service, Privacy Policy and related pages from draft to published — reviewable at their final URLs while still unlisted, worded so billing and pricing changes never require a re-draft, aligned with what the business's insurance actually covers, and backed by an in-app acceptance flow that records which version each user accepted.

## When to use

Before an app takes its first paying subscriber, before a Terms revision, or when a broker/insurer asks what the product's contractual liability looks like. Apply while the pages are still drafts — the preview-publishing pattern is most valuable early — and again whenever the acceptance flow, billing model or insurance cover changes.

## Inputs expected

Partial inputs are acceptable — flag what is missing rather than inventing it.

- The app, its subscription model (payment provider, trial/anniversary billing intent) and the surfaces where users sign up (app, web portal, checkout)
- Existing draft Terms/Privacy text, if any, and the static site or host that will publish them
- The Certificate of Currency (or policy summary) for the business's insurance, and the broker's contact
- Who reviews (founder, broker, insurer, counsel) and the intended publication date

---

## Guiding principles

- **Publish drafts unlisted at their final URL.** Route header `X-Robots-Tag: noindex`, out of the sitemap and nav, an amber draft banner and dotted-underline "confirm flags" on open items — so reviewers, the broker and the insurer all get one stable link that upgrades in place at publication instead of a shifting document.
- **Do not hard-code billing cycles or prices in the Terms.** State that fees, billing frequency and any trial arrangements are as displayed at subscription and that payments are processed by the named provider — which stays true across anniversary billing, price changes and promotions.
- **Read the Certificate of Currency before finalising liability terms.** Check the "Insured Business" description (consulting wording may not cover operating a software product), note cyber-exclusion sub-limits, ask the broker for the full policy wording to answer the contractual-liability question, and set the Terms' liability cap below the cover limits.
- **A bare `terms_accepted` boolean is inadequate.** Acceptance needs a configurable terms URL, explicit acceptance UI with links to Terms and Privacy, `terms_version` (equal to the effective date) plus `accepted_at`, and re-acceptance on version change.
- **Keep the terms reachable and the flow flag-gated.** Links to Terms/Privacy must be reachable after onboarding, fees plus terms must be shown at checkout, and the whole acceptance flow sits behind a feature flag until publication so it can ship dark with the pages.
- **Version by effective date.** `terms_version` equals the effective date shown on the published page; a revision is a new effective date and triggers re-acceptance.

## Process

1. **Inventory the surfaces** — where users sign up, pay, and can later find the Terms; the payment provider; the current draft text.
2. **Publish unlisted previews** — final URLs, `noindex` route header, excluded from sitemap/nav, draft banner, confirm-flag markup on open items; share the links with reviewers.
3. **Draft billing wording** — fees/frequency/trials "as displayed at subscription", provider named, no numbers.
4. **Insurance pass** — read the Certificate of Currency's Insured Business and sub-limits; request full policy wording from the broker; set the liability cap below cover; record the broker's answer on contractual liability.
5. **Design the acceptance record** — `terms_version` (effective date), `accepted_at`, configurable terms URL, re-acceptance on version bump.
6. **Build the flow behind a flag** — explicit acceptance UI with links, terms + fees at checkout, links reachable post-onboarding.
7. **Publish** — remove banner/flags/noindex, add to sitemap and nav, set the effective date, flip the feature flag.

## Output format

1. **Preview publishing plan** — URLs, route/header config, banner and confirm-flag markup, reviewer list
2. **Terms clauses** — billing, liability cap, provider references, effective-date/versioning language
3. **Insurance notes** — Insured Business wording, exclusions/sub-limits, broker questions and answers, chosen cap
4. **Acceptance flow spec** — data fields, UI points (sign-up, checkout, settings), re-acceptance rule, feature flag
5. **Publication checklist** — what flips at go-live

## Quality checklist

- [ ] Drafts live at final URLs with `X-Robots-Tag: noindex`, out of sitemap/nav, banner + confirm flags visible
- [ ] Terms contain no hard-coded prices or billing cycles; provider named
- [ ] Certificate of Currency read; liability cap set below cover; broker asked for full wording
- [ ] Acceptance stores `terms_version` (effective date) + `accepted_at`; re-acceptance on version change
- [ ] Terms/Privacy links reachable after onboarding; fees + terms shown at checkout
- [ ] Acceptance flow behind a feature flag until publication

## Avoid

- Circulating drafts as documents or changing URLs — reviewers lose the thread; publish unlisted at the final URL
- Writing "$X per month, billed monthly" into the Terms — it breaks on the first promotion or anniversary-billing change
- Assuming a consulting policy covers operating a software product — read the Insured Business description
- Setting the liability cap at or above insurance limits
- Shipping `terms_accepted = true` with no version or timestamp
- Publishing the pages before the acceptance flow exists, or vice versa — flag-gate and flip together

## Example usage

> "We launch the subscription in three weeks. I've got a draft Terms doc, our broker wants to see the liability clause, and the app currently just stores a `terms_accepted` boolean. Set up the pages so reviewers can see them without Google indexing them, fix the billing wording, and spec the acceptance flow."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
