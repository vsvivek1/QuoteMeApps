// "Choose your town" picker (components/TownPicker.astro). Progressive enhancement:
// every trigger is a link to /in that works without JavaScript. Nothing here runs
// on page load except reading the remembered town; geolocation is requested only
// when the person presses "Use my location", and the map code (Leaflet) is fetched
// only when they press "Pick on a map".
import { STORAGE_KEY, nearestTown, readTown, roundDistance, saveTown, type PickTown } from './town-core';

interface Config {
  strings: Record<string, string>;
  unit: 'km' | 'mi';
}

const fill = (s: string, vars: Record<string, string>) => s.replace(/\{(\w+)\}/g, (m, k) => vars[k] ?? m);

function showRemembered(): void {
  const town = readTown();
  if (!town) return;
  for (const el of document.querySelectorAll<HTMLElement>('[data-town-label]')) el.textContent = town.name;
  for (const el of document.querySelectorAll<HTMLElement>('[data-town-current]')) {
    el.hidden = false;
    const link = el.querySelector<HTMLAnchorElement>('a[data-town-link]');
    if (link) {
      link.href = `/in/${town.slug}`;
      link.textContent = town.name;
    }
  }
  for (const el of document.querySelectorAll<HTMLElement>('[data-town-default]')) el.hidden = true;
}

function init(): void {
  showRemembered();
  const dialog = document.getElementById('town-picker') as HTMLDialogElement | null;
  if (!dialog || typeof dialog.showModal !== 'function') return;
  const config = JSON.parse(dialog.dataset.config ?? '{}') as Config;
  const s = config.strings;
  const $ = <T extends HTMLElement>(sel: string) => dialog.querySelector<T>(sel)!;
  const search = $<HTMLInputElement>('[data-town-search]');
  const list = $<HTMLUListElement>('[data-town-list]');
  const empty = $<HTMLElement>('[data-town-empty]');
  const result = $<HTMLElement>('[data-town-result]');
  const locate = $<HTMLButtonElement>('[data-town-locate]');
  const mapToggle = $<HTMLButtonElement>('[data-town-map-toggle]');
  const mapLabel = $<HTMLElement>('[data-town-map-label]');
  const mapWrap = $<HTMLElement>('[data-town-map-wrap]');
  const mapEl = $<HTMLElement>('#town-map');

  const links = [...list.querySelectorAll<HTMLAnchorElement>('a[data-town]')];
  const towns: PickTown[] = links.map((a) => ({
    slug: a.dataset.town!,
    name: a.dataset.name!,
    lat: Number(a.dataset.lat),
    lng: Number(a.dataset.lng),
  }));

  let opener: HTMLElement | null = null;
  const open = (trigger: HTMLElement | null) => {
    opener = trigger;
    dialog.showModal();
    search.focus();
  };
  dialog.addEventListener('close', () => {
    opener?.focus();
    opener = null;
  });

  document.addEventListener('click', (e) => {
    const trigger = (e.target as Element | null)?.closest<HTMLElement>('[data-town-open]');
    if (!trigger || e.defaultPrevented || (e as MouseEvent).button > 0 || (e as MouseEvent).metaKey || (e as MouseEvent).ctrlKey) return;
    e.preventDefault();
    open(trigger);
  });
  $<HTMLButtonElement>('[data-town-close]').addEventListener('click', () => dialog.close());
  // Click on the backdrop (outside the dialog box) closes it.
  dialog.addEventListener('click', (e) => {
    if (e.target !== dialog) return;
    const r = dialog.getBoundingClientRect();
    const { clientX: x, clientY: y } = e as MouseEvent;
    if (x < r.left || x > r.right || y < r.top || y > r.bottom) dialog.close();
  });

  // Remember a town whenever one is chosen in the picker.
  dialog.addEventListener('click', (e) => {
    const a = (e.target as Element | null)?.closest<HTMLAnchorElement>('a[data-town]');
    if (a?.dataset.town && a.dataset.name) saveTown({ slug: a.dataset.town, name: a.dataset.name });
  });

  const norm = (v: string) => v.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').trim();
  search.addEventListener('input', () => {
    const q = norm(search.value);
    let shown = 0;
    for (const li of list.children as HTMLCollectionOf<HTMLElement>) {
      const hit = !q || (li.dataset.search ?? '').includes(q);
      li.hidden = !hit;
      if (hit) shown++;
    }
    empty.hidden = shown > 0;
  });
  search.addEventListener('keydown', (e) => {
    if (e.key !== 'Enter') return;
    const first = list.querySelector<HTMLAnchorElement>('li:not([hidden]) a');
    if (first) {
      e.preventDefault();
      first.click();
    }
  });

  const distance = (km: number) => fill(config.unit === 'mi' ? s.distanceMi : s.distanceKm, { n: String(roundDistance(km, config.unit)) });

  /** Shows the nearest town for a point (location or map pin) with a link to its page. */
  let mapApi: { show: (lat: number, lng: number, town: PickTown) => void } | null = null;
  const pick = (lat: number, lng: number, focus: boolean) => {
    const { town, km } = nearestTown(towns, lat, lng);
    mapApi?.show(lat, lng, town);
    result.replaceChildren();
    const p = document.createElement('p');
    p.textContent = fill(km > 150 ? s.far : s.nearest, { name: town.name, distance: distance(km) });
    const go = document.createElement('a');
    go.className = 'btn sm';
    go.href = `/in/${town.slug}`;
    go.dataset.town = town.slug;
    go.dataset.name = town.name;
    go.textContent = fill(s.go, { name: town.name });
    result.append(p, go);
    if (focus) go.focus();
    else result.scrollIntoView({ block: 'nearest' });
  };

  const say = (text: string) => {
    result.replaceChildren();
    const p = document.createElement('p');
    p.textContent = text;
    result.append(p);
  };

  locate.addEventListener('click', () => {
    if (!('geolocation' in navigator)) return say(s.locationError);
    say(s.locating);
    locate.disabled = true;
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        locate.disabled = false;
        pick(pos.coords.latitude, pos.coords.longitude, true);
      },
      (err) => {
        locate.disabled = false;
        say(err.code === err.PERMISSION_DENIED ? s.locationDenied : s.locationError);
      },
      { enableHighAccuracy: false, timeout: 15000, maximumAge: 600000 },
    );
  });

  let mapLoading: Promise<void> | null = null;
  mapToggle.addEventListener('click', () => {
    const show = mapWrap.hidden;
    mapWrap.hidden = !show;
    mapToggle.setAttribute('aria-expanded', String(show));
    mapLabel.textContent = show ? s.hideMap : s.showMap;
    if (!show) return;
    mapLoading ??= (async () => {
      mapEl.setAttribute('aria-busy', 'true');
      mapEl.textContent = s.mapLoading;
      try {
        const { mountMap } = await import('./town-map');
        mapEl.textContent = '';
        mapApi = mountMap(mapEl, towns, (lat, lng) => pick(lat, lng, false));
      } catch {
        mapEl.textContent = s.mapError;
        mapLoading = null;
      } finally {
        mapEl.removeAttribute('aria-busy');
      }
    })();
  });

  // Another tab chose a town: keep the header in sync.
  window.addEventListener('storage', (e) => {
    if (e.key === STORAGE_KEY) showRemembered();
  });
}

init();
