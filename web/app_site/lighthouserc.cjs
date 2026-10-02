/**
 * Lighthouse CI (Core Web Vitals and more, brief 21.9 "Technical SEO"), run on
 * the built static site after a fixture build:
 *
 *   SEO_DATA_FILE=data/seo/fixtures/$SITE_COUNTRY.json npm run build
 *   npm run lhci                      # needs Chrome/Chromium; set CHROME_PATH if it is not found
 *
 * Serves dist/ with LHCI's own static server; production headers (CSP etc.)
 * come from vercel.json and are not part of this check.
 *
 * Fixture pages (price, guide, seller) are noindex by design, so they assert
 * every SEO audit except "is-crawlable" instead of the SEO category score.
 */
const country = (process.env.SITE_COUNTRY || '').trim();
if (country !== 'usa' && country !== 'india') throw new Error('lighthouserc: set SITE_COUNTRY=usa|india');

// Indexable static pages: whole SEO category is asserted.
const indexable = {
  usa: ['/index.html', '/es.html', '/legal/privacy-policy.html', '/sellers.html', '/in/dallas.html', '/in.html'],
  india: ['/index.html', '/hi.html', '/legal/privacy-policy.html', '/sellers.html', '/in/kochi.html', '/in/thiruvananthapuram.html'],
}[country];
// Pages built from data/seo/fixtures/<country>.json (noindex in fixture builds).
const fixtures = {
  usa: ['/quotes/dallas/refrigerators.html', '/guides/fridge-size-family-of-four.html', '/sellers/dallas/cool-breeze-appliances.html'],
  india: ['/quotes/bengaluru/refrigerators.html', '/guides/fridge-size-family-of-four.html', '/sellers/bengaluru/sri-lakshmi-electronics.html'],
}[country];

const scores = {
  'categories:performance': ['error', { minScore: 0.9 }],
  'categories:accessibility': ['error', { minScore: 0.95 }],
  'categories:best-practices': ['error', { minScore: 0.9 }],
};
const seoAudits = ['document-title', 'meta-description', 'http-status-code', 'link-text', 'crawlable-anchors', 'image-alt', 'hreflang', 'canonical', 'robots-txt'];
const esc = (p) => p.replace(/[.*+?^${}()|[\]\\/]/g, '\\$&');

module.exports = {
  ci: {
    collect: {
      staticDistDir: './dist',
      url: [...indexable, ...fixtures].map((p) => `http://localhost${p}`),
      numberOfRuns: 1,
      settings: {
        chromeFlags: '--headless=new --no-sandbox --disable-gpu --disable-dev-shm-usage',
        onlyCategories: ['performance', 'accessibility', 'best-practices', 'seo'],
      },
    },
    assert: {
      assertMatrix: [
        {
          matchingUrlPattern: `(${indexable.map(esc).join('|')})$`,
          assertions: { ...scores, 'categories:seo': ['error', { minScore: 0.95 }] },
        },
        {
          matchingUrlPattern: `(${fixtures.map(esc).join('|')})$`,
          assertions: { ...scores, ...Object.fromEntries(seoAudits.map((a) => [a, ['error', { minScore: 1 }]])) },
        },
      ],
    },
    upload: { target: 'filesystem', outputDir: '.lighthouseci/reports' },
  },
};
