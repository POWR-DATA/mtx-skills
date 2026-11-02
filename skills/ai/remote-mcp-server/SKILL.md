---
name: remote-mcp-server
description: Run a public remote MCP server for AI connector directories — a custom-domain proxy in front of the server, domain verification, tool annotations, MCP Apps widgets, output sanitisation and spoof-proof rate limits
author: PowerData
version: 1.0.0
license: MIT
---

# Remote MCP Server

## Purpose

Run a remote MCP server that the public and connector-directory reviewers can rely on: served on a domain you own through a thin proxy, with verified ownership, every tool fully annotated, an in-chat widget that starts reliably, sanitised output on every channel the host receives, and rate limits keyed on an address the caller cannot forge.

## When to use

When an MCP server that already works at a platform URL is being opened to the public or submitted to an AI connector directory (OpenAI's, Claude's). Apply before submission, because review checks the domain, its verification and the tool annotations. Apply again whenever a tool result gains a field, a widget or a data source that carries detail the server promises to withhold. The worked case is a Supabase edge function behind a Cloudflare Worker; the rules carry over to other hosts and proxies.

## Inputs expected

Partial inputs are fine. State assumptions for the rest.

- Where the server runs today (e.g. a Supabase edge function URL) and its transport path (`/mcp`)
- The domain you control, and where its DNS is managed
- The directories you are submitting to, and their verification requirements
- The tool list: what each tool reads or changes, and whether it reaches beyond your own data
- Fields the server must withhold (street numbers, precise addresses) and every payload they appear in
- Any widget the server ships, and the library it depends on
- Current rate-limit keys and budgets

---

## Guiding principles

- **Own the domain and keep the server where it is.** Directories expect the MCP endpoint on a domain the service owns, not a platform function URL. Keep the server as a Supabase edge function and put a Cloudflare Worker on a custom domain in front of it. The Worker forwards `/mcp` and drops the caller's `Authorization`, `apikey` and `Cookie` headers, so no caller-supplied credential or session reaches the function.
- **Attach the custom domain in the dashboard, not the deploy config.** Attached in the Cloudflare dashboard, the domain and its DNS stay put, and a `wrangler deploy` cannot change DNS.
- **Serve domain verification from the host root, out of a secret.** OpenAI's directory verifies ownership at `/.well-known/openai-apps-challenge` on the host root, not under `/mcp`, and expects the plain-text token and nothing else. Serve it from the Worker using a Worker secret, never from a file in git. The path returns 404 until the secret is set, so fetch it yourself first. After that, check that the directory confirms verification.
- **Annotate every tool completely.** Directory review flags any tool without a `title` and explicit boolean `readOnlyHint`, `destructiveHint` and `openWorldHint`. Set all of them on every tool. Read-only tools get `readOnlyHint: true` and `destructiveHint: false`. An omitted hint falls back to the MCP spec's cautious default (not read-only, destructive, open-world).
- **Sanitise every payload the host receives, not just the text.** The model-visible text is only one of three payloads. `structuredContent` and the widget `_meta` payload are delivered to the host too. Sanitising only the text left full street numbers in the other two. Run every address-like field in all three through one shared sanitiser. The simplest way is to sanitise the records once and build all three payloads from them.
- **Test the glued forms.** A pattern that required a space after "No" let "No.88" through. Test spaced, punctuated and glued forms ("No 88", "No. 88", "No.88"), and assert on the whole serialised result, not just the text.
- **Widgets: handshake first, then the result, with a fallback image.** An MCP Apps widget must complete `ui/initialize` with the host before it expects the tool result. If its rendering library (here, a map library) cannot start, it should fall back to a static PNG.
- **Key public rate limits on an address the caller cannot set.** Any caller can set `X-Forwarded-For`, so a limit keyed on it is a limit the caller chooses. Use the platform's connecting-IP header. Trust a proxy-forwarded client IP only when the request comes from your own proxy's egress, and make the proxy strip any caller-supplied copy first. For reading the client IP inside an edge function, see `supabase-edge-functions`.
- **Check the caller's own limit before the shared ceiling.** In the other order, one busy address can use up everyone's shared budget before its own limit stops it.

## Process

