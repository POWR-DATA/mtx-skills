# Screen Recording Web Guides — Reference

Load-on-demand excerpts for [`SKILL.md`](SKILL.md). Illustrative — load-bearing lines only; replace `<...>` placeholders.

---

## Portable ffmpeg without a system install

```bash
mkdir -p <scratch> && cd <scratch>
npm install ffmpeg-static ffprobe-static       # binaries only, no admin rights
node -e "console.log(require('ffmpeg-static'))"   # prints the path to use
```

## Audio check, then drop it

```bash
ffmpeg -i in.mp4 -af volumedetect -f null -       # mean_volume: -91.0 dB => digital silence
ffmpeg -i in.mp4 -an ...                          # ship no audio track at all
```

## Crop to the page, then blur a field

Cropping removes chrome, tabs, extensions and the address bar in one step. Blur only what survives the crop, timed to the intervals where the field is on screen.

```bash
# crop: width:height:x:y
ffmpeg -i in.mp4 -vf "crop=1280:720:0:140" cropped.mp4

# timed blur over a moving field (one enable clause per visible interval)
ffmpeg -i cropped.mp4 -vf \
 "[0:v]crop=320:48:<x>:<y>,gblur=sigma=24[b];[0:v][b]overlay=<x>:<y>:enable='between(t,4.2,9.8)'" \
 redacted.mp4
```

## Final encode

```bash
ffmpeg -i redacted.mp4 -c:v libx264 -crf 20 -preset slow -movflags +faststart -an out.mp4
# observed: 15.9 MB -> 3.3 MB, 5.1 MB -> 1.2 MB, no visible loss; +faststart puts the index first
```

## Proving the redaction

```python
# every output frame must NOT match the sensitive crop taken from the original
orig = cv2.imread("sensitive_crop.png", 0)
for i, frame in enumerate(frames("out.mp4")):
    score = cv2.matchTemplate(cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY), orig, cv2.TM_CCOEFF_NORMED).max()
    assert score < 0.75, f"frame {i} still shows the field (score {score:.2f})"
```

## Embed plus text alternative

```html
<video src="/assets/guide.mp4?v=2" poster="/assets/guide-poster.jpg"
       width="1280" height="720" controls preload="metadata"></video>

<ol class="video-steps">   <!-- WCAG 1.2.1 text alternative for video-only content -->
  <li>Open <strong>Settings → Account</strong>.</li>
  <li>Select <strong>Add practitioner</strong>.</li>
  <li>Enter their email and send the invitation.</li>
</ol>
<p class="small-print">The account shown has a complimentary billing period; standard pricing applies to new accounts.</p>
```
