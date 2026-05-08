# Example Input

## User request

> I have uploaded a 2048x2048 PNG app logo with a transparent background. I'm happy with it as-is — please use it as the source of truth. I need a full icon set for an Android and web app built with Flet.
>
> Required outputs:
> - Transparent PNGs at 2048, 1024, 512, 192, and 120px
> - A simplified micro icon based on the central mark of the logo, as SVG plus PNG previews at 28x28 and 32x32
> - A favicon at 32x32 PNG
>
> Please provide each file as a separate download link. File names should follow the pattern `logo_<size>.png` and `microicon_<size>.png`.

## Supplied assets

- `app_logo_master.png` — 2048x2048px, RGBA, transparent background, uploaded by user

## Target platforms

- Android (launcher icon, splash screen)
- Web/PWA (favicon, manifest icon)
- Flet app (AppBar micro icon)

## Notes

- No fixed background colour needed — transparent everywhere
- Micro icon should be simplified for AppBar use at 28px
- No store submission yet — production signing not required at this stage
