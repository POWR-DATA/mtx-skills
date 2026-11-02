# Example Input

## Context

GardenTrack shows a planting-zone and frost-risk panel for the user's street. The data is precomputed nightly into one small JSON file per street — about 1.2 million files, 1–4 KB each — split by state: `act`, `nsw`, `nt`, `qld`, `sa`, `tas`, `vic`, `wa`. The web app fetches `<street-id>.json` directly in the browser. The site has a Content Security Policy.

## Input provided

**Current set-up:**

- Bucket `<bucket>` on R2; the app reads from the bucket's `r2.dev` URL
- Keys are `streets/<state>/<street-id>.json` — no version in the path
- Uploads use a PowerShell loop calling `aws s3 cp` once per file, with an account-level API token
- A `meta.json` at `streets/` lists the build date and `"complete": true`; the app reads it to decide whether to enable the panel

**What went wrong:**

1. The latest full upload was estimating about 30 hours.
2. On the last release, `streets/vic/` was missing entirely, but `meta.json` had already been uploaded saying complete. Victorian lookups returned 404 for about 13 minutes until someone noticed and re-ran the upload.
3. Objects have no `Cache-Control`, so every page view goes back to the bucket.

**Constraints:** a revised dataset is published roughly quarterly; the domain is already on the same Cloudflare account.

**Ask:** a key layout, upload process and release gate we can trust.
