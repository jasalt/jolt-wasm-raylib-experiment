/* Establish cross-origin isolation on static GitHub Pages for Emscripten pthreads. */
const headers = {
  'Cross-Origin-Embedder-Policy': 'require-corp',
  'Cross-Origin-Opener-Policy': 'same-origin'
};
self.addEventListener('install', event => event.waitUntil(self.skipWaiting()));
self.addEventListener('activate', event => event.waitUntil(self.clients.claim()));
self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET') return;
  event.respondWith(fetch(event.request).then(response => {
    if (response.type === 'opaque') return response;
    const next = new Headers(response.headers);
    for (const [name, value] of Object.entries(headers)) next.set(name, value);
    if (new URL(event.request.url).pathname.endsWith('.wasm')) next.set('Content-Type', 'application/wasm');
    return new Response(response.body, {status: response.status, statusText: response.statusText, headers: next});
  }));
});
