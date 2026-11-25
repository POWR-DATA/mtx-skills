---
name: ai-social-content-pipeline
description: Build an automated LLM pipeline that drafts, fact-checks and renders social posts — validation on every edit, defensible risk classification, correct typography and acronyms, image briefs that do not come out brown, and spend tracking that matches the provider
author: PowerData
version: 1.1.0
license: MIT
---

# AI Social Content Pipeline

## Purpose

Build and operate an unattended pipeline that turns a topic into a published social post — LLM draft, fact-check, risk screen, rendered image card — without the failure modes that make such a pipeline quietly wrong: drafts that bypass validation, a risk classifier that flags "San Diego" as a death story, acronyms mangled by Title Case, images that all come out brown, and a spend estimate that disagrees with the provider by a factor of three.

## When to use

When an LLM generates content that will be published with little or no human review — scheduled social posts, newsletter items, generated cards — and especially once it runs on a schedule rather than on demand. Apply while building the draft/fact-check/render stages, and again when a run produces output that is subtly wrong rather than obviously broken.

## Inputs expected

Partial inputs are fine — state assumptions for the rest.

- The pipeline stages that exist (draft, fact-check, risk screen, render, publish) and which are automated
- The model and tooling in use, and the provider account the spend is drawn from
- Brand constraints — palette, fonts, acronyms that must survive casing, topics that must never auto-publish
- Where drafts are persisted between stages, and what loads them

---

## Guiding principles

- **Re-validate after every programmatic edit.** Pydantic's `model_copy(update=...)` skips validation, so a fact-check edit pushed a field past its length limit, the invalid draft was saved, and every later load of the drafts folder crashed. Call `Model.model_validate(obj.model_dump())` after any edit a human did not type, and make directory loaders skip and log an unreadable file rather than fail the whole run — one bad draft should not stop the pipeline.
- **A keyword risk floor must match stems as whole words, and a famous-death hold needs two-source confirmation.** A prefix match (`\bdie`) flagged "San Diego" as a death story and held a harmless post. Match an explicit inflection list instead — `\b<stem>(?:s|ed|ing|...)?\b` — and unit-test the known false positives: place names, "minority", "investigation". A plain famous-death report may skip the force-override only when at least two reputable outlets carry it and the story does not involve violence, suicide, crime, children, an accident or a disaster; include phrases such as "shot dead" in the list or those stories slip through.
- **Title Case must handle hyphenated tokens and digit-bearing acronyms as units.** Casing each hyphen part separately turned "GLP-1" into "Glp-1" on a rendered card. Match whole hyphenated tokens against the acronym list first, and leave any uppercase token containing a digit unchanged (GLP-1, COVID-19, F1, 5G).
- **Record spend in a `finally` path, and reconcile against the provider.** An in-code estimate showed $6 remaining while the provider console showed $1.93, because crashed runs recorded no spend at all and early setup testing predated the tracker. Write the estimate in `finally` so a crash still books its cost, track image-generation cost on its own ledger because it is billed by a different provider, reconcile against each console on every top-up, and turn on provider auto-reload so a daily job never stalls on credit. Budget from measurement: with Opus-class models and a web-search fact-check, each generated post cost about $0.60.
- **Brief images for named colour and concrete objects, or they come out brown.** "Warm golden-hour cinematic" plus a renderer that darkened the lower 70% of the card produced uniformly brown, dreary images, and sparse briefs produced plain backdrops. Ask for named vivid colours, three depth layers, and at least five concrete story objects, with negative terms such as "sepia, empty background, minimalist". Darken only a panel behind the text, never the whole frame.
- **Rotate looks and layouts against recent posts.** A grid of generated cards reads as one photo shoot unless named looks and layouts are deliberately varied against what was published recently — track the last N and exclude them.
- **Fill text from glyph ink bounds, not the line box.** Pasting a gradient over each word's line-height box clipped descenders in Pillow — "Group" lost its "p". Paste over `font.getbbox()` per word, and position rules and underlines from the same ink bounds.
- **A stock or archive photo must pass three subject checks, or fall back to a generated image.** The post must name the subject, the archive file title must name the subject, and a vision check must agree the photo shows that subject and fits the story. If any check fails, do not ship the photo — an unrelated political picture on a prize announcement is the typical failure. After the picture is made, mark faces, the main subject and key story objects as regions that must stay visible, then place the headline and inset around them; omit the inset rather than cover a subject, and hold the card if something important would still be hidden.
- **Held-item notices must include the exact commands to copy, and those commands are read only from the digest issue.** Say why the item is held, what to review, and the comments to copy: a force-approve for the next slot, a combined force-and-publish-now command, a drop, and a regenerate. A bare item number that rebuilds the item will just hold it again. Chat messages, and notification-email replies sent from a non-GitHub address, are dropped silently; in the GitHub app the comment is not submitted until Comment is tapped; a publish command sent before a force-approve has finished saving can fail, so prefer a single combined command. Do not expect an API delete on Instagram Login accounts — only Facebook Login accounts can delete media through the API, otherwise the owner must delete the post in the Instagram app.
- **Do not delete a rebuilt custom GPT until its Knowledge files are in the repo, and look for a legacy system prompt in Project chats, not only in custom instructions.** Download reference images and other Knowledge files first: deleting the GPT does not export them and does not remove the Project chats. Search the Project for a distinctive heading rather than opening every chat, then compare the prompt with the current pipeline because later product decisions may have diverged on purpose.

