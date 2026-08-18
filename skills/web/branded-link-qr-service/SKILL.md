---
name: branded-link-qr-service
description: Build a permanent branded short-link and QR code service on a static host — 302 indirection, a source-controlled link registry, generated redirect config with CI drift checks, and validated QR generation
author: PowerData
version: 1.0.0
license: MIT
---

# Branded Link QR Service

## Purpose

Design and operate a branded short-link + QR service where every printed QR encodes a permanent `go.<domain>/<path>` URL that 302-redirects to a changeable destination. The output is a source-controlled link registry, a generated redirect config with a CI drift check, deterministic QR artefacts, and a validation report proving each QR encodes the permanent link — not the destination.

## When to use

Apply **before anything is printed** — business cards, flyers, signage, product labels, event collateral — whenever a QR or short URL will outlive the page it currently points at. Also use when:

- Adding per-person QR codes (employee business cards) that must survive staff and URL changes
- A printed QR already points at a destination that has to move
- Introducing a link registry so redirects stop being hand-edited in hosting config
- Hosting the redirect layer on a static host such as Azure Static Web Apps (`staticwebapp.config.json` routes)

## Inputs expected

Partial inputs are fine — infer sensible defaults and state them.

- The branded link host (default: a `go.<domain>` subdomain) and the static host it runs on
- The list of links: slug/path → current destination, plus who owns each
- Whether per-person routes are needed (`/card/<person-slug>`) and any existing generic routes to keep as aliases
- QR output formats required (SVG for print, PNG for screens) and any styling constraints
- Where the registry and generator should live in the repo (default: `config/branded-links.json`, `scripts/`)

---

## Guiding principles

- **Indirection is the whole point — never encode the destination in the QR.** The printed QR encodes a permanent `go.<domain>/<path>` URL that 302-redirects to a CHANGEABLE destination. Never use 301 — the destination must stay movable without reprinting; a cached 301 makes the printed link permanent in the worst way.
- **A source-controlled registry is the single source of truth.** Keep `config/branded-links.json` (or equivalent) as the only place a link is defined, generate the deployed redirect config from it with a script, and never hand-edit the generated routes.
- **The generator needs a CI `--check` mode.** `--check` rebuilds the config in memory and compares it semantically (CRLF-safe — parse, don't diff bytes) against the committed file, so the pipeline fails if the generated config drifts from the registry.
- **Printed routes are immutable contracts.** Use a scalable per-person convention `/card/<person-slug>` for employee business-card QRs, and keep any earlier generic `/card` as a permanent 302 compatibility alias — once cards are printed, a route can only be added to, never removed or renamed.
- **Generate QR codes deterministically with `segno`.** The pure-Python `segno` library (`segno.make_qr(url, error='m')`) is dependency-free and reproducible; its `boost_error` (on by default) raises the error-correction level as high as fits WITHOUT increasing the symbol version — free robustness at the same module density.
- **Always independently decode the generated QR.** Decode with `pyzbar` or OpenCV and assert it decodes to EXACTLY the branded URL; then assert the redirect destination string appears in neither the SVG nor the PNG — proving the QR encodes the permanent link, not the mutable destination.
- **Encode bare paths.** A static `redirect` route on Azure SWA does not forward the query string, so put any UTM/tracking on the destination side of the registry, never in the printed URL.
- **Verify the live 302 before printing.** `curl -I https://go.<domain>/<path>` must return `302` with the registry destination in `Location` — a QR is only ready to print once the redirect is live and decoded.

## Process

1. **Choose the link host** — a `go.<domain>` subdomain, deployed as its own static site (on Azure SWA, a subfolder SWA with its own deploy token; see the `static-website-hosting` skill).
2. **Define the route convention** — `/card/<person-slug>` for people, short nouns for campaigns; list any legacy generic routes (`/card`) to retain as 302 aliases.
3. **Create the registry** — one entry per link: `path`, `destination`, `status: 302`, `owner`, `notes`, and `aliases` where a legacy path must keep working.
4. **Write the generator** — reads the registry, emits the host's redirect config (e.g. `staticwebapp.config.json` `routes` with `redirect` + `statusCode: 302`); supports `--check` for CI.
5. **Wire the CI check** — run the generator in `--check` mode on every push/PR; fail on drift.
6. **Generate QR artefacts** — `segno.make_qr(url, error='m')` per link, saved as SVG (print) and PNG (screen), file-named by slug.
7. **Validate** — decode each artefact and assert exact-URL match; grep the SVG/PNG for the destination string and assert absence; record results.
8. **Deploy and verify live** — confirm `302` + correct `Location` for every path, including aliases.
9. **Operate** — to move a destination, edit the registry, regenerate, deploy. Never touch a printed path.

## Output format

1. **Route convention and registry schema** — path pattern, alias policy, registry fields
2. **Registry file** — the complete `config/branded-links.json`
3. **Generator script** — build + `--check` behaviour, and the CI step that runs it
4. **Generated redirect config** — the emitted routes (302, no 301)
5. **QR artefacts** — per link: filename, format, EC level, symbol version
6. **Validation report** — decode result per artefact, destination-absence check, live 302 check
7. **Operating notes** — how to change a destination; what must never change

## Quality checklist

- [ ] Every printed QR encodes `go.<domain>/<path>`, never a destination
- [ ] All redirects are 302 — no 301 anywhere in the generated config
- [ ] Registry is the only source; generated config is never hand-edited
- [ ] Generator `--check` runs in CI and compares semantically (CRLF-safe)
- [ ] Per-person routes follow `/card/<person-slug>`; legacy generic routes kept as 302 aliases
- [ ] QR generated with `segno` (`error='m'`, `boost_error` left on) — deterministic and reproducible
- [ ] Each artefact decoded independently and asserted equal to the exact branded URL
- [ ] Destination string absent from every SVG and PNG
- [ ] Printed URLs are bare paths (no query strings)
- [ ] Live `302` + `Location` verified for every path and alias before print sign-off

## Avoid

- Encoding the destination URL directly in a QR — it can never be changed once printed
- Using 301 for branded links — browsers and crawlers cache it, freezing the destination
- Hand-editing the deployed redirect config — the registry must generate it, and CI must prove it did
- Byte-diffing generated config in `--check` — CRLF differences cause false failures; parse and compare
- Renaming or removing a route that has been printed — add aliases instead
- Trusting the generator without decoding the artefact — verify with `pyzbar`/OpenCV every time
- Putting UTM/query parameters in the printed URL — a static redirect drops them; attach them to the destination
- Printing before the live redirect returns `302` with the right `Location`

## Example usage

> "We're printing business cards for four staff and a flyer for a product page. I want each QR to go to a permanent `go.example.com` link I can repoint later, hosted on our Azure Static Web App, with the links kept in a JSON file and CI checking the redirect config. Generate the QRs and prove they encode the short link, not the destination."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
