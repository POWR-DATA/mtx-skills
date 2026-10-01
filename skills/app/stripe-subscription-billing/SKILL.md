---
name: stripe-subscription-billing
description: Run subscription pricing against Stripe from a database plan catalogue — per-environment price ids, idempotent price setup, and modelling permanent comped access without a sentinel trial date
author: PowerData
version: 1.0.0
license: MIT
---

# Stripe Subscription Billing

## Purpose

Keep a subscription product's pricing editable in one place while Stripe remains the thing that actually charges — a database plan catalogue holding the amount, per-environment Stripe price ids written back by a setup script, prices rotated rather than mutated, and comped accounts modelled so they bill $0 without pretending to be on a trial that never ends.

## When to use

When wiring an app's subscription plans to Stripe for the first time, when a price changes, or when someone needs permanent free access. Apply before any price id is hardcoded into a migration, and again whenever the displayed price and the charged price risk diverging.

## Inputs expected

Partial inputs are acceptable — state assumptions for the rest.

- The plans, their amounts, currency and billing interval
- Which environments exist (test, live, and any staging) and how the app selects between them
- Whether prices are tax-inclusive, and the tax display requirement
- Who needs comped or trial access, and whether it is time-limited or permanent

---

## Guiding principles

- **The database row is the editable source of truth; Stripe holds the charge.** Store `price_cents` (the amount) on a plan-catalogue row alongside a **per-environment** `stripe_price_id`. Test and live price ids differ, so a price id must never be hardcoded into a migration — the migration would be wrong in one environment by construction. A small setup script reads `price_cents`, creates or finds the Stripe Price, and writes the id back onto the row for that environment, which keeps display and charge in sync from one place.
- **Stripe Prices are immutable, so a price change is a rotation, not an edit.** Make the setup script idempotent by `lookup_key`: reuse the existing price when amount, currency and interval all match, and when the amount changes create a **new** Price passing `transfer_lookup_key=true` so the key moves to it. *Note: the fresh-create path is the one exercised in practice; the reuse and rotate branches are implemented but have not been verified end to end — treat them as the intended design and test them on first real use.*
- **Set `tax_behavior: 'inclusive'` on the Price for GST or other tax-inclusive display**, so the displayed amount is what the customer is charged.
- **Do not model permanent free access as a far-future trial.** Stripe rejects a `trial_end` more than five years ahead with "Invalid timestamp: can be no more than five years in the future", so a sentinel date is not available — and a subscription parked in `trialing` misrepresents its own state anyway.
- **Model a permanent comp as a 100%-off forever coupon on an active subscription.** End the trial now (`trial_end: 'now'`, `proration_behavior: 'none'`) and attach a `duration: 'forever'` 100%-off coupon. Every invoice is $0 and nothing is charged, the subscription reports as genuinely active, and removing the coupon simply resumes billing at the next renewal — which makes comping reversible without touching the plan.
- **Keep the environment selection explicit in the catalogue, not in code branches.** One row per plan per environment, or one row with an environment-keyed id column; either way the app reads the id for the environment it is running in rather than deciding at the call site.

## Process

1. **Model the catalogue** — one row per plan with `price_cents`, currency, interval, `lookup_key`, and a per-environment `stripe_price_id` column.
2. **Write the setup script** — read `price_cents`, find-or-create the Stripe Price by `lookup_key`, write the id back for the current environment.
3. **Set `tax_behavior`** on creation where prices are displayed tax-inclusive.
4. **Run it per environment** — test first, then live; never copy ids between them.
5. **Change a price** by editing `price_cents` and re-running the script, which creates a new Price and transfers the lookup key.
6. **Comp an account** by ending the trial now and attaching a forever 100%-off coupon; record who approved it.
7. **Verify** — the displayed price matches the Stripe Price, an invoice for a comped account is $0, and removing the coupon restores the normal amount at renewal.

## Output format

1. **Plan catalogue schema** — columns, keys, environment handling
2. **Setup script behaviour** — find-or-create logic, lookup-key rotation, what it writes back
3. **Price change procedure** — steps from amount edit to live Price
4. **Comp procedure** — the API calls, what the subscription looks like afterwards, how to reverse it
5. **Verification** — display/charge match, $0 invoice, reversal at renewal

## Quality checklist

- [ ] No Stripe price id hardcoded in a migration or in application code
- [ ] `price_cents` is the editable amount; the id is written back per environment by the script
- [ ] Setup script idempotent by `lookup_key`; a changed amount creates a new Price with `transfer_lookup_key=true`
- [ ] `tax_behavior: 'inclusive'` set where prices are displayed tax-inclusive
- [ ] Permanent comps use a forever 100%-off coupon, not a far-future `trial_end`
- [ ] A comped subscription shows as active and invoices $0
- [ ] Removing the coupon demonstrably resumes billing at the next renewal

## Avoid

- Hardcoding a `stripe_price_id` in a migration — test and live ids differ, so it is wrong somewhere by construction
- Trying to edit a Stripe Price's amount — they are immutable; rotate the lookup key onto a new one
- Re-creating a Price on every setup run instead of finding it by `lookup_key`
- Modelling permanent access as a far-future `trial_end` — Stripe caps it at five years and the state is a lie
- Leaving a comped subscription in `trialing`, where dunning and renewal logic treat it as temporary
- Copying price ids between environments to "save a step"

## Example usage

> "Our plan is $29/month and the price id is hardcoded in a migration, so staging charges the wrong thing. We also need to give three foundation customers free access permanently — I tried setting `trial_end` to 2099 and Stripe refused it. Sort out the pricing source of truth and the comped accounts."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
