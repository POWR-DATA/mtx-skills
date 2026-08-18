# Branded Link QR Service — Reference Templates

Load-on-demand excerpts for [`SKILL.md`](SKILL.md). Illustrative — load-bearing lines only; replace `<...>` placeholders.

---

## Registry — `config/branded-links.json`

```json
{
  "host": "https://go.<domain>",
  "links": [
    { "path": "/card/<person-slug>", "destination": "https://www.<domain>/team/<person-slug>.vcf", "status": 302, "owner": "<name>" },
    { "path": "/card", "destination": "https://www.<domain>/team", "status": 302, "owner": "<team>", "notes": "legacy alias — never remove" }
  ]
}
```

## Generator with `--check` — `scripts/build_links.py`

Semantic comparison: parse both sides and compare objects, so CRLF/whitespace/key order can never fail CI.

```python
import json, sys, pathlib
REG = pathlib.Path("config/branded-links.json"); OUT = pathlib.Path("go/staticwebapp.config.json")

def build():
    links = json.loads(REG.read_text(encoding="utf-8"))["links"]
    return {"routes": [{"route": l["path"], "redirect": l["destination"], "statusCode": 302} for l in links]}
    # ...  status is forced to 302 — a 301 in the registry is a bug, not a choice

if "--check" in sys.argv:
    current = json.loads(OUT.read_text(encoding="utf-8")) if OUT.exists() else None
    sys.exit(0 if current == build() else "DRIFT: regenerate go/staticwebapp.config.json from the registry")
OUT.write_text(json.dumps(build(), indent=2) + "\n", encoding="utf-8", newline="\n")
```

## CI step

```yaml
- name: Branded-link config matches registry
  run: python scripts/build_links.py --check
```

## Generated SWA route (one per link)

```json
{ "route": "/card/<person-slug>", "redirect": "https://www.<domain>/team/<person-slug>.vcf", "statusCode": 302 }
```

Incoming query strings are dropped by a static SWA redirect — keep printed URLs as bare paths and put UTM on the destination.

## QR generation — `npx qrcode` (Node) or `segno` (Python)

```bash
npx -y qrcode -t svg -e Q -q 4 -d "<RRGGBB>FF" -l "FFFFFFFF" -o qr/<slug>.svg "https://go.<domain>/qr/<slug>"   # brand-colour print master
npx -y qrcode -t svg -e Q -q 4 -d "000000FF"   -l "FFFFFFFF" -o qr/<slug>-black.svg "https://go.<domain>/qr/<slug>"
npx -y qrcode -t png -w 1200 -e Q -q 4 -o qr/<slug>.png "https://go.<domain>/qr/<slug>"                       # proof
```


```python
import segno
url = "https://go.<domain>/card/<person-slug>"
qr = segno.make_qr(url, error="m")          # boost_error=True by default: raises EC level without raising the version
qr.save("qr/<person-slug>.svg", scale=10)   # print
qr.save("qr/<person-slug>.png", scale=32)   # screen (~1024 px)
print(qr.version, qr.error)                 # record in the artefact table
```

## Independent decode + destination-absence assertion

```python
from pyzbar.pyzbar import decode          # or cv2.QRCodeDetector().detectAndDecode(img)
from PIL import Image

decoded = decode(Image.open("qr/<person-slug>.png"))[0].data.decode()
assert decoded == url, decoded            # EXACT branded URL — nothing else

dest = "<destination-url>"
assert dest not in open("qr/<person-slug>.svg", encoding="utf-8").read()
assert dest.encode() not in open("qr/<person-slug>.png", "rb").read()
```

## Live redirect check (before print sign-off)

```bash
curl -sI https://go.<domain>/card/<person-slug> | grep -iE '^(HTTP|location)'   # expect 302 + registry destination
```

## ACA escape hatch — Caddy redirect host, no image build

Use when SWA custom-domain binding is wedged. Domain validation: `asuid.<host>` TXT + CNAME to the ACA ingress FQDN; managed cert is free; scale-to-zero. Routes live in the Caddyfile secret below — amend here and redeploy so they stay in source control.

```bicep
var caddyfile = '''
:8080 {
  route {
    redir /qr/<campaign> https://www.<domain>/promotions/<campaign>?src=qr 302
    redir /<campaign> https://www.<domain>/promotions/<campaign>?src=url 302
    redir https://www.<domain>/ 302
  }
}
'''
// ...
configuration: {
  ingress: { external: true, targetPort: 8080 }
  secrets: [ { name: 'caddyfile', value: caddyfile } ]
}
template: {
  containers: [ {
    image: 'docker.io/library/caddy:2.8'
    command: ['caddy', 'run', '--config', '/mnt/secrets/caddyfile', '--adapter', 'caddyfile']
    volumeMounts: [ { volumeName: 'config', mountPath: '/mnt/secrets' } ]
  } ]
  scale: { minReplicas: 0, maxReplicas: 2 }
  volumes: [ { name: 'config', storageType: 'Secret' } ]
}
```

Custom-domain binding on ACA (managed cert, `bindingType Disabled` re-bind fix): see `flet-aca-deploy` *Custom domain*.
