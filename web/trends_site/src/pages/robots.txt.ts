import fs from 'node:fs';
import path from 'node:path';
import type { APIRoute } from 'astro';
import { WEB_ROOT, abs, site } from '../lib/site';

export const GET: APIRoute = () => {
  const { user_agents } = JSON.parse(fs.readFileSync(path.join(WEB_ROOT, 'shared', 'ai_bots.json'), 'utf8'));
  const lines = [
    '# AI training and scraping crawlers: not allowed. Also enforced by the Vercel Firewall AI-bot rule.',
    ...user_agents.map((ua: string) => `User-agent: ${ua}`),
    'Disallow: /',
    '',
    'User-agent: *',
    'Allow: /',
    '',
    `Sitemap: ${abs('/sitemap.xml')}`,
    ...(site.newsSitemap ? [`Sitemap: ${abs('/news-sitemap.xml')}`] : []),
    '',
  ];
  return new Response(lines.join('\n'), { headers: { 'Content-Type': 'text/plain; charset=utf-8' } });
};
