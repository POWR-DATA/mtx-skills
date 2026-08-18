# Example Input

## Context

GardenTrack is a small subscription app (mobile + web portal) about to launch paid plans in three weeks. Payments will run through Stripe; the founder intends anniversary billing and expects to run a launch discount. The company's marketing site is a static site on Azure Static Web Apps, which will host `/terms` and `/privacy`.

## Input provided

**Drafts:** a Terms of Service Word document (mentions "$12 per month billed on the 1st") and a Privacy Policy draft; both need review by the founder, the insurance broker and, for the liability clause, the insurer

**Insurance:** Certificate of Currency for a professional indemnity + public liability policy; "Insured Business" reads "data and analytics consulting"; a cyber-liability sub-limit is listed; the broker has not yet been asked about contractual liability

**App state:** users table has `terms_accepted boolean`; onboarding shows a checkbox with no link to the Terms; checkout shows the price but no terms; there is no way to find the Terms after onboarding

**Constraints:** pages must not be indexed or linked until publication; the acceptance flow should ship in the next app build but stay dark until the pages go live

**Ask:** how to publish the drafts for review, the billing and liability wording approach, what to ask the broker, and the acceptance-flow spec.
