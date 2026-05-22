---
name: app-icon-asset-generation
description: Generate a consistent application icon asset set from an approved high-resolution logo, including large app assets, small UI icons, favicons, transparent PNGs, and SVG micro icons
author: POWR-DATA
version: 1.1.0
license: MIT
---

# App Icon Asset Generation

## Purpose

Generate a complete, consistent set of application and web icon assets from an approved high-resolution source logo. This skill is focused on preserving visual consistency, scaling quality, transparency, file sizing, and usability across mobile apps, desktop apps, web apps, app bars, favicons, splash screens, and store assets.

This skill is not about inventing a brand style. The source logo, colours, theme, and visual direction should be supplied by the user. The AI should use that approved source artwork as the visual anchor for every derived asset.

## When to use

Use this skill when a user has an approved large logo or app icon and wants production-ready supporting assets for an application or web application.

Typical triggers:

- The user has a high-resolution logo and needs smaller versions for app use
- The user wants app icon, splash, favicon, micro icon, and launcher assets
- The user needs transparent PNGs that blend cleanly on different backgrounds
- The user wants SVG versions for scalable UI use
- The user wants a simplified icon that still looks related to the main logo
- The user is seeing rectangular background edges, poor scaling, blur, or excessive detail at small sizes
- The user wants individual downloadable files rather than one combined image

This skill applies after the main logo direction has already been approved.

## Inputs expected

Provide as many of the following as available. Partial inputs are acceptable. The AI should identify gaps and ask structured follow-up questions only where needed.

- Approved source logo, preferably 1024x1024px, 2048x2048px, or larger
- Transparent source logo if available
- Existing app icon, splash image, favicon, or micro icon attempts
- Target platforms, such as Android, iOS, Flutter, Flet, web, desktop, or PWA
- Required output sizes
- Required output formats, such as PNG, SVG, ICO, or WebP
- Background colours where the assets will be displayed
- Whether the logo should have transparent background or fixed background
- Whether small icons should be detailed or simplified
- Use context for each asset, such as splash screen, login hero, AppBar, favicon, launcher icon, store listing, notification icon
- Naming conventions required by the project
- Whether assets should be generated individually or as a full downloadable set

## Guiding principles

- Treat the approved high-resolution logo as the source of truth.
- Do not redesign the brand unless the user explicitly asks.
- Preserve consistency between large assets and small assets.
- Use transparent PNGs where possible so assets blend cleanly across backgrounds.
- A file can be RGBA and still not be truly transparent. Confirm that background pixels have alpha=0.
- Do not create separate background-coloured variants unless there is a strong reason. Transparent assets are usually safer.
- Small icons are not simply large logos scaled down. They may need simplified shapes to remain readable.
- Generate a micro icon as a simplified interpretation of the main logo, not as a new unrelated logo.
- Prioritise silhouette, contrast, and recognisability at small sizes.
- At 28x28 and 32x32, remove unnecessary detail that will collapse or blur.
- At 16x16, even many good micro icons may need an ultra-simplified favicon.
- Prefer SVG for micro UI icons when clean vector geometry is practical.
- Prefer PNG for complex raster artwork, launcher icons, splash screens, and store assets.
- If creating SVG from PNG, avoid raw jagged tracing. Smooth paths, reduce noise, and produce a PNG preview.
- Always provide separate download links for each final file.
- Do not provide one combined contact sheet as the only deliverable.
- Make the exported files directly usable in the project.

## Process

1. Confirm the source logo
   - Identify the approved master logo.
   - Confirm whether it already has transparency.
   - Confirm its dimensions and visual quality.
   - Use the largest clean version available.

2. Identify target asset roles
   - Classify outputs into large brand assets and small UI assets.
   - Large brand assets include launcher icon, splash, login hero, store listing, and marketing images.
   - Small UI assets include AppBar icon, toolbar icon, favicon, notification icon, and micro icon.

3. Decide whether each asset should be detailed or simplified
   - Use detailed source artwork for large assets.
   - Use a simplified visual mark for very small sizes.
   - Do not force detailed artwork into tiny UI placements if it becomes unreadable.

4. Check transparency requirements
   - Use transparent PNGs when the asset needs to sit on different UI backgrounds.
   - Confirm corner pixels are alpha=0.
   - Remove any accidental solid background, glow rectangle, or edge artifact.
   - Avoid matching a background colour manually unless the user specifically requires a fixed-background export.

5. Create the detailed asset set
   - Export from the approved master logo.
   - Preserve proportions and central alignment.
   - Use high-quality resampling for PNG exports.
   - Common sizes include 2048, 1024, 512, 192, and 120px.
   - Keep the same visual composition across these sizes.

