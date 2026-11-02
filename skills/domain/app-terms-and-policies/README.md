# App Terms and Policies

Draft and publish Terms of Service and policy pages for a subscription app — unlisted preview publishing, billing wording that survives price changes, insurance-aware liability terms, and versioned in-app acceptance flows.

## What this skill does

Guides the path from a draft Terms document to published, accepted terms for a subscription app: publishing drafts unlisted at their final URLs so every reviewer shares one stable link, writing billing clauses that reference "as displayed at subscription" instead of numbers, checking the business's Certificate of Currency before setting a liability cap, and specifying an acceptance flow that records which version of each document was accepted, labelled by the page's Last updated date — all flag-gated until go-live. It also covers wording billing clauses from what the platform actually does, consent ticks and marketing opt-ins, and fencing trial-only clauses for deletion at launch.

## When to use it

- A subscription app is about to take its first paying customer
- Terms are being revised and existing users must re-accept
- A broker or insurer has asked about the product's contractual liability
- The app currently records only a `terms_accepted` boolean
- Sign-up is gaining a consent tick or a marketing opt-in
- Billing clauses must match what the platform does on failed payments, cancellation and complimentary access

## Example use cases

- Publish draft Terms and Privacy pages at `/terms` and `/privacy` with `noindex`, a draft banner and confirm flags for the broker to review
- Rewrite a billing clause so anniversary billing and a promotion do not require a Terms change
- Set the liability cap after reading the Certificate of Currency and asking the broker for policy wording
- Spec per-document version labels + `accepted_at`, one required tick and an optional marketing opt-in, behind a feature flag
- Word billing clauses from the platform's written answers and fence trial-only clauses for deletion at launch

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |

## How to use

Copy `SKILL.md` into your AI tool as an instruction or system prompt. Provide the app's subscription model, draft text, insurance certificate and reviewer list, then work through the preview → wording → insurance → acceptance → publish sequence. This skill structures the work; it is not legal advice — have counsel review the final clauses.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
