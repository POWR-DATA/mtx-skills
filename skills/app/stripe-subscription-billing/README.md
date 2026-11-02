# Stripe Subscription Billing

Run subscription billing against Stripe from a database plan catalogue — idempotent per-environment price setup, webhook mirroring, guarded Checkout and upgrades, race-safe plan limits, complimentary access and how it ends, failed-payment suspension, Australian tax invoices, and Customer Portal settings.

## What this skill does

Keeps the price editable in one place — a database row holding `price_cents` — while Stripe remains the thing that charges. A setup script finds or creates the Stripe Price and writes its id back for the current environment, so no price id is ever hardcoded into a migration that would be wrong in test or live. It then keeps the app's entitlements in step with Stripe: webhooks that survive out-of-order events, Checkout and upgrade guards that stop duplicate subscriptions and free upgrades, plan limits enforced under a row lock, permanent and time-limited complimentary access with one notice rule, a dunning-to-suspension state map, valid Australian tax invoices, and a Customer Portal that cannot bypass the app's checks.

## When to use it

- Wiring subscription plans to Stripe for the first time, or before billing goes live
- A price id is hardcoded somewhere and staging charges the wrong amount
- A price needs to change and Stripe will not let you edit the existing Price
- Someone needs permanent or time-limited complimentary access, or a comp needs reversing
- Two browser tabs created two subscriptions, or invitations raced past a plan limit
- Failed payments, cancellations and complimentary endings need defined access states
- Invoices must be valid Australian tax invoices, or prices are displayed GST-inclusive

## Example use cases

- Move a hardcoded price id out of a migration into a per-environment catalogue column
- Raise a plan's price by editing `price_cents` and letting the script rotate the lookup key
- Comp three foundation customers permanently, and run a free-period launch promotion with 14 days' notice
- Lock the webhook plan mirror during a complimentary trial and stop a late `invoice.payment_failed` overwriting a cancellation
- Enforce a linked-user cap in one locking SQL function and prove it with parallel requests
- Set the ABN, GST memo and legal-entity footer so every invoice is a tax invoice

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |
| `reference.md` | Load-on-demand excerpts — catalogue schema, setup script, webhook mirror, upgrade test cards, plan-limit function, complimentary mechanisms, dunning map, tax invoice and portal settings |

## How to use

Copy `SKILL.md` into your AI tool as an instruction or system prompt. Provide the plans and limits, environments, tax registration and complimentary-access needs, then follow the structured output. Load `reference.md` for the schema, the Stripe calls and the settings tables.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
