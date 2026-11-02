# Cloudflare R2 Static Data — Reference

Load-on-demand excerpts for [`SKILL.md`](SKILL.md). Illustrative — load-bearing lines only; replace `<...>` placeholders.

---

## Credentials

R2 dashboard → *Manage API tokens* → create a token with **Object Read & Write**, applied to **specific buckets only** → `<bucket>`. It yields an Access Key ID and Secret Access Key for the S3 API.

```ini
# ~/.aws/config
[profile r2]
region = auto
```

```bash
R2="https://<account-id>.r2.cloudflarestorage.com"
```

## Sync per prefix

```bash
for p in nsw vic qld; do          # different prefixes may run in parallel; never two syncs on one prefix
  aws s3 sync "out/<dataset>/v1/$p/" "s3://<bucket>/<dataset>/v1/$p/" \
    --profile r2 --endpoint-url "$R2" \
    --content-type application/json \
    --cache-control "public, max-age=2592000, immutable" \
    --only-show-errors &
done
wait
```

The same `--content-type` and `--cache-control` on every sync. Never a per-file `aws s3 cp` loop.

## Completeness gate, then the manifest

```bash
fail=0
while read -r p; do                                   # prefixes.txt = every prefix the app reads
  remote=$(aws s3 ls "s3://<bucket>/<dataset>/v1/$p/" --recursive --profile r2 --endpoint-url "$R2" | wc -l)
  built=$(find "out/<dataset>/v1/$p" -type f | wc -l)
  [ "$remote" -gt 0 ] && [ "$remote" -eq "$built" ] || { echo "INCOMPLETE $p: remote=$remote built=$built"; fail=1; }
done < prefixes.txt
[ "$fail" -eq 0 ] || exit 1

aws s3 cp out/<dataset>/v1/meta.json "s3://<bucket>/<dataset>/v1/meta.json" \
  --profile r2 --endpoint-url "$R2" \
  --content-type application/json --cache-control "public, max-age=2592000, immutable"   # last, only after the gate
```

Only then switch the release to `v1`.

## Verify through the custom domain

```bash
curl -sI "https://data.<your-domain>/<dataset>/v1/<prefix>/<shard>.json"
# HTTP/2 200
# content-type: application/json
# cache-control: public, max-age=2592000, immutable
# cf-cache-status: HIT        (on a repeat request)
```

JSON is not in Cloudflare's default list of cached file extensions. Without a Cache Rule marking the data hostname eligible for cache, expect `cf-cache-status: DYNAMIC` — browsers still honour `Cache-Control`, but every first request per client goes to the bucket.
