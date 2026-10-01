---
name: demo-seed-data
description: Build demo and screenshot data that is safe to publish and repeatable to rebuild — reserved fictitious identifiers, curated content encoded in the seed, recency-aware ordering, and the expected noise after a reseed
author: PowerData
version: 1.0.0
license: MIT
---

# Demo Seed Data

## Purpose

Produce the demo accounts and content used for store screenshots, walkthrough videos and sales demos as a repeatable seed rather than hand-built data — using identifiers that cannot belong to a real person or business, encoding the exact curated state the screenshots depend on, and knowing which errors after a reseed are expected rather than broken.

## When to use

Before capturing store screenshots or recording a product video, and whenever a demo environment is rebuilt. Apply at the point the first demo account is created — retrofitting safe identifiers after screenshots are published means re-capturing everything — and again whenever showcase content is added that could reorder what the screenshots show.

## Inputs expected

Partial inputs are acceptable — flag what is missing rather than inventing it.

- The screens to be captured and what must be visible in each
- The data model behind them, and which lists sort by recency
- The jurisdiction the demo data must be safe in (identifier ranges differ by country)
- Whether auth users are recreated on reseed, and who is logged in during capture

---

## Guiding principles

- **Use identifier ranges that are reserved for fiction, not ones that merely look fake.** In Australia, ACMA reserves number ranges for creative works that are never issued to a real service. A transposed digit in an invented number is the common failure — it produces a number that belongs to somebody.

  | Identifier | Safe form |
  |---|---|
  | Mobile | `0491 570 xxx` (e.g. `0491 570 156`) |
  | Landline | `(0X) 5550 xxxx` or `(0X) 7010 xxxx`, using the real state area code |
  | ABN | one that deliberately **fails** the mod-89 checksum, so it cannot be a real business |

- **Check invented names against the public registers before using them.** Search ABN Lookup and the relevant professional register for any invented person or practice name — a plausible name frequently belongs to a real business or practitioner.
- **Leave professional registration numbers blank rather than inventing them.** An invented registration number may match a real practitioner, and there is no reserved range to fall back on.
- **Make the screenshot state part of the seed, not something assembled by hand.** Encode the exact curated content — photos, threads, attachments, dates — in `seed()` and `teardown()` so every reset rebuilds the same world. Hand-built demo data cannot be reproduced after a reset, which is when it is always needed.
- **Where a UI lists by recency, ordering *is* the composition.** Pin curated items as the newest records and deliberately empty out "today", or newer showcase data added later will bury exactly the content the screenshots were composed around.
- **A reseed that recreates auth users orphans existing browser sessions.** The next page load surfaces `AuthApiError: Invalid Refresh Token: Refresh Token Not Found`. This is benign and expected: the client falls back to signed-out, and clearing site data or logging in fresh resolves it. Treat it as normal post-reseed noise, not a defect to investigate.
- **Capture from the seeded demo account, never a real one.** Real accounts carry live codes, real contacts and real billing state into anything published — and none of it is reproducible later.

## Process

1. **List the captures** — every screen to be shot or recorded, and what must be visible in each.
2. **Choose safe identifiers** from the reserved ranges for the relevant jurisdiction; check invented names against the public registers; leave registration numbers blank.
3. **Write the curated content into `seed()`** — the specific photos, threads and attachments each capture depends on.
4. **Control the ordering** — pin curated items as the newest records, and clear anything that would occupy "today".
5. **Write `teardown()`** so a reset is clean and the next seed is identical.
6. **Reseed, then log in fresh** — expect the refresh-token error once, clear site data, continue.
7. **Capture**, then re-run the full seed → capture cycle once to prove it reproduces.

## Output format

1. **Capture list** — screens, required visible content, device/size
2. **Identifier set** — the reserved numbers, ABN, names used, and the register checks performed
3. **Seed contents** — curated records per screen, with their intended ordering
4. **Ordering strategy** — what is pinned as newest, what is emptied out
5. **Reseed notes** — expected errors and the recovery step
6. **Reproduction check** — confirmation that a fresh seed rebuilds the same screenshots

## Quality checklist

- [ ] Every phone number sits in a reserved fictitious range, digit-checked against it
- [ ] ABN deliberately fails the checksum; invented names checked against ABN Lookup and professional registers
- [ ] Professional registration numbers left blank, not invented
- [ ] All screenshot content is created by `seed()` — nothing hand-built
- [ ] Curated items pinned as newest where a list sorts by recency; "today" emptied where needed
- [ ] `teardown()` leaves a clean state so the next seed is identical
- [ ] Captures taken from the demo account only
- [ ] Seed → capture cycle re-run once and the screenshots reproduce

## Avoid

- Inventing a phone number "that looks fake" — transpose a digit out of the reserved range and it belongs to someone
- An ABN that passes the checksum, which means it is or could become a real business
- Inventing professional registration numbers
- Hand-building demo content that a reset destroys and nobody can rebuild
- Adding showcase data later without checking it does not bury the curated items in a recency-sorted list
- Reporting the post-reseed refresh-token error as a bug
- Capturing screenshots or video from a real account

## Example usage

> "We're submitting to both app stores next week and need screenshots. The demo account was built by hand months ago and half of it has been deleted since. I also need to be sure the phone number and ABN on the practice profile can't belong to anyone real. Set up a seed we can re-run every time."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
