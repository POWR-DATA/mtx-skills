# Example Input

## Context

A small consultancy, Northwind Analytics, is about to print business cards for four staff and an A5 flyer for a new training course. The website is a static site on Azure Static Web Apps (`www.example.com`), deployed from a GitHub repo via GitHub Actions. They previously printed a batch of cards with a QR that went straight to a `/contact.html` page, which has since moved — so this time every QR must be repointable without a reprint.

## Input provided

**Link host:** `go.example.com` — a new subdomain; happy to run it as a second Static Web App from a `go/` subfolder of the same repo

**Links needed:**

| Path | Current destination | Owner |
|---|---|---|
| `/card/jane-citizen` | `https://www.example.com/team/jane-citizen.vcf` | Jane |
| `/card/sam-lee` | `https://www.example.com/team/sam-lee.vcf` | Sam |
| `/card/priya-nair` | `https://www.example.com/team/priya-nair.vcf` | Priya |
| `/card/tom-okafor` | `https://www.example.com/team/tom-okafor.vcf` | Tom |
| `/training` | `https://www.example.com/courses/data-foundations` | Marketing |

**Legacy route to keep working:** `/card` (from the earlier batch of printed cards) — should land on the team page

**QR formats:** SVG for the print house, PNG (1024 px) for email signatures

**Registry location:** `config/branded-links.json` in the repo; generator under `scripts/`

**CI:** GitHub Actions already runs on push and PR — add a check that fails if the redirect config is stale

**Constraint:** marketing wants UTM tracking on the training link — fine to attach it on the destination side
