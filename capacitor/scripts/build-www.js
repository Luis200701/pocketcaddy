// Kopiert nur die eigentlichen App-Dateien aus dem Repo-Hauptordner nach
// capacitor/www/ - das ist der Ordner, den Capacitor in die iOS-App packt.
// Bewusst keine Kopie von marketing/, wrangler.jsonc usw., die gehoeren
// nicht in die App.
const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..', '..');
const out = path.resolve(__dirname, '..', 'www');
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

console.log('capacitor/www gebaut: ' + files.concat(dirs).join(', '));
