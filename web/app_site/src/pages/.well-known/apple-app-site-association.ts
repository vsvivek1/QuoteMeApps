import type { APIRoute } from 'astro';
import { PLACEHOLDER, site, warnOnce } from '../../lib/site';

// iOS Universal Links. Served as application/json (see vercel.json headers), no redirects.
export const GET: APIRoute = () => {
  let teamId = site.ios.teamId;
  if (teamId && !/^[A-Z0-9]{10}$/.test(teamId)) throw new Error(`APPLE_TEAM_ID "${teamId}" must be 10 upper-case letters/digits`);
  if (!teamId) {
    warnOnce('APPLE_TEAM_ID unset: apple-app-site-association uses a placeholder, Universal Links will not verify.');
    teamId = PLACEHOLDER.teamId;
  }
  const appIDs = site.ios.bundleIds.map((b) => `${teamId}.${b}`);
  const body = {
    applinks: {
      details: [
        {
          appIDs,
          components: [
            { '/': '/r/*', comment: 'Shared request' },
            { '/': '/q/*', comment: 'Quote' },
            { '/': '/s/*', comment: 'Seller profile' },
          ],
        },
      ],
    },
  };
  return new Response(JSON.stringify(body, null, 2) + '\n', { headers: { 'Content-Type': 'application/json' } });
};
