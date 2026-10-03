// "Choose your town" picker (components/TownPicker.astro). Progressive enhancement:
// every trigger is a link to /in that works without JavaScript. Nothing here runs
// on page load except reading the remembered town. The town list (/towns-index.json)
// is fetched when the dialog first opens, PIN/ZIP codes (/towns-postal.json) only when
// digits are typed, geolocation is requested only when the person presses "Use my
// location", and the map code (Leaflet) is fetched only when they press "Pick on a map".
import { STORAGE_KEY, nearestTown, readTown, roundDistance, saveTown, type PickTown } from './town-core';

interface Config {
  strings: Record<string, string>;
  unit: 'km' | 'mi';
  /** URL segment of the page language ('' for English). */
  lang: string;
}

interface Town extends PickTown {
  state: string;
  stateSeg: string;
  major: boolean;
  search: string;
}

type IndexFile = { v: 1; states: [string, string, string][]; towns: [string, string, number, number, number, 0 | 1, string?][] };

const MAX_SHOWN = 50;
const fill = (s: string, vars: Record<string, string>) => s.replace(/\{(\w+)\}/g, (m, k) => vars[k] ?? m);
const norm = (v: string) => v.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').trim();

function showRemembered(): void {
  const town = readTown();
  if (!town) return;
  for (const el of document.querySelectorAll<HTMLElement>('[data-town-label]')) el.textContent = town.name;
  for (const el of document.querySelectorAll<HTMLElement>('[data-town-current]')) {
    el.hidden = false;
    const link = el.querySelector<HTMLAnchorElement>('a[data-town-link]');
    if (link) {
      link.href = `/${town.path}`;
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
  const more = $<HTMLElement>('[data-town-more]');
  const result = $<HTMLElement>('[data-town-result]');
  const locate = $<HTMLButtonElement>('[data-town-locate]');
  const mapToggle = $<HTMLButtonElement>('[data-town-map-toggle]');
  const mapLabel = $<HTMLElement>('[data-town-map-label]');
  const mapWrap = $<HTMLElement>('[data-town-map-wrap]');
  const mapEl = $<HTMLElement>('#town-map');

  // Pages in a state's language link to that language's town pages for towns of that state.
  const href = (t: Town) => (config.lang && t.stateSeg === config.lang ? `/${config.lang}/${t.path}` : `/${t.path}`);

  let towns: Town[] = [];
  let byPath = new Map<string, Town>();
  let loading: Promise<Town[]> | null = null;
  const loadTowns = () =>
    (loading ??= (async () => {
      const res = await fetch('/towns-index.json', { credentials: 'omit' });
      if (!res.ok) throw new Error(String(res.status));
      const data = (await res.json()) as IndexFile;
      towns = data.towns.map(([slug, name, si, lat, lng, major, extra]) => {
        const [stateSlug, stateName, stateSeg] = data.states[si];
        return {
          path: `${stateSlug}/${slug}`,
          name,
          lat,
          lng,
          state: stateName,
          stateSeg,
          major: major === 1,
          search: norm([name, stateName, ...(extra ?? '').split('|')].join(' ')),
        };
      });
      byPath = new Map(towns.map((t) => [t.path, t]));
      return towns;
    })().catch((e) => {
      loading = null;
      throw e;
    }));

  let postal: Promise<Record<string, string>> | null = null;
  const loadPostal = () =>
    (postal ??= fetch('/towns-postal.json', { credentials: 'omit' })
      .then((r) => (r.ok ? (r.json() as Promise<Record<string, string>>) : {}))
      .catch(() => {
        postal = null;
        return {};
      }));

  const item = (t: Town) => {
    const li = document.createElement('li');
    const a = document.createElement('a');
    a.href = href(t);
    a.dataset.town = t.path;
    a.dataset.name = t.name;
    if (config.lang) a.lang = 'en';
    const name = document.createElement('span');
    name.textContent = t.name;
    const state = document.createElement('small');
    state.textContent = t.state;
    a.append(name, state);
    li.append(a);
    return li;
  };

  let seq = 0;
  const render = async () => {
    const id = ++seq;
    const q = norm(search.value);
    let hits: Town[];
    if (/^\d{3,}$/.test(q)) {
      const codes = await loadPostal();
      if (id !== seq) return;
      const paths = q.length >= 5 ? [codes[q]] : Object.keys(codes).filter((c) => c.startsWith(q)).map((c) => codes[c]);
      hits = [...new Set(paths)].map((p) => byPath.get(p!)).filter((t): t is Town => Boolean(t));
    } else if (q) {
      const starts: Town[] = [];
      const inside: Town[] = [];
      for (const t of towns) {
        const n = norm(t.name);
        if (n.startsWith(q)) starts.push(t);
        else if (t.search.includes(q)) inside.push(t);
      }
      hits = [...starts, ...inside];
    } else {
      hits = towns.filter((t) => t.major);
    }
    list.replaceChildren(...hits.slice(0, MAX_SHOWN).map(item));
    empty.hidden = hits.length > 0;
    more.hidden = hits.length <= MAX_SHOWN;
    more.textContent = fill(s.moreResults, { n: String(MAX_SHOWN) });
  };

  const prepare = async () => {
    list.setAttribute('aria-busy', 'true');
    if (!towns.length) more.hidden = false;
    more.textContent = s.loadingList;
    try {
      await loadTowns();
      await render();
    } catch {
      more.hidden = false;
      more.textContent = s.listError;
    } finally {
      list.removeAttribute('aria-busy');
    }
  };

  let opener: HTMLElement | null = null;
  const open = (trigger: HTMLElement | null) => {
    opener = trigger;
    dialog.showModal();
    search.focus();
    void prepare();
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
    if (a?.dataset.town && a.dataset.name) saveTown({ path: a.dataset.town, name: a.dataset.name });
  });

  search.addEventListener('input', () => {
    if (towns.length) void render();
  });
  search.addEventListener('keydown', (e) => {
    if (e.key !== 'Enter') return;
    const first = list.querySelector<HTMLAnchorElement>('li a');
    if (first) {
      e.preventDefault();
      first.click();
    }
  });

  const distance = (km: number) => fill(config.unit === 'mi' ? s.distanceMi : s.distanceKm, { n: String(roundDistance(km, config.unit)) });

  const say = (text: string) => {
    result.replaceChildren();
    const p = document.createElement('p');
    p.textContent = text;
    result.append(p);
  };

  /** Shows the nearest town for a point (location or map pin) with a link to its page. */
  let mapApi: { show: (lat: number, lng: number, town: PickTown) => void } | null = null;
  const pick = async (lat: number, lng: number, focus: boolean) => {
    try {
      await loadTowns();
    } catch {
      return say(s.listError);
    }
    const { town, km } = nearestTown(towns, lat, lng);
    mapApi?.show(lat, lng, town);
    result.replaceChildren();
    const p = document.createElement('p');
    p.textContent = fill(km > 150 ? s.far : s.nearest, { name: town.name, distance: distance(km) });
    const go = document.createElement('a');
    go.className = 'btn sm';
    go.href = href(town);
    go.dataset.town = town.path;
    go.dataset.name = town.name;
    go.textContent = fill(s.go, { name: town.name });
    result.append(p, go);
    if (focus) go.focus();
    else result.scrollIntoView({ block: 'nearest' });
  };

  locate.addEventListener('click', () => {
    if (!('geolocation' in navigator)) return say(s.locationError);
    say(s.locating);
    locate.disabled = true;
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        locate.disabled = false;
        void pick(pos.coords.latitude, pos.coords.longitude, true);
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
        const [{ mountMap }] = await Promise.all([import('./town-map'), loadTowns()]);
        mapEl.textContent = '';
        // Dots for the larger towns only; a click anywhere still snaps to the nearest of all towns.
        mapApi = mountMap(mapEl, towns.filter((t) => t.major), (lat, lng) => void pick(lat, lng, false));
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
