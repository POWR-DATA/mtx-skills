## Data Coverage Analysis

**Natural Earth 110m (`ne_110m_admin_1_states_provinces`)**
- Contains **US states only** — not a global dataset despite the scale name
- US states are fully enumerated
- To get world countries, query `ne_110m_countries` instead; to get non-US states, use the 10m or 50m scales
- Always verify coverage with a test query before relying on the dataset

**WideWorldImporters (`Application.Cities`, `Application.StateProvinces`)**
- Contains **US data only** despite the schema having global `Countries` table
- All cities and states are US-based
- Joins to US-centric data will succeed; non-US location queries return empty results
- The global schema is misleading — the sample data is US-focused

## Query Patterns

### Natural Earth with geography casting (PostgreSQL)

```sql
SET client_min_messages = warning;  -- Suppress coordinate coercion NOTICEs

SELECT
  name,
  ST_AsText(geom) AS geometry_wkt,
  ST_Distance(geom::geography, ST_MakeValid(other_geom)::geography) AS distance_meters
FROM ne_110m_countries
WHERE name = '<your-country>'
ORDER BY distance_meters;
```

**Why this works:**
- `SET client_min_messages = warning` suppresses the NOTICE messages about coordinate coercion
- `ST_MakeValid()` validates geometries before the geography cast
- `::geography` enables distance calculations in meters

### SQL Server spatial validation

```sql
SELECT TOP 10
  CountryID,
  CountryName,
  Border.MakeValid() AS valid_geometry,
  valid_geometry.STDistance(geography::Point(<latitude>, <longitude>, 4326)) AS distance_meters
FROM Application.Countries
WHERE Border.STIsValid() = 0;  -- Find invalid geometries
```

**Why this works:**
- `.MakeValid()` repairs invalid geometries before operations
- `STIsValid()` checks geometry validity first
- The `.STDistance()` call is valid despite DBeaver parser warnings

## Tool-Specific Notes

**DBeaver on SQL Server:**
- Orange warning triangles on `.STDistance()`, `.STContains()`, `geography::Point()`, `.Long` are **parser limitations, not execution errors**
- The queries run correctly despite the warnings
- CTE rewrites and column aliasing do NOT resolve the warnings — they are purely cosmetic
- Safe to ignore after verifying the query logic is correct

**PostgreSQL in DBeaver:**
- `client_min_messages = warning` suppresses NOTICE-level messages but not WARNING or ERROR
- Always include this in scripts that cast to geography to reduce noise in query results

## Coverage Verification Checklist

- [ ] Natural Earth: Verified with `SELECT DISTINCT name FROM ne_110m_admin_1_states_provinces LIMIT 10` to confirm US-only
- [ ] WideWorldImporters: Verified with `SELECT DISTINCT CountryID FROM Application.Cities` to confirm US-only
- [ ] Geometries: Ran `.STIsValid()` or `ST_IsValid()` on sample rows to identify invalid geometries
- [ ] Warnings: Identified which warnings are expected (DBeaver parser, coordinate coercion NOTICEs) vs. actual errors
