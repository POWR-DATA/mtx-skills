# Example Input

## Context

A commercial web app shows a dark, glowing map of a selected area in its social share cards. The images are rendered by a serverless function in the dev project and stored in a storage bucket keyed by entity id, then served from there on every later request.

## Input provided

**Renderer:** serverless function, fetches raster basemap tiles from a popular free dark basemap, composites a 3x3 grid around the centre tile, draws a glow overlay, crops to 1200x630

**Cache:** storage bucket, key `<entity-id>.png`; existing objects are never overwritten

**Observed in the dev project:**

- Tiles render as grey squares reading "API KEY REQUIRED"
- At some positions a blank vertical strip appears down the right edge
- After a colour change was deployed, previously generated cards still show the old colours

**Constraint:** the product is commercial; no paid map plan is budgeted.

**Ask:** make the renderer legal, complete and refreshable.
