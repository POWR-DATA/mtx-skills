# Website SEO and Indexing — Reference Templates

Load-on-demand templates for [`SKILL.md`](SKILL.md). Illustrative excerpts — load-bearing lines only; replace `<...>` placeholders.

---

## Post-deploy Indexing API CI job

Submits every `<loc>` in `sitemap.xml` to the Google Indexing API after a successful deploy. The sitemap is the single source of truth for what gets submitted. The job **no-ops when the secret is absent** so it never blocks a deploy, and never fails the build on per-URL errors.

```yaml
index_job:
  if: github.event_name == 'push' && github.ref == 'refs/heads/main'
  needs: build_and_deploy_job
  steps:
    - uses: actions/checkout@v3
    - uses: actions/setup-python@v5
    - env:
        GOOGLE_INDEXING_SA_KEY: ${{ secrets.GOOGLE_INDEXING_SA_KEY }}
      run: |
        [ -z "$GOOGLE_INDEXING_SA_KEY" ] && echo "no key — skip" && exit 0
        pip install -q google-auth google-api-python-client
        python ci-index-submit.py   # reads sitemap.xml, POSTs each <loc> to the Indexing API
```

## Loading the service-account key as a secret

```bash
gh secret set GOOGLE_INDEXING_SA_KEY < service-account-key.json   # uploads encrypted; never printed or committed
```

Extract only the non-secret `client_email` (for the Search Console owner step) — never `cat` the whole key or place it in the repo:

```bash
python -c "import json;print(json.load(open('service-account-key.json'))['client_email'])"
```
