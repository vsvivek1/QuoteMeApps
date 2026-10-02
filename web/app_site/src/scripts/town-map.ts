// Map for the town picker. Loaded with import() only when "Pick on a map" is pressed,
// so Leaflet (bundled from npm, no CDN) and its CSS never touch normal page loads.
// Tiles: OpenStreetMap's standard tile server, with the attribution its policy requires.
import * as L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import type { PickTown } from './town-core';

export function mountMap(el: HTMLElement, towns: PickTown[], onPick: (lat: number, lng: number) => void) {
  const map = L.map(el, { scrollWheelZoom: false, zoomSnap: 0.5, worldCopyJump: false });
  L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 18,
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
  }).addTo(map);
  map.fitBounds(L.latLngBounds(towns.map((t) => [t.lat, t.lng] as [number, number])).pad(0.08));

  for (const t of towns) {
    L.circleMarker([t.lat, t.lng], { radius: 6, weight: 2, fillOpacity: 0.9, className: 'town-dot' })
      .bindTooltip(t.name, { direction: 'top', offset: [0, -6] })
      .on('click', (e) => {
        L.DomEvent.stopPropagation(e);
        onPick(t.lat, t.lng);
      })
      .addTo(map);
  }

  let pin: L.CircleMarker | null = null;
  let line: L.Polyline | null = null;
  let chosen: L.CircleMarker | null = null;
  map.on('click', (e: L.LeafletMouseEvent) => onPick(e.latlng.lat, e.latlng.lng));
  // Size is known only once the dialog has laid the map out.
  requestAnimationFrame(() => map.invalidateSize());

  return {
    show(lat: number, lng: number, town: PickTown) {
      pin?.remove();
      line?.remove();
      chosen?.remove();
      const same = Math.abs(lat - town.lat) < 1e-6 && Math.abs(lng - town.lng) < 1e-6;
      if (!same) {
        line = L.polyline([[lat, lng], [town.lat, town.lng]], { weight: 2, dashArray: '6 6', className: 'town-line', interactive: false }).addTo(map);
        pin = L.circleMarker([lat, lng], { radius: 7, weight: 3, fillOpacity: 1, className: 'town-pin', interactive: false }).addTo(map);
      }
      chosen = L.circleMarker([town.lat, town.lng], { radius: 10, weight: 3, fillOpacity: 1, className: 'town-chosen', interactive: false })
        .bindTooltip(town.name, { permanent: true, direction: 'top', offset: [0, -10] })
        .addTo(map);
      map.panTo([town.lat, town.lng]);
    },
  };
}
