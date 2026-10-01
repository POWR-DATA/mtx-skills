# Example Input

## Context

A small SaaS wants a silent walkthrough video on its help page showing how to invite a colleague to an account. The recording was made on a staging account in the founder's own Chrome window, at 1920×1080, and saved as a 15.9 MB fixed-bitrate MP4. The help page is a static site with an existing `/assets/` folder on a 7-day cache.

## Input provided

**Recording:** `invite-walkthrough.mp4`, 2 min 48 s, 1920×1080, 15.9 MB, audio track present but nothing was said.

**What is on screen:**

- Full browser window — tab strip with three other tabs, address bar, two extension icons
- The staging account's contact page, showing a phone number typed as `0419 570 156`
- An invitation screen displaying a live, still-redeemable invite code
- A brief moment where the billing page shows "Complimentary — no charge until further notice"
- The address bar shows a checkout session URL during one transition

**Target page:** `/help/inviting-your-team`, static HTML, no existing video embeds.

**Available tooling:** Node is installed; ffmpeg is not, and the machine has no admin rights.

**Ask:** get this publishable — safe to put on a public page, small enough to stream, and whatever the accessibility standard needs for a video with no narration.
