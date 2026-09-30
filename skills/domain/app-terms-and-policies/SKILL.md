---
name: app-terms-and-policies
description: Draft and publish Terms of Service and policy pages for a subscription app — unlisted preview publishing, billing wording that survives price changes, insurance-aware liability terms, and versioned in-app acceptance flows
author: PowerData
version: 1.2.0
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
- **Publish in place, and distinguish finalised from launched.** An unlisted draft at its final URL publishes in place: remove the draft banner and every confirm-flag, set Effective and Last-updated dates (the effective date doubles as the platform's `terms_version` string), and notify acceptance-flow owners of the version. "Finalised" is not "publicly launched": keep noindex and stay out of nav and sitemap while apps link the page directly, and when a later legal review edits the live document, bump Last-updated and `terms_version` and re-notify.
- **In-app-linked Terms must be in effect before real users or store review.** A "DRAFT / pending legal review" banner on a page the app links (e.g. a More-menu row) is both a legal gap and an app-review rejection trigger. Either finalise and date the document, or remove the in-app link until it is; an unlisted (noindex, not in nav) but in-effect page is fine.
- **Phrase the liability cap as a greater-of, expressly subject to the ACL.** "Our total liability is limited to the GREATER OF the fees you have paid us in the 12 months before the claim and AUD $100" — the greater-of form guarantees the floor to every user including free/non-paying ones (state plainly which user type pays nothing so the floor visibly applies to them). The cap sits inside a "to the extent permitted by law" preamble alongside an explicit section stating non-excludable consumer guarantees are not excluded; an unqualified cap is unenforceable in an Australian consumer context (consumer guarantees and personal-injury liability cannot be limited for personal-use services) and is a rejection/complaint risk.
- **Keep any indemnity narrow — the safe Australian shape.** Australian-drafted app terms routinely include a user indemnity, even free consumer wellbeing apps (Smiling Mind) and both sides of two-audience platforms (Halaxy consumer AND practitioner terms), but the unfair-contract-terms regime makes broad indemnities in standard-form consumer contracts risky. Draft it breach-scoped, reasonableness-limited and fault-excluded ("loss we reasonably incur arising from your breach or unlawful use, except to the extent we caused the loss"), and open the liability section "Subject to [the ACL section], and to the extent permitted by law" so cap and indemnity visibly sit under the consumer-guarantee carve-out.
- **A consent-card-linked page is a hardcoded contract.** When an app's consent card links a web page, agree the path exactly and never move it. Scope the page to ONLY what the consent needs beyond existing documents (do not repeat crisis, age-gate or data-sharing text already in the in-app card and Terms — duplication drifts out of sync), state the points are additional to the Terms and Privacy Policy with links, and keep it unlisted, noindexed and beacon-free when the audience is patients.
- **Content standards target conduct towards others, never honest self-expression.** For a journalling or mental-health app, cover abusive, discriminatory or hateful, sexually explicit, impersonating and spam conduct, with an explicit carve-out ("this is not a restriction on honest journalling") — raw language in a private or shared entry is the product working, and a profanity ban would prohibit exactly that. Pair the standards with a "we may remove or hide content, acting reasonably" right; benchmarks: Headspace has the fullest conduct list, and Recovery Record (the established eating-disorder app) deliberately has no illness-specific content bans.
- **Integrate a benchmarking review by mapping, not rewriting.** Map every spec item against the current document first — most asks usually exist already, and the job is add-what-is-missing without duplication. Grep-verify the REMOVE list rather than trusting memory (HIPAA, GDPR machinery, "including but not limited to", fixed retention years), and add the OAIC-favoured layered structure by prepending a short plain-language "In Short" summary to the full policy rather than restructuring it.
- **Factual infrastructure claims come from the actual configuration, not the vendor's nationality.** A review spec asserted a crash-reporting region was the United States while the deployed config was deliberately EU (the ingest endpoint hostname proves the region), and the claim flip-flopped in print within a day. When an upstream review contradicts the current document on a fact you cannot verify, apply-and-flag loudly for confirmation; the accurate disclosure pattern is "hosted in <region>; the provider is <country>-based and its authorised support personnel may access systems from <country>".
- **Disclose sub-processors by purpose and country, as a maintained list.** Name each material provider with its PURPOSE and COUNTRY, mark the list "current as at the last-updated date" so it reads as maintained rather than stale, exclude app stores as distribution-not-processors of user data, distinguish hosting region from provider nationality where they differ, and describe substitutable categories (push-notification delivery) by function rather than freezing vendor names.
- **A Last-updated bump does not automatically mean re-acceptance work.** First check whether the platform's acceptance is version-pinned or timestamp-only — a `terms_accepted_at` with no version column has no re-acceptance flow to trigger. If timestamp-only and pre-launch with few accepted users, record the new date as the future version-pinning baseline (in the deferred issue) instead of building re-acceptance reactively.
- **Diff a returned review section by section, and cherry-pick.** When a reviewer sends a legal document back as pasted plain text, strip the live HTML to prose and compare section by section, bucketing changes as substantive, wording or trivial, and checking renumbering and cross-references. One clinical reviewer's rewrite contained six load-bearing errors: an unqualified data-location claim contradicting the privacy policy, a registration requirement naming only one regulator (excluding a whole profession), an incoherent "limited to the greater of, at our option" consumer-law remedy, a reversed description of which records a practitioner can see, an unevidenced "independent security testing" claim, and a self-contradiction on third-party collection. Take the genuine improvements into the existing structure rather than adopting a compressed rewrite that drops required disclosures.
- **A new kind of personal information means a privacy-policy update in the same cycle.** When the platform started collecting professional registration numbers as sign-up opened beyond one profession, the policy's inventory had to be updated and its Last updated date bumped, or it under-describes collection (APP 5). Ask the platform side to tell the website side whenever onboarding fields change.
- **Never describe a verification or approval step that does not exist.** While practitioner sign-up was self-declared, invitation gating could only be framed publicly as "the trial is invitation-limited". Watch for sentences stated as fact about users — "practitioners who use the app are registered health professionals" reads as an assurance the operator checks. Put the requirement in an obligation bullet instead.
- **Keep research-study vocabulary off a product-trial page.** "Participate", "your role in the trial", "entirely voluntary" and "study" make an early product release read like a formal clinical study, implying ethics approval and participant information statements. Use product-beta language: "take part", "your part", "always your choice".

## Process

1. **Inventory the surfaces** — where users sign up, pay, and can later find the Terms; the payment provider; the current draft text.
2. **Publish unlisted previews** — final URLs, `noindex` route header, excluded from sitemap/nav, draft banner, confirm-flag markup on open items; share the links with reviewers.
3. **Draft billing wording** — fees/frequency/trials "as displayed at subscription", provider named, no numbers.
4. **Insurance pass** — read the Certificate of Currency's Insured Business and sub-limits; request full policy wording from the broker; set the liability cap below cover; record the broker's answer on contractual liability.
5. **Design the acceptance record** — `terms_version` (effective date), `accepted_at`, configurable terms URL, re-acceptance on version bump.
6. **Build the flow behind a flag** — explicit acceptance UI with links, terms + fees at checkout, links reachable post-onboarding.
7. **Finalise in place** — remove banner and confirm-flags, set Effective and Last-updated dates, notify acceptance-flow owners of the new `terms_version`; keep noindex/out-of-nav while only apps link the page.
8. **Launch publicly** (when intended) — lift noindex, add to sitemap and nav, flip the feature flag; on any later revision bump Last-updated and `terms_version` and re-notify.
8. **Process a returned review** by diffing prose section by section, bucketing each change, and verifying cross-references and numbering before accepting anything.
9. **Re-check the collection inventory** whenever onboarding fields change, and bump Last updated in the same cycle.

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
- [ ] Liability cap uses the greater-of form, under a "to the extent permitted by law" preamble and expressly subject to the ACL carve-out; any indemnity breach-scoped, reasonableness-limited, fault-excluded
- [ ] No draft banner remains on any page the app links; in-app-linked pages are in effect
- [ ] Sub-processor list names purpose + country per provider and is marked "current as at" the last-updated date
- [ ] Consent-card-linked page path agreed and frozen; page scoped to consent-only additions
- [ ] Content standards conduct-scoped with an honest-journalling carve-out (where applicable)
- [ ] Returned reviews diffed section by section; each change bucketed; renumbering and cross-references checked
- [ ] No claim of a verification, approval or testing step the operator does not actually perform
- [ ] Privacy-policy inventory covers every field onboarding now collects, with Last updated bumped
- [ ] Trial pages use product-beta language, not research-study vocabulary

## Avoid

- Circulating drafts as documents or changing URLs — reviewers lose the thread; publish unlisted at the final URL
- Writing "$X per month, billed monthly" into the Terms — it breaks on the first promotion or anniversary-billing change
- Assuming a consulting policy covers operating a software product — read the Insured Business description
- Setting the liability cap at or above insurance limits
- Shipping `terms_accepted = true` with no version or timestamp
- Publishing the pages before the acceptance flow exists, or vice versa — flag-gate and flip together
- Leaving a draft banner on a Terms page the app already links — legal gap and store-review rejection trigger
- An unqualified liability cap or a broad "any claim arising from your use" indemnity in an Australian consumer contract
- Repeating in-app consent-card or Terms text on a consent page — duplicated text drifts out of sync
- Copying a review spec's factual claims (hosting regions) without checking the deployed configuration
- Building a re-acceptance flow reactively when acceptance is timestamp-only — record the baseline and defer
- Adopting a reviewer's compressed rewrite wholesale — it can drop required disclosures and contradict the privacy policy
- Stating as fact something about users that the operator does not verify — put it in an obligation bullet
- Letting onboarding add a new data field without updating the policy inventory and its date
- Research-study vocabulary on a product-trial page — it implies ethics approval the product does not have

## Example usage

> "We launch the subscription in three weeks. I've got a draft Terms doc, our broker wants to see the liability clause, and the app currently just stores a `terms_accepted` boolean. Set up the pages so reviewers can see them without Google indexing them, fix the billing wording, and spec the acceptance flow."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
