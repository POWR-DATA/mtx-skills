# Screen Recording Web Guides

Publish screen-recorded walkthrough videos on a website safely — frame-by-frame redaction of real data, provable blurring, portable ffmpeg encoding, and the written text alternative accessibility requires.

## What this skill does

Turns a raw screen capture into something publishable. It covers the frame sweep that finds live codes, phone numbers and session URLs invisible at playback speed, cropping away browser chrome, placing blur overlays by template matching rather than by eye, proving the redaction against the original frames, re-encoding for streaming, and writing the step list a silent video needs under WCAG 1.2.1.

## When to use it

- A screen recording is about to go on a public help, onboarding or marketing page
- The recording was made on a real or semi-real account rather than a clean demo seed
- Browser chrome, extensions or a checkout URL are visible in the capture
- A fixed-bitrate capture is too large to stream comfortably
- A silent walkthrough is being embedded with no written equivalent

## Example use cases

- Sweep a sign-up walkthrough for live invite codes and a transposed phone number before publishing
- Crop out the address bar and extensions, then blur a contact field that moves as the page scrolls
- Cut a 15.9 MB capture to 3.3 MB with `-crf 20 -preset slow -movflags +faststart`
- Write the numbered step list and the complimentary-billing small print under an embedded guide

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |
| `reference.md` | Load-on-demand excerpts — portable ffmpeg, audio check, crop and timed blur, final encode, redaction proof, embed markup |

## How to use

Copy `SKILL.md` into your AI tool as an instruction or system prompt. Describe the recording, the account it was made on and where it will be published, then work through the structured output. Load `reference.md` for the ffmpeg commands and the verification script.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
