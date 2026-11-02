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

## Webhook mirror

```python
# customer.subscription.* — plan from the price, except during a complimentary free window
plan = plan_for_price(price_id)
if sub.status == "trialing" and row.comp_plan:
    plan = row.comp_plan                     # locked: a bigger plan picked now is not free until trial end

# invoice.payment_failed can arrive AFTER customer.subscription.deleted
live = stripe.Subscription.retrieve(sub_id)
if event.created >= row.status_marker:      # ordering marker: an older event never overwrites newer state
    db.update(row.id, {"status": live.status, "status_marker": event.created})   # not a hard-coded 'past_due'
```

```sql
-- entitlement read (illustrative)
(status in ('active', 'trialing') and current_period_end + interval '<n> days' > now())  -- renewal → webhook gap
or complimentary_until is not null   -- stays entitled until the scheduled job moves it to Free; do not compare with now()
```

## Upgrades and test cards

```python
stripe.Subscription.modify(
    sub_id,
    items=[{"id": item_id, "price": new_price_id}],
    payment_behavior="error_if_incomplete",   # declined card → refused, plan unchanged
)
# a card needing 3D Secure is refused the same way — branch on requires_action, do not report it as a decline
```

| Test card | Behaviour | Use for |
|---|---|---|
| `4000 0000 0000 0341` | attaches successfully, then fails every charge | declined upgrades and failed renewals |
| `4000 0000 0000 0002` | fails at attach | not upgrade tests — it never reaches the charge |

Run decline tests on an account with no proration credit. A prior downgrade's credit netted the next upgrade invoice to $0, so the bad card was never charged and the test passed for the wrong reason.

## Plan-limit function

```sql
create or replace function claim_seat(p_account uuid, p_invitee text) returns boolean
language plpgsql as $$
declare v_limit int; v_used int;
begin
  select seat_limit into v_limit from subscriptions
   where account_id = p_account for update;              -- serialises every claim for this account
  select (select count(*) from connections where account_id = p_account)
       + (select count(*) from invitations where account_id = p_account and status = 'pending')
    into v_used;                                           -- pending invitations count too
  if v_used >= v_limit then return false; end if;
  insert into invitations (account_id, invitee, status) values (p_account, p_invitee, 'pending');
  return true;
end $$;
```

Call it from every path that adds usage — invite create, invite accept, over-limit refresh. Prove it by firing 12 claims in parallel against a cap of 3: exactly 3 must win.

## Complimentary access

**Permanent** — a far-future `trial_end` is rejected, because Stripe caps it at five years:

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

**Time-limited** — three mechanisms, each ending differently:

| Mechanism | Card on file | At the end | Ended early |
|---|---|---|---|
| Stripe free period, card collected at Checkout | yes | first charge on the date Checkout showed | charges the card immediately |
| 100%-off coupon for N months on a paying customer | yes | full price from the next billing date once removed | remove the coupon |
| Admin grant, no Stripe subscription | no | scheduled job moves the account to the Free plan | — |

All three: 14 days' notice by automatic email. Key the "notice sent" record on the end date truncated to whole seconds — Stripe rewrites `trial_end` to seconds, so a millisecond stamp re-sends the email.

| Transition | Rule |
|---|---|
| Complimentary window ends (scheduled job) | read side keeps the row entitled until the job moves it, or users lose access for up to one job interval |
| Card-backed free window cancelled before its first charge | returns to Free |
| Any cancellation | clears the complimentary markers |
| Webhook during a complimentary trial | plan stays locked to the comp plan |

## Failed payments

| Stage | Stripe | App |
|---|---|---|
| Renewal fails | retries for about two weeks (8 attempts) | full access, overdue banner |
| Retries exhausted | cancels the subscription | suspended behind a locked "overdue payment" screen with a restart button; open invoices voided |
| Terms and FAQs | — | "cancelled and access suspended until payment is made", plus the effect on linked end users |

## Australian tax invoices

| Setting | Value |
|---|---|
| Account default tax ID | AU ABN `<your-abn>` — otherwise it is not printed in the invoice header |
| Default invoice memo | `Tax invoice. Total price includes GST.` |
| Default invoice footer | `<legal entity name> · ABN <your-abn>` |

Under A$1,000 the GST-inclusive statement is the permitted form. Invoices issued before the change keep their old layout. Stripe sandboxes and the legacy Test mode are separate environments — confirm which account the test key belongs to before changing these.

## Customer Portal

| Setting | Value |
|---|---|
| Plan switching | off, in test and live — a switch there bypasses the app's limit checks |
| Public business details | brand name, support email and URL, privacy and terms URLs — the "Return to …" link and headings use the public business name |
