# Example Output — Supabase Edge Functions

## Deployment checklist

| Item | Action |
|---|---|
| npm SDK import | Replace with `fetch` against provider REST API |
| CLI authentication | Use `SUPABASE_ACCESS_TOKEN` env var |
| Gemini model name | Switch to `gemini-2.0-flash` |
| Error extraction | Read `error.context.clone().json()` |
| Bad cached row | Delete directly in SQL Editor |

---

## Fix 1 — npm SDK import fails in Deno

`npm:@google/generative-ai` relies on Deno's npm compatibility layer, which is unreliable for complex SDK packages. Use the Gemini REST API via `fetch` directly:

```ts
Deno.serve(async (req) => {
  const { prompt } = await req.json();
  const apiKey = Deno.env.get('GEMINI_API_KEY');

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
      }),
    }
  );

  const data = await response.json();
  const text = data.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
  return Response.json({ summary: text });
});
```

This pattern works with any LLM provider — replace the URL and request body shape for OpenAI or Anthropic.

---

## Fix 2 — CLI auth hanging in PowerShell

`supabase login` opens a browser flow and blocks when there is no interactive terminal. Use an access token instead:

```powershell
$env:SUPABASE_ACCESS_TOKEN = "sbp_your_token_here"
supabase functions deploy generate-summary
```

Generate the token at supabase.com → Account → Access Tokens. The env var is read automatically by the CLI.

---

## Fix 3 — Gemini model returns 404

`gemini-1.5-flash` is deprecated on the v1beta API. Update the model name in the fetch URL:

```
# Deprecated — returns 404
gemini-1.5-flash

# Use instead
gemini-2.0-flash
gemini-flash-lite-latest    <- lower quota cost
```

If calls fail with quota `limit: 0`, check GCP → APIs & Services → Quotas for the Generative Language API. A `limit: 0` value means the GCP project has no free tier enabled — this is usually an org policy restriction, not exhausted quota.

---

## Fix 4 — Extracting the real error from FunctionsHttpError

`FunctionsHttpError.message` is always `"non-2xx status code"`. Read the actual response body from the edge function:

```ts
try {
  const { data, error } = await supabase.functions.invoke('generate-summary', {
    body: { prompt },
  });
  if (error) throw error;
  return data;
} catch (err) {
  if (err?.name === 'FunctionsHttpError') {
    const body = await err.context.clone().json();
    console.error('Edge function error:', body);
  }
  throw err;
}
```

---

## Fix 5 — Client serving bad cached data after function fix

The cache table has a row with today's date containing the incorrect summary. The client stale check only triggers when no row exists — it will keep reading the bad row indefinitely.

Delete the affected row in the Supabase SQL Editor:

```sql
DELETE FROM summaries WHERE date_column = '2026-05-25';
```

The next client request finds no row, triggers a fresh edge function call, and writes the corrected result.

---

## Post-fix checklist

- [ ] `fetch`-based Gemini call tested with `supabase functions serve`
- [ ] Function deployed with `SUPABASE_ACCESS_TOKEN` set
- [ ] Error handling reads `error.context.clone().json()` on failure
- [ ] Model name confirmed as `gemini-2.0-flash` or `gemini-flash-lite-latest`
- [ ] Bad cached rows deleted; fresh fetch confirmed
