/**
 * Lighthouse CI (Core Web Vitals and more, brief 21.9 / 21.10), run on the built
 * static site after a fixture build:
 *
 *   BUILD_NOW=2026-10-02T00:00:00Z npm run build:fixtures
 *   npm run lhci                      # needs Chrome/Chromium; set CHROME_PATH if it is not found
 *
 * Fixture articles (and the country page listing only them) are noindex by
 * design, so they assert every SEO audit except "is-crawlable" instead of the
 * SEO category score.
 */
const indexable = ['/index.html', '/editorial-policy.html'];
const fixtures = ['/a/sample-pune-heat-ac-demand.html', '/india.html'];

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
