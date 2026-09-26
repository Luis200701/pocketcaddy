// Kopiert nur die eigentlichen App-Dateien aus dem Repo-Hauptordner sowie
// die eigene _headers-Datei nach play/dist/ - das ist der Ordner, den
// dieser Cloudflare Worker als statische Assets ausliefert.
// Bewusst keine Kopie von marketing/, club-portal/, capacitor/,
// ANLEITUNG.md, README.md, wrangler.jsonc usw. - die gehoeren nicht in
// diesen Worker.
const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..', '..');
const playDir = path.resolve(__dirname, '..');
const out = path.resolve(playDir, 'dist');

const files = ['index.html', 'manifest.json', 'service-worker.js'];
const dirs = ['icons'];

fs.rmSync(out, { recursive: true, force: true });
fs.mkdirSync(out, { recursive: true });

files.forEach(function (f) {
  fs.copyFileSync(path.join(repoRoot, f), path.join(out, f));
});
dirs.forEach(function (d) {
  fs.cpSync(path.join(repoRoot, d), path.join(out, d), { recursive: true });
});

fs.copyFileSync(path.join(playDir, '_headers'), path.join(out, '_headers'));

console.log('play/dist gebaut: ' + files.concat(dirs).concat(['_headers']).join(', '));
