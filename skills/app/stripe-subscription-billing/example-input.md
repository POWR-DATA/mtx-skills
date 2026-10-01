# Example Input

## Context

A subscription app charges practitioners a monthly fee. Billing was wired up quickly during the beta: the Stripe price id was written straight into a migration, so the staging environment points at a live-mode price and fails. Three foundation customers were promised free access "for good" as thanks for early feedback.

## Input provided

**Plan:** one tier, `standard`, AUD $29.00 per month, displayed GST-inclusive.

**Environments:** `test` (used by local and staging) and `live`. The app currently reads a single `STRIPE_PRICE_ID` constant seeded by migration `0014_add_price.sql`.

**Problems:**

1. Staging attempts to charge against a live-mode price id and errors on checkout.
2. Marketing wants to raise the price to $34 next quarter; nobody is sure how to change it, since the Stripe dashboard will not let the amount be edited.
3. An attempt to comp the three foundation customers by setting `trial_end` to 1 January 2099 was rejected with `Invalid timestamp: can be no more than five years in the future`.
4. One of the three may convert to paying later, so any comp has to be reversible.

**Constraint:** the displayed price on the pricing page and the amount charged must never disagree — that is the thing that generates support tickets.

**Ask:** fix the source of truth, give us a price-change procedure, and set up the comps properly.
