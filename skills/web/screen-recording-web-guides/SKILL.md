---
name: screen-recording-web-guides
description: Publish screen-recorded walkthrough videos on a website safely — frame-by-frame redaction of real data, provable blurring, portable ffmpeg encoding, and the written text alternative accessibility requires
author: PowerData
version: 1.0.0
license: MIT
---

# Screen Recording Web Guides

## Purpose

Take a raw screen recording of a product flow and publish it as a web guide without leaking real data and without failing accessibility — reviewing every frame for live identifiers, blurring them in a way you can prove, re-encoding to a size that streams, and writing the step list that a silent video legally needs beside it.

## When to use

Before any screen recording goes on a public page: onboarding walkthroughs, feature guides, support articles, demo videos embedded in marketing pages. Apply after the recording exists and before it is encoded or uploaded — redaction decisions are far cheaper than a re-record, and impossible to retrofit once published.

## Inputs expected

Partial inputs are acceptable — identify the gaps rather than guessing.

- The raw recording, and whether the account shown is a demo or a real one
- What appears on screen: contact details, codes, URLs, billing state, browser chrome and extensions
- Where it will be published and whether that page has an existing text-alternative pattern
- Whether ffmpeg is available on the machine doing the work

---

## Guiding principles

- **Review the recording frame by frame for real data before anything else.** A single pass found a phone number outside ACMA's reserved fictitious ranges (a transposed `0419` where the demo data used `0491 570 xxx`), a live redeemable invite code, and browser chrome exposing a live checkout-session URL and the operator's extensions. None of these are visible at playback speed — they need a deliberate frame sweep.
- **Crop first, then blur what remains.** Cropping to the page content with ffmpeg removes browser chrome, tabs, extensions and the address bar in one step, which eliminates a whole class of leaks before any blurring is needed.
- **Place blur overlays by template-matching the field across frames, not by eye.** A field moves as the page scrolls, so a fixed rectangle either misses it or covers too much. Match the field's position per frame and emit timed `crop,gblur` overlays for the intervals where it is visible.
- **Prove the redaction rather than eyeballing it.** Match every output frame against crops of the unredacted original: if any frame still matches the sensitive region, the overlay timing is wrong. This is the step that turns "I think it's covered" into evidence.
- **`npm install ffmpeg-static ffprobe-static` gives working binaries when ffmpeg is not installed.** Install into a scratch folder — no system package manager, no admin rights, and the paths are importable from a script.
- **Check the audio track before assuming it is wanted.** `-af volumedetect` on a screen capture reported −91 dB, which is digital silence; drop it with `-an` rather than shipping an empty track.
- **Re-encode fixed-bitrate screen captures — the savings are large and free.** `libx264 -crf 20 -preset slow -movflags +faststart` cut 15.9 MB and 5.1 MB source files to 3.3 MB and 1.2 MB with no visible loss, and `+faststart` moves the index to the front so the video streams instead of waiting for a full download.
- **A silent walkthrough needs the same steps written beneath it.** WCAG 1.2.1 requires a text alternative for video-only content; one line per step, no policy links, and updated whenever the product flow changes. Add small print wherever the recording shows account-specific state, such as a complimentary billing period, so a viewer does not read it as the standard offer.

## Process

1. **Sweep the frames** — step through the recording looking for phone numbers, codes, URLs, emails, billing state, names and browser chrome. List every occurrence with its timestamp.
2. **Decide demo-data fixes** — anything that should have been fictitious (phone numbers, ABNs, names) is a re-record or a blur; prefer re-recording from a proper demo seed where the flow is cheap to repeat.
3. **Crop to the page** to remove chrome, tabs and extensions.
4. **Template-match each sensitive field** across frames and generate timed `crop,gblur` overlays for its visible intervals.
5. **Prove it** — compare every output frame against crops of the unredacted original and confirm no match remains.
6. **Check and usually drop the audio** (`-af volumedetect`; `-an` when it is silence).
7. **Re-encode** with `libx264 -crf 20 -preset slow -movflags +faststart` and record the before/after sizes.
8. **Write the step list** beneath the embed, one line per step, plus small print for any account-specific state shown.
9. **Re-check on publication** that the written steps still match the live product flow.

## Output format

1. **Redaction log** — every sensitive item found, its timestamps, and how it was handled (crop, blur, re-record)
2. **Proof of redaction** — the frame-matching check and its result
3. **Encoding report** — source and output size, codec settings, audio decision
4. **Embed markup** — video element, poster, dimensions
5. **Text alternative** — the numbered step list, plus any small print
6. **Maintenance note** — what triggers a re-record or a step-list update

## Quality checklist

- [ ] Frame-by-frame sweep completed; every finding logged with a timestamp
- [ ] Browser chrome, tabs, extensions and address bar cropped out
- [ ] Blur overlays placed by template matching, timed to the field's visible intervals
- [ ] Redaction proven by matching output frames against the unredacted original
- [ ] Audio checked with `volumedetect` and dropped if silent
- [ ] Re-encoded with `-crf 20 -preset slow -movflags +faststart`; sizes recorded
- [ ] Step list published beneath the video, one line per step, no policy links
- [ ] Small print added wherever the recording shows account-specific state

## Avoid

- Judging a recording at playback speed — live codes and transposed numbers are only visible frame by frame
- Blurring with a fixed rectangle on a page that scrolls
- Shipping a redaction you have not verified against the original frames
- Publishing browser chrome, which exposes session URLs, extensions and other tabs
- Leaving a silent audio track on the published file
- Uploading a fixed-bitrate capture unencoded, or omitting `+faststart` so playback waits on a full download
- Publishing a silent walkthrough with no written steps, or letting those steps drift from the product
- Showing a complimentary or trial billing state without small print saying so

## Example usage

> "I've recorded a three-minute walkthrough of our sign-up flow to put on the help page. It was recorded on a real test account in my own browser. Get it ready to publish — I need to be sure nothing identifying is in it, and the page needs whatever accessibility requires for a video with no narration."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
