---
name: stripe-subscription-billing
description: Run subscription billing against Stripe from a database plan catalogue — idempotent per-environment price setup, webhook mirroring, guarded Checkout and upgrades, race-safe plan limits, complimentary access and how it ends, failed-payment suspension, Australian tax invoices, and Customer Portal settings
author: PowerData
version: 1.1.0
license: MIT
---

# Stripe Subscription Billing

## Purpose

Keep a subscription product's pricing editable in one place while Stripe remains the thing that actually charges — a database plan catalogue holding the amount, per-environment Stripe price ids written back by a setup script, prices rotated rather than mutated — and keep the app's entitlements in step with Stripe at every edge: webhook ordering, Checkout and upgrades, plan limits under concurrency, complimentary access and how it ends, failed payments, tax invoices and the Customer Portal.

## When to use

When wiring an app's subscription plans to Stripe for the first time, when a price changes, or when someone needs complimentary access. Apply before any price id is hardcoded into a migration, before billing goes live (webhooks, Checkout, plan limits, invoices, portal), and again whenever the displayed price, the charged price and the app's entitlement risk diverging.

## Inputs expected

Partial inputs are acceptable — state assumptions for the rest.

- The plans, their amounts, currency, billing interval and any usage limits (seats, linked users)
- Which environments exist (test, live, and any staging) and how the app selects between them
- Whether prices are tax-inclusive, the tax display requirement, and the seller's tax registration (e.g. GST and ABN)
- Who needs complimentary or trial access, whether it is time-limited or permanent, and whether a card is collected
- Whether there is a Free plan, and what access the app should give when a payment fails

---

## Guiding principles

### Pricing and catalogue

- **The database row is the editable source of truth; Stripe holds the charge.** Store `price_cents` (the amount) on a plan-catalogue row alongside a **per-environment** `stripe_price_id`. Test and live price ids differ, so a price id must never be hardcoded into a migration — the migration would be wrong in one environment by construction. A small setup script reads `price_cents`, creates or finds the Stripe Price, and writes the id back onto the row for that environment, which keeps display and charge in sync from one place.
- **Stripe Prices are immutable, so a price change is a rotation, not an edit.** Make the setup script idempotent by `lookup_key`: reuse the existing price when amount, currency and interval all match, and when the amount changes create a **new** Price passing `transfer_lookup_key=true` so the key moves to it. *Note: the fresh-create path is the one exercised in practice; the reuse and rotate branches are implemented but have not been verified end to end — treat them as the intended design and test them on first real use.*
- **Set `tax_behavior: 'inclusive'` on the Price for GST or other tax-inclusive display**, so the displayed amount is what the customer is charged.
- **Keep the environment selection explicit in the catalogue, not in code branches.** One row per plan per environment, or one row with an environment-keyed id column; either way the app reads the id for the environment it is running in rather than deciding at the call site. Account settings are per environment too, and Stripe sandboxes and the legacy "Test mode" are separate environments — confirm which account a test key belongs to before changing any setting.

### Entitlement, Checkout and plan changes

- **Mirror Stripe from webhooks, with three guards.** Take the plan from the subscription's price in the webhook — except while a complimentary free window is trialing, when it stays locked to the comp plan; otherwise a customer who picks a bigger plan gets it free until the trial ends. Mirror Stripe's live status behind an ordering marker instead of hard-coding `past_due`, because the final `invoice.payment_failed` can arrive after `customer.subscription.deleted`. Allow a few days' tolerance past the period end, or entitlement drops between renewal and its webhook. See *Webhook mirror* in [`reference.md`](reference.md).
- **Guard Checkout and plan changes against Stripe's live state, never the local mirror.** Before opening any subscription Checkout, refuse a customer Stripe already bills and expire their other open Checkout sessions, or two tabs produce two subscriptions. Before a plan change, read the live subscription's `discount` and `cancel_at_period_end`. Offer a Free tier only to accounts with no billing history, or a cancelled payer re-runs onboarding onto Free and keeps everything for $0.
- **Upgrade with `payment_behavior: 'error_if_incomplete'`, and catch `requires_action` separately.** A declined card is refused cleanly with the plan unchanged, but a card needing 3D Secure is refused too, so it needs its own path. Test declines with card `4000 0000 0000 0341`, which attaches successfully and then fails every charge (`…0002` fails at attach), on an account with no proration credit: a prior downgrade's credit netted the next upgrade invoice to $0, so the bad card was never charged.
- **Enforce seat or linked-user limits as check-and-write in one SQL function.** It takes the customer's subscription row lock (`SELECT ... FOR UPDATE`), counts pending invitations as well as connections, and is shared by every path that adds usage — invite create, invite accept, over-limit refresh. Prove it with parallel requests: 12 simultaneous claims against a cap of 3 produced exactly 3 wins. See *Plan-limit function* in [`reference.md`](reference.md).

