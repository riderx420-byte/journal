const CACHE_NAME = 'journal-v1';
const ASSETS = ['/', '/index.html', '/manifest.json'];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(ASSETS))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key))
      );
    })
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((response) => response || fetch(event.request))
  );
});

// Handle background sync for notifications
self.addEventListener('periodicsync', (event) => {
  if (event.tag === 'journal-reminder') {
    event.waitUntil(checkAndSendReminder());
  }
});

async function checkAndSendReminder() {
  const now = new Date();
  if (now.getHours() === 21 && now.getMinutes() === 0) {
    const registration = await self.registration;
    registration.showNotification('📔 Time to Journal!', {
      body: 'Take a moment to reflect on your day.',
      tag: 'journal-reminder'
    });
  }
}
