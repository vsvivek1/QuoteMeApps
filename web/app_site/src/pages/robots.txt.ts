import fs from 'node:fs';
import path from 'node:path';
import type { APIRoute } from 'astro';
import { WEB_ROOT, abs } from '../lib/site';

// AI training/scraping bots are disallowed; search engines stay allowed (Section 20.5).
export const GET: APIRoute = () => {
  const { user_agents } = JSON.parse(fs.readFileSync(path.join(WEB_ROOT, 'shared', 'ai_bots.json'), 'utf8'));
  const lines = [
    '# AI training and scraping crawlers: not allowed. Also enforced by the Vercel Firewall AI-bot rule.',
    ...user_agents.map((ua: string) => `User-agent: ${ua}`),
    'Disallow: /',
    '',
    '# Search engines and everyone else',
    'User-agent: *',
    'Allow: /',
    'Disallow: /link/',
    '',
    `Sitemap: ${abs('/sitemap.xml')}`,
    '',
  ];
  return new Response(lines.join('\n'), { headers: { 'Content-Type': 'text/plain; charset=utf-8' } });
};
