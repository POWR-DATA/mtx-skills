# Example Input

## Context

GardenTrack is a crowd-sourced map of front-yard produce stalls. Contributors submit a stall's full address. The public app shows only the street and suburb, never the street number. Its MCP server lets ChatGPT and Claude users search for stalls and see them on an in-chat map.

## Input provided

**Server:** Supabase edge function `gardentrack-mcp`. It answers MCP requests at `https://<your-project-ref>.supabase.co/functions/v1/gardentrack-mcp`.

**Domain:** `example.com`, with DNS on Cloudflare. The goal is `mcp.example.com`.

**Tools:**

- `find_stalls`: search by suburb and produce; opens the map widget
- `get_stall`: one stall's details
- `list_suburbs`: suburbs that have at least one stall

All three read GardenTrack's own database. None of them writes. No tool has annotations yet.

**Widget:** an MCP Apps map widget that uses a third-party map library loaded from a CDN. It sometimes renders blank. It starts listening for the tool result as soon as it loads. Pins are placed at a street-level point, not at the stall.

**Current privacy handling:** the tool text goes through `/\bNo\.?\s+\d+/` and a strip of leading numbers. `structuredContent.stalls[].address` and `_meta.markers[].popup` are built from the raw database row.

**Current rate limit:** 30 requests/min per caller, keyed on the first `X-Forwarded-For` entry. A shared ceiling of 600 requests/min is checked first.

**Ask:** get the server ready to submit to the OpenAI and Claude connector directories.
