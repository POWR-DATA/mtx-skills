# Example Input

## Context

A subscription app charges business accounts a monthly fee, with each plan capped at a number of linked users. Billing was wired up quickly during the beta: the Stripe price id was written straight into a migration, so the staging environment points at a live-mode price and fails. Three foundation customers were promised free access "for good" as thanks for early feedback, and public launch is a month away.

## Input provided

**Plans:** `free` (1 linked user), `standard` AUD $29.00 per month (3 linked users) and `plus` AUD $49.00 per month (10 linked users), displayed GST-inclusive. The seller is GST-registered in Australia.

**Environments:** `test` (used by local and staging) and `live`. The app currently reads a single `STRIPE_PRICE_ID` constant seeded by migration `0014_add_price.sql`.

**Problems:**

1. Staging attempts to charge against a live-mode price id and errors on checkout.
2. Marketing wants to raise `standard` to $34 next quarter; nobody is sure how to change it, since the Stripe dashboard will not let the amount be edited.
3. An attempt to comp the three foundation customers by setting `trial_end` to 1 January 2099 was rejected with `Invalid timestamp: can be no more than five years in the future`.
4. One of the three may convert to paying later, so any comp has to be reversible.
5. A beta tester with two tabs open ended up with two subscriptions.
6. A `standard` account sent five invitations in quick succession and ended up with five linked users against a cap of 3.
7. A cancelled account showed `past_due` the next morning.
8. An upgrade test with a declining card "succeeded", and the plan changed.

**Launch plans:** a promotion of 3 free months on `standard` with the card collected at sign-up; occasional admin-granted access for reviewers with no card; every payment must come with a tax invoice; the Customer Portal is on with default settings.

**Constraint:** the displayed price on the pricing page and the amount charged must never disagree — that is the thing that generates support tickets.

**Ask:** fix the source of truth, give us a price-change procedure, set up the comps properly, and make the webhooks, Checkout, limits, complimentary endings, failed payments, invoices and portal launch-safe.
