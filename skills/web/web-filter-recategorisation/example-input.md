# Example Input

## Context

A health-services site launched three weeks ago on Azure Static Web Apps at `www.example.com.au`, with a short-link host `go.example.com.au` in front of a redirect service. Two clinicians have reported that the site will not open on their hospital networks, and a third says it works on her phone but not on the desk machine. Launch communications go out to a list dominated by hospital and clinic staff next week.

## Input provided

**Domains:** `www.example.com.au` (main site), `go.example.com.au` (redirects only, no content)

**Host default hostname:** `<swa-default-hostname>.azurestaticapps.net` — still live and reachable

**Reports from the blocking network:**

- Browser shows a generic "can't reach this page"
- `curl https://www.example.com.au` → `curl: (35) Recv failure: Connection was reset`
- The staff member recalls the network uses Zscaler

**Also observed:** the agent session running on that machine cannot fetch the production site to verify a deploy, and reported it as a site failure.

**Site description, honestly:** patient-facing health information and practitioner sign-up for a wellbeing app.

**Ask:** work out whether this is us or them, and get it unblocked before the launch emails go out.
