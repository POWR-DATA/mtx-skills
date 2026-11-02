# Remote MCP Server — Reference

Load-on-demand excerpts for [`SKILL.md`](SKILL.md). These are illustrative and show the load-bearing lines only. Replace the `<...>` placeholders with your own values.

---

## Worker in front of the edge function

```js
// Cloudflare Worker on mcp.<your-domain>. The custom domain is attached in the dashboard, not in wrangler config.
const UPSTREAM = "https://<your-project-ref>.supabase.co/functions/v1/<your-function>";
const STRIP = ["authorization", "apikey", "cookie", "x-client-ip"];

export default {
  async fetch(req, env) {
    const url = new URL(req.url);

    if (url.pathname === "/.well-known/openai-apps-challenge") {
      if (!env.OPENAI_APPS_CHALLENGE) return new Response("Not found", { status: 404 });
      return new Response(env.OPENAI_APPS_CHALLENGE, {      // the token only: no HTML, no JSON
        headers: { "content-type": "text/plain; charset=utf-8" },
      });
    }
    if (url.pathname !== "/mcp") return new Response("Not found", { status: 404 });

    const headers = new Headers(req.headers);
    for (const h of STRIP) headers.delete(h);               // caller credentials and any forged client IP
    headers.set("x-client-ip", req.headers.get("cf-connecting-ip") ?? "");

    return fetch(UPSTREAM + url.search, { method: req.method, headers, body: req.body });
  },
};
```

- Set the token with `wrangler secret put OPENAI_APPS_CHALLENGE`. The verification path returns 404 until the secret is set.
- `x-client-ip` is only an example name. Any header works, as long as the Worker deletes the caller's copy before it sets its own.

## Tool annotations

```json
{
  "name": "find_places",
  "title": "Find places",
  "description": "Search places by suburb. Returns street names, never street numbers.",
  "inputSchema": { "type": "object", "properties": { "suburb": { "type": "string" } } },
  "annotations": {
    "title": "Find places",
    "readOnlyHint": true,
    "destructiveHint": false,
    "openWorldHint": false
  }
}
```

- Set all three hints as explicit booleans on every tool. If you omit them, the MCP spec defaults apply (`readOnlyHint: false`, `destructiveHint: true`, `openWorldHint: true`), and those defaults describe a read-only search as a destructive, open-world tool.
- `openWorldHint` is `true` when the tool interacts with external entities beyond your own data, such as a web search or a third-party API.
- Current MCP revisions put `title` on the tool itself, and older ones read `annotations.title`. Setting both does no harm.

## One sanitiser, three payloads

```ts
// wrong: /\bNo\.?\s+\d+/ requires a space, so "No.88" passes through
const NO_FORM = /\bNo\.?\s*\d+[A-Za-z]?\b\s*/gi;           // "No 88", "No. 88", "No.88"
const LEADING = /^\s*(?:\d+[A-Za-z]?\/)?\d+[A-Za-z]?\s+/;   // "88 Hill St", "88A Hill St", "4/88 Hill St"

export const sanitiseAddress = (s: string) => s.replace(NO_FORM, "").replace(LEADING, "").trim();

const safe = rows.map((r) => ({ ...r, address: sanitiseAddress(r.address) }));

return {
  content: [{ type: "text", text: describe(safe) }],   // model-visible
  structuredContent: { places: safe },                 // also delivered to the host
  _meta: { markers: safe.map(toMarker) },              // widget payload, also delivered to the host
};
```

```ts
// whole-result test: seed a fixture at "No.8817 Hill St", then check that every payload is clean
const out = JSON.stringify(await callTool("find_places", { suburb: "<fixture-suburb>" }));
assert(!out.includes("8817"), "street number leaked into text, structuredContent or _meta");
```

## Rate-limit key and order

```ts
// For reading the connecting IP inside an edge function, see supabase-edge-functions.
function clientKey(req: Request): string {
  const connecting = connectingIp(req);                    // set by the platform, not by the caller
  if (isOwnProxyEgress(connecting)) {                      // <how you recognise your proxy's egress>
    return req.headers.get("x-client-ip") ?? connecting;   // the proxy already stripped any caller copy
  }
  return connecting;                                       // never X-Forwarded-For: any caller can set it
}

const key = clientKey(req);
if (!(await perCaller.allow(key))) return tooMany();       // the caller's own limit first
if (!(await shared.allow("all")))  return tooMany();       // then the shared ceiling
```

If the shared ceiling is checked first, requests that are already over their caller's own limit still use up the shared budget.
