# Cloudflare R2 Static Data

Publish large versioned static datasets on Cloudflare R2 — bulk sync by key prefix, immutable caching on versioned keys, a custom domain instead of r2.dev, and completeness checks before a release points at the data.

## What this skill does

Sets up the upload and release process for a large precomputed dataset — typically many thousands to millions of small JSON shards — that an app reads from R2. It replaces per-file copies with per-prefix `aws s3 sync`, puts the dataset version in every key so objects can be cached as immutable, serves them from a custom domain with a bucket-scoped token, and gates each release on proof that every prefix the app reads is actually on the bucket.

## When to use it

- A per-file upload loop is estimating hours or days
- You are designing the key layout for a new static dataset
- The app reads from the `r2.dev` URL in production
- A release pointed at data that turned out to be incomplete
- You want long-lived caching without risking stale data

## Example use cases

- Upload over a million per-street lookup shards in one evening with parallel per-prefix syncs
- Move a dataset from `r2.dev` to a custom domain with a token limited to one bucket
- Add a completeness gate so the manifest is written only after every prefix checks out
- Publish a revised dataset as `v2` while `v1` stays cached and untouched for the current release

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |
| `reference.md` | Load-on-demand excerpts — token scope and CLI profile, per-prefix sync command, completeness gate with manifest-last, header and cache verification |

## How to use

Copy `SKILL.md` into your AI tool as an instruction or system prompt. Describe the dataset, its prefixes, which of them the app reads, and how releases choose a version, then work through the structured output. Load `reference.md` for the commands. Related skills: `windows-cli-gotchas` for running the AWS CLI from PowerShell, and `static-website-config-and-csp` if the reading site has a Content Security Policy.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