### Complimentary access

- **Do not model permanent free access as a far-future trial.** Stripe rejects a `trial_end` more than five years ahead with "Invalid timestamp: can be no more than five years in the future", so a sentinel date is not available — and a subscription parked in `trialing` misrepresents its own state anyway.
- **Model a permanent comp as a 100%-off forever coupon on an active subscription.** End the trial now (`trial_end: 'now'`, `proration_behavior: 'none'`) and attach a `duration: 'forever'` 100%-off coupon. Every invoice is $0 and nothing is charged, the subscription reports as genuinely active, and removing the coupon simply resumes billing at the next renewal — which makes comping reversible without touching the plan.
- **Time-limited complimentary access comes in three mechanisms that end differently — give them all the same notice.** A Stripe free period with the card collected at Checkout (Checkout shows the first-charge date); a 100%-off coupon for N months on a paying customer (full price from the next billing date once removed — the time-limited form of the forever coupon); and an admin grant with no Stripe subscription (moves to the Free plan at the end). Give every one 14 days' notice with an automatic email, because ending a Stripe free period early otherwise charges the card immediately. See *Complimentary access* in [`reference.md`](reference.md).
- **Deduplicate end-of-access notices per end date, at second precision.** Stripe rewrites `trial_end` to whole seconds, so a "notice already sent for this end date" record stamped with milliseconds looked like a new date on the next run and re-sent the email.
- **Keep transitions gap-free and clean.** When a scheduled job performs the state change (complimentary window ended → Free), the read-side entitlement check must keep the row entitled until the job moves it, or users see an access gap of up to one job interval. A card-backed free window cancelled before its first charge returns to Free, and every cancellation clears the complimentary markers.

### Failed payments, invoices and the portal

- **Map each dunning stage to an access state, and word the terms to match.** Stripe retried a failed renewal for about two weeks (8 attempts), then cancelled the subscription. A workable mapping: full access with an overdue banner during the retries, then suspension behind a locked "overdue payment" screen with a restart button once Stripe cancels. On suspension, void the subscription's open invoices so nobody pays twice after restarting. Terms and FAQs should say "cancelled and access suspended until payment is made" and state the effect on any linked end users.
- **Make every invoice a valid Australian tax invoice before the terms promise one.** For a GST-registered seller, set the AU ABN as the account's default tax ID (otherwise it is not printed in the invoice header), a default memo "Tax invoice. Total price includes GST." and a footer with the legal entity name and ABN; under A$1,000 the GST-inclusive statement is the permitted form. Invoices issued earlier keep their old layout, so confirm the settings are on before the terms say "each payment comes with a tax invoice". See *Australian tax invoices* in [`reference.md`](reference.md).
- **Keep plan switching off in the Customer Portal, in test and live.** A switch there bypasses the app's limit checks. The portal's "Return to …" link and headings use the account's public business name, so set the public details (brand name, support email and URL, privacy and terms URLs) before launch.

## Process

1. **Model the catalogue** — one row per plan with `price_cents`, currency, interval, `lookup_key`, a per-environment `stripe_price_id` column, and any usage limit.
2. **Write the setup script** — read `price_cents`, find-or-create the Stripe Price by `lookup_key`, write the id back for the current environment.
3. **Set `tax_behavior`** on creation where prices are displayed tax-inclusive.
4. **Run it per environment** — test first, then live; never copy ids between them, and confirm which account each key belongs to.
5. **Change a price** by editing `price_cents` and re-running the script, which creates a new Price and transfers the lookup key.
6. **Wire the webhook mirror** — plan from the price (locked during a complimentary trial), live status behind an ordering marker, period-end tolerance.
7. **Guard Checkout and plan changes** — refuse already-billed customers, expire their other open sessions, Free only without billing history, live `discount` and `cancel_at_period_end` checks, upgrades with `error_if_incomplete` and a `requires_action` branch.
8. **Enforce plan limits** in one locking SQL function called from every usage path; prove it with parallel claims.
9. **Comp an account** — permanent: end the trial now and attach a forever 100%-off coupon; time-limited: pick one of the three mechanisms and schedule the 14-day notice email. Record who approved it.
10. **Map the transitions** — dunning stages to access states, scheduled job plus read-side grace, Free on early cancellation of a card-backed window, markers cleared on every cancellation, open invoices voided on suspension; align the terms wording.
11. **Configure account settings in each environment** — default tax ID, invoice memo and footer; Customer Portal with plan switching off and public details set.
12. **Verify** — the displayed price matches the Stripe Price, a comped invoice is $0 and removing the coupon restores the amount at renewal, a declined upgrade leaves the plan unchanged, parallel claims never exceed the cap, and a new invoice shows the ABN and GST statement.

