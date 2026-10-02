# Fonts

No font files are committed here; the app pulls fonts via `google_fonts` (or bundles them in `assets/fonts/` at release time).

| Use | Font | Why | Licence |
|---|---|---|---|
| UI + wordmark (Latin, both apps, en-US / es-US / en-IN) | **Inter** (400, 500, 700) | Neutral geometric sans, excellent at small sizes, tabular figures for prices | SIL Open Font License 1.1 |
| Hindi (hi-IN, I Want India) | **Noto Sans Devanagari** (400, 700) | Metrics pair well with Inter; full conjunct shaping | SIL Open Font License 1.1 |

- Google Fonts: https://fonts.google.com/specimen/Inter and https://fonts.google.com/noto/specimen/Noto+Sans+Devanagari
- OFL 1.1 lets us bundle, embed and ship these fonts in the apps and marketing artwork; the licence text must travel with any redistributed font files (`OFL.txt`) and the fonts must not be sold on their own.

## Placeholder renderer

`tool/branding/generate.py` does not bundle fonts. It uses whatever is installed: DejaVu Sans Bold for Latin
and the first Devanagari-capable font fontconfig finds (Noto Sans Devanagari, else GNU FreeSans) with Pillow's
Raqm layout engine for correct Hindi shaping. Install `fonts-noto-core` (Linux) to get closer to final artwork.
SVG templates reference `Inter, 'Noto Sans Devanagari', 'DejaVu Sans', Arial, sans-serif`.
