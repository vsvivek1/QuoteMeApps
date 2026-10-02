// Types for og.mjs (shared Open Graph image renderer).
export const OG_WIDTH: 1200;
export const OG_HEIGHT: 630;

export interface OgColors {
  bg: string;
  fg: string;
  muted: string;
  accent: string;
  accentSoft: string;
  band: string;
  bandFg: string;
}

export interface OgTemplate {
  colors: OgColors;
  brand: string;
  logoSvg?: string;
  kicker?: string;
  title: string;
  detail?: string;
  footer: string;
  footerRight?: string;
}

export interface OgRenderer {
  svg(o: OgTemplate): string;
  png(o: OgTemplate): Buffer;
  wrap(text: string, size: number, weight: 'regular' | 'bold', maxWidth: number, maxLines: number): string[];
  measure(text: string, size: number, weight: 'regular' | 'bold'): number;
}

/** fontDir: absolute path of web/shared/fonts. */
export function createOgRenderer(libs: { hb: unknown; Resvg: unknown; fontDir: string }): OgRenderer;
