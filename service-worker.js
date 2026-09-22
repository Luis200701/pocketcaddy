// Pocket Caddy: haelt die Grundoberflaeche im Zwischenspeicher, damit die
// App auch bei schlechter oder fehlender Verbindung sofort aufgeht statt
// eine leere Seite zu zeigen. Runden-Daten von Supabase laufen weiterhin
// normal ueber das Netz, die werden hier bewusst nicht angefasst.

const CACHE_NAME = 'pocketcaddy-v65';
const APP_SHELL = [
  './',
  './index.html',
  './manifest.json',
  './icons/icon-192.png',
  './icons/icon-512.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const req = event.request;

  // Nur eigene GET-Anfragen behandeln. Supabase, CDN-Bibliotheken und
  // alles andere normal durchlassen, damit dort immer aktuelle Daten
  // ankommen statt veralteter Zwischenspeicher-Inhalte.
  if (req.method !== 'GET' || new URL(req.url).origin !== location.origin) {
    return;
  }

  // Die Seite selbst (Navigation zu index.html) bewusst Netz-zuerst statt
  // Zwischenspeicher-zuerst: sonst zeigt ein frischer Deploy trotz neuer
  // CACHE_NAME erst beim ZWEITEN Neuladen die Aenderung - der erste Aufruf
  // bekommt noch die alte, gecachte index.html ausgeliefert, bevor der neue
  // Service Worker ueberhaupt aktiv ist. Nur bei fehlendem Netz faellt das
  // auf den Zwischenspeicher zurueck (Offline-Fall bleibt erhalten).
  if (req.mode === 'navigate') {
    event.respondWith(
      fetch(req)
        .then((res) => {
          if (res && res.status === 200) {
            const copy = res.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(req, copy));
          }
          return res;
        })
        .catch(() => caches.match(req))
    );
    return;
  }

  event.respondWith(
    caches.match(req).then((cached) => {
      const network = fetch(req)
        .then((res) => {
          if (res && res.status === 200) {
            const copy = res.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(req, copy));
          }
          return res;
        })
        .catch(() => cached);
      // Sofort aus dem Zwischenspeicher antworten, falls vorhanden (schnell),
      // im Hintergrund trotzdem aktualisieren fuer den naechsten Aufruf.
      return cached || network;
    })
  );
});
