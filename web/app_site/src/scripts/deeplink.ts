// Builds the "Open in the app" link for /r/:id, /q/:id, /s/:id fallback pages.
const root = document.getElementById('deeplink');
const button = document.getElementById('open-in-app') as HTMLAnchorElement | null;
if (root && button) {
  const kind = root.dataset.kind ?? 'r';
  const match = location.pathname.match(/^\/([rqs])\/([A-Za-z0-9_-]{1,64})\/?$/);
  if (!match || match[1] !== kind) {
    button.hidden = true;
  } else {
    const path = `/${kind}/${match[2]}`;
    const httpsUrl = `${location.origin}${path}${location.search}`;
    if (/android/i.test(navigator.userAgent)) {
      const fallback = encodeURIComponent(root.dataset.play ?? httpsUrl);
      button.href = `intent://${location.host}${path}${location.search}#Intent;scheme=https;package=${root.dataset.package};S.browser_fallback_url=${fallback};end`;
    } else {
      // iOS ignores Universal Links tapped on the same domain; the Smart App Banner covers it.
      button.href = httpsUrl;
    }
  }
}
export {};