## Process

1. **Model the draft** with validated fields and explicit length limits, and decide what a loader does with an invalid file (skip and log).
2. **Draft, then edit through validation** — every automated edit round-trips `model_validate(model_dump())`.
3. **Fact-check** with the tool or search step, recording the cost of the call.
4. **Risk-screen** with whole-word stems plus an inflection list, and a unit-test file of known false positives.
5. **Render** — Title Case through the acronym-aware helper, gradient fills from glyph ink bounds, panel-only darkening behind text. For a real photo, run the three subject checks and reserve visible regions before placing the headline and inset.
6. **Brief the image** with named colours, three depth layers, five-plus concrete objects, negative terms, and a look/layout excluded against recent posts.
7. **Book the spend in `finally`**, split image cost from the text-model provider, then reconcile against each console at every top-up.
8. **Publish**, and keep the risk classifier's holds reviewable so false positives are caught and fixed rather than tolerated. Held notices must list the exact issue comments to copy, and those commands are accepted only from the digest issue.

## Output format

1. **Pipeline map** — stages, what is automated, where drafts persist
2. **Validation rules** — model fields and limits, re-validation points, loader behaviour on a bad file
3. **Risk classifier** — stem list, inflection pattern, false-positive test cases, and the two-source rule for plain famous-death reports
4. **Render rules** — acronym list, casing helper behaviour, glyph-bounds handling, real-photo subject checks and reserved visible regions
5. **Image brief template** — colour, layers, objects, negative terms, look/layout rotation
6. **Cost model** — per-post estimate, where spend is booked, image-cost split, reconciliation and auto-reload settings
7. **Moderation and publishing** — exact hold-command list, issue-comment channel, and how a published item is deleted if the API cannot

## Quality checklist

- [ ] Every programmatic edit re-validates; loaders skip and log bad files instead of failing the run
- [ ] Risk stems matched as whole words with an inflection list; false-positive tests include place names; famous-death auto-clear requires two reputable sources and excludes violence, suicide, crime, children, accidents and disasters
- [ ] Hyphenated and digit-bearing acronyms survive Title Case unchanged
- [ ] Spend booked in a `finally` path, image cost tracked separately, and each ledger reconciled against its provider; auto-reload on
- [ ] Image briefs name colours, three depth layers and five-plus objects, with negative terms
- [ ] Only a panel behind the text is darkened, never the whole image
- [ ] Looks and layouts rotated against recent posts
- [ ] Gradient fills and rules positioned from `font.getbbox()`, not the line box
- [ ] Real photos pass subject, archive-title and vision checks; headlines and insets do not cover reserved regions
- [ ] Held notices list exact issue comments; commands are accepted only from the digest issue
- [ ] Knowledge files and legacy prompts are in the repo before a rebuilt GPT is deleted

## Avoid

- `model_copy(update=...)` on anything that will be persisted — it writes past the field's own limits
- Letting one unreadable draft file fail the whole directory load
- Prefix-matching risk keywords (`\bdie` matches "San Diego")
- Auto-clearing a death story from a single source, or treating "shot dead" as a plain death report
- Shipping an archive photo that fails a subject, title or vision check
- Covering a face or key object with a headline or inset
- Title-casing hyphen parts independently, or lowercasing tokens that contain digits
- Trusting an in-code spend estimate — crashed runs book nothing, so it drifts optimistic
- Mixing image-generation cost into the text-model ledger
- Briefing an image with mood words alone, or darkening the whole frame for text contrast
- Pasting gradients over the line-height box and clipping descenders
- Held notices that do not give the exact comment to copy, or commands sent in chat or by email
- Expecting the Instagram media delete API to work on an Instagram Login account
- Deleting a rebuilt GPT before its Knowledge files and legacy prompts are saved

## Example usage

> "Our daily post generator runs on a schedule. Last week it held a post about a San Diego conference as a 'death story', a card rendered 'Glp-1' instead of 'GLP-1', every image came out muddy brown, and the budget tracker said $6 when the provider said $1.93. Fix the classifier, the casing, the image briefs and the cost tracking."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
