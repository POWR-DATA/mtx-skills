# App Skills

Skills for building and deploying multi-platform applications.

These skills cover the full delivery lifecycle for Python-based multi-platform apps: project scaffolding, backend integration, CI/CD build pipelines, cloud deployment, and asset preparation. They are designed to be applied in sequence — the output of one skill feeds naturally into the next.

## Skills

| Skill | Description | Typical next skill |
|---|---|---|
| [Flet + Supabase App Framework](flet-supabase-framework/) | Scaffold a Flet + Supabase multi-platform Python app with correct project structure and integration patterns | Flet Multi-Platform Build |
| [Flet Multi-Platform Build](flet-multiplatform-build/) | Configure Android, iOS, and web Docker build pipelines for a Flet app with CI/CD | Flet ACA Deploy |
| [Flet ACA Deploy](flet-aca-deploy/) | Deploy a Flet web app to Azure Container Apps | — |
| [App Icon Asset Generation](app-icon-asset-generation/) | Generate a consistent application icon asset set from an approved high-resolution logo | — |
| [Supabase Marketing Backend](supabase-marketing-backend/) | Supabase as the backend for a static marketing site — insert-only public forms on the anon key with RLS, a privacy-tiered page-hit beacon, reader roles, and the RLS/view leaks that bite | Excel Power Query Postgres (data) |
| [Stripe Subscription Billing](stripe-subscription-billing/) | Subscription pricing against Stripe from a database plan catalogue — per-environment price ids, idempotent price setup, permanent comped access | — |
| [Demo Seed Data](demo-seed-data/) | Demo and screenshot data that is safe to publish and repeatable to rebuild — reserved fictitious identifiers, curated content in the seed | App Store Listing / Google Play Listing |
| [Resend Email Sending](resend-email-sending/) | Resend as an application's email provider — API key and domain scoping, marketing vs transactional stream separation, Svix-signed delivery webhooks with suppression | Marketing Email Campaign (web) |

## Suggested delivery sequence

For a new Flet app targeting Android and web:

```
Flet + Supabase App Framework
    -> Flet Multi-Platform Build
        -> Flet ACA Deploy (web)
```

App Icon Asset Generation can be applied at any point once the approved logo is available — it is independent of the other skills.

## Adding a new app skill

Use the [skill template](../../contribute/templates/skill-template/) as your starting point. See [CONTRIBUTING.md](../../contribute/CONTRIBUTING.md) for submission guidance.
