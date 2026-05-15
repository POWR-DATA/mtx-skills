# Website SEO and Indexing

Prepare a static website for search engine indexing and submit it to Google Search Console.

## What this skill does

This skill guides an AI through the complete technical SEO setup for a static website: adding canonical URL tags to every page, writing `sitemap.xml` and `robots.txt`, verifying static files are served with correct content types, and setting up a Google Search Console Domain property with DNS TXT verification and sitemap submission. It does not cover content strategy or keyword research — only the technical layer required for correct crawling and indexing.

## When to use it

- Launching a new static website and want it indexed in Google
- Auditing an existing site for missing canonical tags, sitemap, or robots.txt
- Setting up Google Search Console for the first time on a domain
- Verifying that `sitemap.xml` is served correctly (not as HTML through a SPA fallback)
- Reviewing per-page meta titles and descriptions for completeness

## Example use cases

- Add canonical tags and a sitemap to a two-page HTML website
- Set up a Google Search Console Domain property with DNS verification
- Check whether a static site's `sitemap.xml` is actually being served as XML
- Audit a newly deployed site for all technical SEO requirements before launch

## Files in this folder

| File | Required | Description |
|---|---|---|
| `SKILL.md` | Yes | Full skill definition |
| `README.md` | Yes | Short navigation guide for this skill (this file) |
| `example-input.md` | Optional | Example input — include when it helps users frame their request |
| `example-output.md` | Optional | Example output — include when it sets a useful quality bar or the output is a concrete artefact |

## How to use

Copy the content of `SKILL.md` into your AI tool as an instruction or system prompt. Provide the expected inputs, then review the structured output.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [PowerData Skills](https://github.com/POWR-DATA/skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