1. **Confirm the server answers at its function URL.** For its `verify_jwt` setting and deploy flags, see `supabase-edge-functions`.
2. **Write the Worker** (sketch in `reference.md`). It forwards `/mcp` to the function and drops `Authorization`, `apikey` and `Cookie`. It replaces any caller-supplied client-IP header with the platform's connecting IP, answers the verification path, and returns 404 for every other path.
3. **Attach the custom domain** (`mcp.<your-domain>`) to the Worker in the Cloudflare dashboard. Keep routes and custom domains out of the wrangler config.
4. **Set up domain verification.** Store the token as a Worker secret (`wrangler secret put <CHALLENGE_SECRET>`). Fetch `https://mcp.<your-domain>/.well-known/openai-apps-challenge` and check the body is exactly the token. Then run the directory's check and confirm that it reports the domain as verified.
5. **Annotate every tool** with `title`, `readOnlyHint`, `destructiveHint` and `openWorldHint`, then check the `tools/list` response through the custom domain.
6. **Build one sanitiser** and run every address-like field through it before the text, `structuredContent` and `_meta` are built. Add test cases for the glued forms and one test over the whole serialised result.
7. **Order the widget start-up.** It completes `ui/initialize`, then takes the tool result, then renders. If the library fails, it shows the static PNG. Test it in every host you target.
8. **Derive the rate-limit key.** Use the connecting IP, or the proxy-forwarded IP only when the request comes from your own egress. Check the per-caller limit first, then the shared ceiling.
9. **Verify through the custom domain before submitting.** `/mcp` answers. The verification path returns the token. A forged `X-Forwarded-For` maps to the same rate-limit key. No withheld field appears anywhere in a tool result.

## Output format

1. **Topology**: custom domain, proxy and server; what the proxy forwards and strips; where DNS is managed
2. **Proxy routes**: each path with its handling and response, including the 404 default
3. **Domain verification**: path, secret name, self-check result, directory status
4. **Tool manifest**: every tool with its `title`, its three hints, and the reason for each hint value
5. **Output sanitisation**: withheld fields, where each one appears (text, `structuredContent`, `_meta`), sanitiser rules and test cases
6. **Widget behaviour**: start-up order, fallback, hosts tested
7. **Rate limiting**: how the key is derived, when a forwarded IP is trusted, per-caller and shared limits and the order they are checked
8. **Pre-submission checks**: each check, how it was run, and the result

## Quality checklist

- [ ] Server reached through the custom domain's `/mcp`; caller `Authorization`, `apikey` and `Cookie` dropped at the proxy
- [ ] Custom domain attached in the dashboard; no routes or custom domains in the wrangler config
- [ ] `/.well-known/openai-apps-challenge` at the host root returns only the token, from a secret that is not in git
- [ ] The directory confirms domain verification
- [ ] Every tool has a `title` and explicit boolean `readOnlyHint`, `destructiveHint` and `openWorldHint`
- [ ] Read-only tools are marked `readOnlyHint: true` and `destructiveHint: false`
- [ ] Every address-like field in the text, `structuredContent` and widget `_meta` goes through the one shared sanitiser
- [ ] Sanitiser tests include glued forms ("No.88") and assert on the whole serialised result
- [ ] Widget completes `ui/initialize` before it expects the tool result, and falls back to a static PNG
- [ ] Rate-limit key never comes from `X-Forwarded-For`; a forwarded client IP is trusted only from your own proxy's egress
- [ ] Per-caller limit checked before the shared ceiling

## Avoid

- Submitting a platform function URL to a directory instead of a domain the service owns
- Passing caller `Authorization`, `apikey` or `Cookie` headers through to the function
- Declaring the custom domain in the wrangler config, where a routine `wrangler deploy` can change DNS
- Serving the verification token under `/mcp`, wrapping it in HTML or JSON, or committing it to git
- Omitting `title` or leaving any of the three hints implicit, on any tool
- Sanitising only the model-visible text. `structuredContent` and `_meta` reach the host as well
- Address patterns that require a space after "No", which lets "No.88" through
- A widget that expects the tool result before `ui/initialize` completes, or that shows nothing when its library fails
- Keying a public rate limit on `X-Forwarded-For`, or trusting a forwarded IP from anywhere other than your own proxy
- Checking the shared ceiling before the per-caller limit

## Example usage

> "Our GardenTrack MCP server runs as a Supabase edge function. We want to list it in the OpenAI and Claude connector directories on `mcp.example.com`, keep the in-chat map widget, and make sure no tool ever returns a street number. The rate limit is currently keyed on `X-Forwarded-For`. Set up the proxy, verification, annotations, sanitisation and rate limits for submission."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