## Output format

1. **Plan catalogue schema** — columns, keys, environment handling, usage limits
2. **Setup script behaviour** — find-or-create logic, lookup-key rotation, what it writes back
3. **Price change procedure** — steps from amount edit to live Price
4. **Complimentary access** — mechanism per case, the API calls, how each ends or is reversed, the notice schedule
5. **Webhook and guard rules** — plan and status mirroring, Checkout and plan-change guards, upgrade payment behaviour
6. **Plan-limit enforcement** — the locking function, the paths that call it, the concurrency proof
7. **State map** — dunning stages, complimentary endings and cancellations, the access granted at each, and the matching terms wording
8. **Account settings** — tax invoice fields and Customer Portal configuration, per environment
9. **Verification** — display/charge match, $0 invoice and reversal, declined upgrade, parallel claims, tax invoice

## Quality checklist

- [ ] No Stripe price id hardcoded in a migration or in application code
- [ ] `price_cents` is the editable amount; the id is written back per environment by the script
- [ ] Setup script idempotent by `lookup_key`; a changed amount creates a new Price with `transfer_lookup_key=true`
- [ ] `tax_behavior: 'inclusive'` set where prices are displayed tax-inclusive
- [ ] Permanent comps use a forever 100%-off coupon, not a far-future `trial_end`
- [ ] A comped subscription shows as active and invoices $0
- [ ] Removing the coupon demonstrably resumes billing at the next renewal
- [ ] Webhook plan locked to the comp plan while a complimentary window is trialing
- [ ] Status mirrored behind an ordering marker, never a hard-coded `past_due`; period-end tolerance allowed
- [ ] Checkout refuses already-billed customers and expires their other open sessions; Free offered only without billing history
- [ ] Plan changes read the live `discount` and `cancel_at_period_end`
- [ ] Upgrades use `error_if_incomplete` with a separate `requires_action` path; declines tested with `…0341` on an account with no proration credit
- [ ] Usage limits enforced in one locking SQL function on every path, counting pending invitations; parallel test passes
- [ ] Every complimentary mechanism gets 14 days' notice by automatic email; notices deduplicated at second precision
- [ ] Read-side entitlement holds until the scheduled job runs; every cancellation clears complimentary markers
- [ ] Suspension voids open invoices; terms say "cancelled and access suspended until payment is made"
- [ ] Invoices show the ABN as default tax ID, the GST memo and the legal-entity footer
- [ ] Customer Portal plan switching off in test and live; public details set

## Avoid

- Hardcoding a `stripe_price_id` in a migration — test and live ids differ, so it is wrong somewhere by construction
- Trying to edit a Stripe Price's amount — they are immutable; rotate the lookup key onto a new one
- Re-creating a Price on every setup run instead of finding it by `lookup_key`
- Modelling permanent access as a far-future `trial_end` — Stripe caps it at five years and the state is a lie
- Leaving a permanently comped subscription in `trialing`, where dunning and renewal logic treat it as temporary
- Copying price ids between environments to "save a step"
- Changing account settings before confirming whether the key belongs to a sandbox or the legacy Test mode
- Taking the plan from the price while a complimentary window is trialing — a bigger plan rides free until the trial ends
- Hard-coding `past_due` on `invoice.payment_failed` — it can arrive after the subscription was deleted
- Opening Checkout without checking for an existing billed subscription and other open sessions — two tabs, two subscriptions
- Testing upgrade declines with `…0002` or on an account carrying proration credit — the bad card is never charged
- Limit checks in application code, or counts that ignore pending invitations — parallel requests overshoot the cap
- Ending a Stripe free period early without notice — it charges the card immediately
- Comparing notice records against `trial_end` at millisecond precision — the email re-sends
- Leaving plan switching on in the Customer Portal — it bypasses the app's limit checks

## Example usage

> "Our plan is $29/month and the price id is hardcoded in a migration, so staging charges the wrong thing. We also need to give three foundation customers free access permanently — I tried setting `trial_end` to 2099 and Stripe refused it. Before launch, make the webhooks, Checkout, linked-user limits, free-period promotion and tax invoices safe as well."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