6. Create the micro icon
   - Base it on the most recognisable central mark or dominant silhouette from the source logo.
   - Simplify detail while keeping the brand relationship obvious.
   - Remove tiny decorative elements that will not read at 28x28.
   - Use strong contrast and clear negative space.
   - Test preview renders at 28x28 and 32x32.
   - If the user dislikes the simplified version, revise based on the source logo rather than iterating on an unrelated simplified attempt.

7. Create SVG where useful
   - Use SVG for micro icons, simple marks, or clean geometry.
   - If embedding a PNG inside an SVG, clearly state that it is an SVG wrapper, not a true vector redraw.
   - For true SVG micro icons, use clean paths, gradients, and minimal filters.
   - Provide a PNG preview of the SVG at 512px and at the target micro size.

8. Export final files
   - Use clear file names.
   - Provide each file as an individual downloadable link.
   - Include dimensions and format in the label.
   - Do not rely on the chat image preview as the final asset, because previews may be compressed or scaled.

9. Validate the asset set
   - Verify dimensions.
   - Verify transparency.
   - Verify small-size readability.
   - Verify consistency with the approved source logo.
   - Verify file names align with project expectations.

## Output format

The AI should structure its response as follows:

1. Confirmed source — state which uploaded/master logo is being used and whether it is detailed or micro-focused.

2. Planned outputs — list the requested files and sizes, separating large/detail assets from small/micro assets.

3. Generated files — provide individual download links for each generated file, including dimensions and format in each link label.

4. Notes — mention any important caveats, such as SVG being true vector vs PNG embedded in SVG, or if a small asset is intentionally simplified for readability.

5. Next recommended step — suggest only the next relevant export or review step.

## Recommended asset set

Adjust based on the user's platform. Default set:

| File | Size | Use |
|---|---|---|
| `logo_2048.png` | 2048×2048 | Transparent PNG — splash screen, high-res master |
| `logo_1024.png` | 1024×1024 | Transparent PNG — app icon / store base |
| `logo_512.png` | 512×512 | Transparent PNG — general app use, PWA |
| `logo_512.svg` | — | SVG version if suitable |
| `logo_192.png` | 192×192 | Android / PWA launcher |
| `logo_120.png` | 120×120 | Login hero or compact UI branding |
| `microicon.svg` | — | Scalable simplified icon |
| `microicon_32.png` | 32×32 | Small UI preview / favicon test |
| `microicon_28.png` | 28×28 | AppBar or toolbar icon |
| `favicon.png` | 32×32 | Browser favicon candidate |
| `favicon.ico` | — | Optional browser-specific export |

## Quality checklist

- [ ] The approved high-resolution logo was used as the source of truth
- [ ] Large assets preserve the source logo's composition and proportions
- [ ] Micro icon is visually related to the source logo
- [ ] Micro icon is simplified enough to read at 28x28
- [ ] SVG file is actually SVG, not accidentally delivered as PNG
- [ ] If SVG embeds a PNG, that limitation is clearly stated
- [ ] PNG files are the requested dimensions
- [ ] Transparent PNG files have alpha=0 background pixels
- [ ] No rectangular background edge is visible on target UI colours
- [ ] Individual download links are supplied for every generated file
- [ ] 28x28 and 32x32 previews are generated for micro icon review
- [ ] File names are clear and project-ready
- [ ] The user can consume the files without manually extracting them from a combined mockup

## Avoid

- Inventing a new brand style when the user already has an approved logo
- Generating only a mockup image when the user asked for downloadable files
- Creating one big contact sheet as the only output
- Assuming a chat preview is the final downloadable asset
- Claiming a file is transparent without checking the alpha channel
- Claiming a file is SVG if it is actually a PNG image
- Over-detailing micro icons
- Scaling the detailed logo down to 28x28 and expecting it to remain readable
- Creating background-coloured icons when a transparent PNG would solve the problem
- Using pure black or arbitrary background colours unless the user requested fixed-background variants
- Continuing to iterate from a failed simplified icon when the user wants the source logo used as the basis
- Using excessive glow that causes the icon to blur at small sizes

## Example usage

> "I have uploaded a 2048x2048 app logo that I'm happy with. Use it as the source of truth and generate a complete app/web icon set. I need transparent PNGs at 2048, 1024, 512, 192, and 120px. I also need a simplified micro icon based on the centre of the logo, delivered as SVG plus 28x28 and 32x32 PNG previews. Please provide separate download links for each file."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
