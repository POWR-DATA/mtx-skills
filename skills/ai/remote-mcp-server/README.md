# Remote MCP Server

Run a public remote MCP server for AI connector directories — a custom-domain proxy in front of the server, domain verification, tool annotations, MCP Apps widgets, output sanitisation and spoof-proof rate limits.

## What this skill does

Takes an MCP server that already works at a platform URL and prepares it for public use and connector-directory review. That covers a Cloudflare Worker on your own domain in front of a Supabase edge function, and OpenAI's root-level domain verification served from a secret. It also covers complete tool annotations, an MCP Apps widget that starts in the right order, one sanitiser across every payload the host receives, and rate limits that a forged header cannot get around.

## When to use it

- Submitting an MCP server to an AI connector directory (OpenAI's, Claude's)
- Moving a server from a platform function URL to a domain the service owns
- Directory review flags tools for a missing `title` or missing hints
- A tool must withhold street numbers, precise addresses or similar detail
- Adding an in-chat MCP Apps widget to a tool
- Rate-limiting a public, unauthenticated MCP endpoint

## Example use cases

- Put a Worker on `mcp.example.com` in front of a Supabase edge function so it forwards `/mcp` only and drops caller credentials
- Serve `/.well-known/openai-apps-challenge` from a Worker secret after the path kept returning 404
- Find street numbers that still reach the host through `structuredContent` and the widget `_meta` after the text was sanitised, and close the "No.88" gap
- Replace a rate-limit key read from `X-Forwarded-For`, which any caller could change on every request

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |
| `reference.md` | Load-on-demand excerpts: Worker forwarding and verification route, tool annotation shape, three-payload sanitiser, rate-limit key logic |

## How to use

Copy `SKILL.md` into your AI tool as an instruction or system prompt. Describe where the server runs, your domain, the tools and what they must withhold, then work through the structured output. Load `reference.md` for the Worker, annotation, sanitiser and rate-limit excerpts. Use it with `supabase-edge-functions` for the function itself, including `verify_jwt`, deploy flags and reading the client IP.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
