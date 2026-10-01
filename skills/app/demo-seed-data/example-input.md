# Example Input

## Context

An Australian wellbeing app is submitting to both app stores next week and needs a fresh set of store screenshots. The demo account was built by hand during the beta: a practitioner profile, a few client threads with photos, and some goal entries. Several of those records have since been deleted during testing, and the person who created them has left.

## Input provided

**Screens to capture:** home dashboard, a goal thread with photo attachments, the practitioner profile, and the sharing screen. Phone and 13" tablet sizes for both stores.

**Data model:** Supabase. `profiles`, `goals`, `goal_entries` (sorted newest first in the UI), `attachments`, and auth users. The demo seed currently creates only the two auth users — everything else was hand-entered.

**Current demo data concerns:**

- The practice profile shows phone `0419 570 156` and an ABN someone made up
- The practitioner has an invented AHPRA-style registration number on the profile
- The practice name was invented without checking anything

**Recent problem:** a developer added new test goal entries last week to check a bug fix, and they now sit at the top of the thread — the curated entries the old screenshots were composed around are pushed below the fold.

**Also seen:** after running the seed reset, the browser shows `AuthApiError: Invalid Refresh Token: Refresh Token Not Found` on the next page load, and nobody is sure whether the reset failed.

**Ask:** make this a seed we can re-run before every submission, with data that is safe to publish.
