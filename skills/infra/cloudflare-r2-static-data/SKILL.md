---
name: cloudflare-r2-static-data
description: Publish large versioned static datasets on Cloudflare R2 — bulk sync by key prefix, immutable caching on versioned keys, a custom domain instead of r2.dev, and completeness checks before a release points at the data
author: PowerData
version: 1.0.0
license: MIT
---

# Cloudflare R2 Static Data

## Purpose

Publish a large precomputed dataset — often hundreds of thousands to millions of small JSON shards — to Cloudflare R2 so an app can read it cheaply and fast: uploaded in hours rather than days, cached as immutable under a versioned key, served from a custom domain, and proven complete before any release points at it.

## When to use

When an app reads precomputed static data (per-street, per-postcode or per-tile lookups, for example) that is too big to ship with the app and does not need a database. Apply when designing the key layout, before the first bulk upload, and before every release that switches the app to a new dataset version.

## Inputs expected

Partial inputs are acceptable — state assumptions for the rest.

- The dataset: number of files, typical size, content type, and how it is split into key prefixes
- Which prefixes the app reads, and what the app does when a key is missing
- How releases select a dataset version (config value, manifest, build-time constant)
- Whether a domain is already on the same Cloudflare account

The upload uses the S3-compatible API with the AWS CLI. For running it from PowerShell, see `windows-cli-gotchas`; if the reading site has a Content Security Policy, add the data domain to `connect-src` (see `static-website-config-and-csp`).

---

## Guiding principles

- **Sync by prefix; never copy file by file.** One `aws s3 cp` per file over millions of small files would take more than a day. `aws s3 sync` per key prefix uploaded about 60k shards the same evening. Run separate prefixes in parallel if you like, but never two syncs over the same prefix at once.
- **Set the headers at upload, the same for every object.** Pass the same `Content-Type` and `Cache-Control` on every sync, so no shard is served with a default type or uncached.
- **Put the dataset version in the key** — `<dataset>/v1/...` — and serve with `Cache-Control: public, max-age=2592000, immutable`. The versioned key is what makes the immutable cache safe: a changed dataset is a new version under a new prefix, never an overwrite of a cached key.
- **Serve through a public custom domain on the bucket, not the `r2.dev` URL.** `r2.dev` is rate-limited and not meant for production traffic.
- **Scope the upload credential to the one bucket.** Use an S3 API token with Object Read & Write on that bucket only — not an account-wide or admin token.
- **A manifest is a claim, not evidence.** A `meta.json` at the version root said the dataset was complete while a whole prefix was missing; the app had no fallback, so lookups 404'd for about 13 minutes after deploy. Check that every prefix the app reads exists on the bucket before pointing a release at it, or write the manifest last — ideally both.

## Process

1. **Fix the key layout** — `<dataset>/v<n>/<prefix>/<shard>.json`, and list every prefix the app reads.
2. **Create the bucket, connect the custom domain** (a zone on the same Cloudflare account), and leave `r2.dev` access off for production.
3. **Create the S3 API token** — Object Read & Write, applied to this bucket only — and configure the AWS CLI profile with the R2 endpoint and region `auto`.
4. **Generate the dataset locally** into a tree that mirrors the keys.
5. **Sync each prefix** with `--content-type` and `--cache-control` set; parallelise across prefixes, never within one (see [`reference.md`](reference.md)).
6. **Check completeness** — every prefix the app reads exists on the bucket, and remote object counts match local counts.
7. **Write the manifest last**, only after the checks pass.
8. **Point the release at the version** and deploy.
9. **Verify through the custom domain** — a sample key from every prefix returns 200 with the expected headers, and the edge cache status is what you intended (JSON needs a Cache Rule to be cached at the edge).
10. **For the next dataset**, publish under `v<n+1>`; leave the previous version in place until no release reads it.

## Output format

1. **Key layout** — version scheme, prefixes, which the app reads
2. **Bucket and access** — custom domain, `r2.dev` state, token scope
3. **Upload plan** — sync commands per prefix, headers, concurrency rule
4. **Release gate** — completeness checks, manifest-last order, the switch to the new version
5. **Verification** — sample requests per prefix through the custom domain, headers and cache status

## Quality checklist

- [ ] Every key carries the dataset version; no versioned key is ever overwritten
- [ ] Upload uses `aws s3 sync` per prefix, never a per-file `cp` loop, and no prefix has two syncs at once
- [ ] Every object has the same `Content-Type` and `Cache-Control: public, max-age=2592000, immutable`
- [ ] Reads go through a custom domain, not `r2.dev`
- [ ] The S3 API token is Object Read & Write on this bucket only
- [ ] Every prefix the app reads was confirmed on the bucket before the release switched
- [ ] The manifest was written after the data, not before

## Avoid

- Looping `aws s3 cp` over millions of files
- Two concurrent syncs over the same prefix
- Uploading without explicit `Content-Type` and `Cache-Control`
- `immutable` caching on keys that are not versioned, or re-uploading changed data under an existing version
- Pointing production at the rate-limited `r2.dev` URL
- An account-wide or admin token for a job that writes one bucket
- Writing `meta.json` first, or trusting it as proof the data is there
- Switching a release to a new version before every prefix it reads has been checked

## Example usage

> "We've got about 1.2 million per-street JSON files for GardenTrack's planting-zone lookup. A loop of `aws s3 cp` is estimating 30 hours, the app currently reads from the `r2.dev` URL, and on the last release one state's prefix was missing even though `meta.json` said the build was complete. Set up the upload and release process properly."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
