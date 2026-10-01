# Stripe Subscription Billing

Run subscription pricing against Stripe from a database plan catalogue — per-environment price ids, idempotent price setup, and modelling permanent comped access without a sentinel trial date.

## What this skill does

Keeps the price editable in one place — a database row holding `price_cents` — while Stripe remains the thing that charges. A setup script finds or creates the Stripe Price and writes its id back for the current environment, so no price id is ever hardcoded into a migration that would be wrong in test or live. It also covers rotating an immutable Price by lookup key, and modelling permanent free access as a forever 100%-off coupon rather than a far-future trial date Stripe will not accept.

## When to use it

- Wiring subscription plans to Stripe for the first time
- A price id is hardcoded somewhere and staging charges the wrong amount
- A price needs to change and Stripe will not let you edit the existing Price
- Someone needs permanent free access, or a comp needs reversing
- Prices are displayed tax-inclusive (GST) and must match what is charged

## Example use cases

- Move a hardcoded price id out of a migration into a per-environment catalogue column
- Write an idempotent setup script keyed on `lookup_key` that runs safely in both environments
- Raise a plan's price by editing `price_cents` and letting the script rotate the lookup key
- Comp three foundation customers permanently, and reverse one of them later

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |
| `reference.md` | Load-on-demand excerpts — catalogue schema, idempotent setup script, permanent comp calls |

## How to use

Copy `SKILL.md` into your AI tool as an instruction or system prompt. Provide the plans, environments and tax-display requirement, then follow the structured output. Load `reference.md` for the schema and the Stripe calls.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
