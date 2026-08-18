# Branded Link QR Service

Build a permanent branded short-link and QR code service on a static host — 302 indirection, a source-controlled link registry, generated redirect config with CI drift checks, and validated QR generation.

## What this skill does

Guides an AI through building a `go.<domain>` short-link layer where every printed QR encodes a permanent branded URL that 302-redirects to a changeable destination. It covers the link registry, the script that generates the host's redirect config (with a CI `--check` mode), deterministic QR generation with `segno`, and independent decode validation that proves the QR encodes the link — not the destination.

## When to use it

- Printing QR codes on business cards, flyers, signage, or labels that will outlive the page they point at
- Giving each employee a permanent business-card QR (`/card/<person-slug>`)
- A printed QR already points somewhere that has to move
- Replacing hand-edited redirects with a registry that generates the hosting config
- Hosting the redirect layer on Azure Static Web Apps or another static host with route-based redirects

## Example use cases

- Set up `go.example.com` on an Azure SWA and generate 302 routes from `config/branded-links.json`
- Produce SVG + PNG QR codes for four staff business cards and prove each decodes to its branded URL
- Add a CI step that fails when the committed redirect config drifts from the registry
- Repoint a flyer's QR from an old landing page to a new one without reprinting

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |
| `reference.md` | Load-on-demand excerpts — registry schema, generator/check sketch, SWA routes, segno + decode snippets, CI step |

## How to use

Copy the content of `SKILL.md` into your AI tool as an instruction or system prompt. Provide the link host, the list of links and owners, and the QR formats you need, then review the structured output. Load `reference.md` when you want the concrete registry, generator, and validation snippets.

Pairs with the [Static Website Hosting](../static-website-hosting/) skill for provisioning the `go.<domain>` site itself.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
