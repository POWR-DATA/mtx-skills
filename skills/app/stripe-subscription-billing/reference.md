# Stripe Subscription Billing — Reference

Load-on-demand excerpts for [`SKILL.md`](SKILL.md). Illustrative — load-bearing lines only; replace `<...>` placeholders.

---

## Plan catalogue

```sql
create table if not exists plans (
  code                text primary key,              -- 'standard'
  price_cents         integer not null,              -- the editable source of truth
  currency            text not null default 'aud',
  interval            text not null default 'month',
  lookup_key          text not null unique,          -- 'standard_monthly'
  stripe_price_id_test text,                         -- written back per environment
  stripe_price_id_live text
);
```

Never write a `stripe_price_id` in a migration — test and live ids differ, so the migration is wrong in one environment by construction.

## Idempotent setup script

```python
existing = stripe.Price.search(query=f"lookup_key:'{plan.lookup_key}'").data

if existing and matches(existing[0], plan):          # amount + currency + interval all equal
    price = existing[0]                              # reuse; nothing to do
else:
    price = stripe.Price.create(
        unit_amount=plan.price_cents,
        currency=plan.currency,
        recurring={"interval": plan.interval},
        product=plan.stripe_product_id,
        lookup_key=plan.lookup_key,
        transfer_lookup_key=bool(existing),           # rotate the key onto the new Price
        tax_behavior="inclusive",                     # GST-inclusive display
    )

db.update(plan.code, {f"stripe_price_id_{env}": price.id})   # write back for THIS environment
```

The fresh-create path is the one exercised in practice; verify the reuse and rotate branches on first real price change.

## Permanent comp

A far-future `trial_end` is rejected — Stripe caps it at five years:

```text
Invalid timestamp: can be no more than five years in the future
```

Instead, end the trial now and attach a forever 100%-off coupon:

```python
coupon = stripe.Coupon.create(percent_off=100, duration="forever", name="Foundation comp")

stripe.Subscription.modify(
    sub_id,
    trial_end="now",
    proration_behavior="none",
    coupon=coupon.id,
)
```

The subscription reports `active` (not `trialing`), every invoice totals $0, and `stripe.Subscription.delete_discount(sub_id)` resumes normal billing at the next renewal.
