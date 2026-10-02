import type { APIRoute } from 'astro';
import { brandColors } from '../lib/site';

// Country colour tokens from branding/<country>/colors.json, served as a static
// stylesheet (no inline <style>, so the CSP can stay strict).
const vars = (c: Record<string, string>) =>
  Object.entries(c)
    .map(([k, v]) => `  --${k.replace(/[A-Z]/g, (m) => `-${m.toLowerCase()}`)}: ${v};`)
    .join('\n');

export const GET: APIRoute = () => {
  const { light, dark } = brandColors();
  const css = `:root {\n${vars(light)}\n  color-scheme: light dark;\n}\n@media (prefers-color-scheme: dark) {\n  :root {\n${vars(dark)}\n  }\n}\n`;
  return new Response(css, { headers: { 'Content-Type': 'text/css; charset=utf-8' } });
};
