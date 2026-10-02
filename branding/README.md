# branding/

Single source of truth for every brand asset of the two sibling apps, **I Want USA** and **I Want India**
(one Flutter codebase, flavors `usaDev|usaStaging|usaProd|indiaDev|indiaStaging|indiaProd`).

```
branding/
  shared/            "I Want" mark (mark.svg, uses currentColor), neutral colors.json, fonts/, licence notes
  usa/  india/       README.md, colors.json, sizes.json + logo/ app_icon/ splash/ store/ social/ ads/ web/
```

The two apps share the mark and neutrals; they differ by accent colour (USA blue `#1D4ED8`, India deep saffron
`#C2410C`) and a country badge on the icon ("USA" / "IN").

Everything below `usa/` and `india/` except `README.md`, `colors.json` and `sizes.json` is a **generated placeholder**.
Final artwork replaces it with the same file names and sizes; no code changes needed.

## Regenerate

```sh
python3 -m pip install Pillow                  # once
python3 tool/branding/generate.py              # both countries (or --country usa / --country india)

# Launcher icons: reads every flutter_launcher_icons-<flavor>.yaml at the repo root
dart run flutter_launcher_icons

# Native splash: one flutter_native_splash-<flavor>.yaml per flavor
dart run flutter_native_splash:create --flavors usaDev,usaStaging,usaProd,indiaDev,indiaStaging,indiaProd
```

`generate.py` reads `branding/<country>/sizes.json` + `colors.json`, fails if any colour pair drops below WCAG AA
(4.5:1), and writes:

- every PNG/SVG listed in `sizes.json` (paths with `{locale}` expand per locale, `{n}` to 01..count);
- `branding/<country>/README.md` (palette + contrast table);
- `lib/core/theme/brand_colors.g.dart` (`BrandColors.usa`, `BrandColors.india`; the app theme reads only this);
- `flutter_launcher_icons-<flavor>.yaml` and `flutter_native_splash-<flavor>.yaml` at the repo root.

Both packages name flavor configs `<package>-<flavor>.yaml`, where `<flavor>` is the full Flutter flavor
(Android variant / source set such as `usaDev`, iOS scheme of the same name), so there is one file per flavor.
Add `flutter_launcher_icons` and `flutter_native_splash` to `dev_dependencies` before running them.

## Rules

- Sizes change. `sizes.json` records the platform source page and the date checked (`2026-10-02`); re-verify before
  final artwork and bump `checked`.
- Keep text inside the `safe` / `safe_circle` zones in `sizes.json` (stories, reels, TikTok, Shorts, YouTube banner,
  Facebook cover, adaptive icons, Android 12 splash).
- Real store screenshots come from the integration_test screenshot driver / fastlane and overwrite the placeholder
  frames in `store/google_play/screenshots/` and `store/apple/screenshots/`.
- Videos (app previews, TikTok ads, Play promo video) are not generated; see the README / `promo_video.txt`
  placeholders in their folders.
