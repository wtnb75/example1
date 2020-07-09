'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';
const RESOURCES = {
  "main.dart.js": "acab3062af605a88851d3b966f080705",
"assets/fonts/MaterialIcons-Regular.ttf": "56d3ffdef7a25659eab6a68a3fbfaf16",
"assets/FontManifest.json": "01700ba55b08a6141f33e168c4a6c22f",
"assets/NOTICES": "6463bc32ca9a9c81304762373d57a8a3",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "115e937bb829a890521f72d2e664b632",
"assets/workflow/%25E3%2581%25A1%25E3%2581%258E%25E3%2582%258A%25E3%2583%2591%25E3%2583%25B3.yaml": "6dc69f9d700e69af90c38ade52028efc",
"assets/workflow/%25E5%2591%25B3%25E5%2599%258C%25E3%2583%259E%25E3%2583%25A8%25E9%25A3%25AF.yaml": "22e95bae9b1f68c4c7e1a4cf0e666170",
"assets/workflow/%25E3%2582%2586%25E3%2581%25A7%25E3%2581%259F%25E3%2581%25BE%25E3%2581%2594.yaml": "9c2d87acdbb071ede29f03ac39246589",
"assets/workflow/%25E3%2583%25A1%25E3%2583%25AD%25E3%2583%25B3%25E3%2583%2591%25E3%2583%25B31.yaml": "3d5f24b438c6084022125ee5cb2d3ed1",
"assets/workflow/index.yaml": "c5d5cb8cbb54cb872bda6f73e3850173",
"assets/workflow/PullRequest1.yaml": "8b80c75a2fb44526f18c3d0046155f52",
"assets/workflow/%25E8%25B1%259A%25E8%25A7%2592%25E7%2585%25AE.yaml": "79971928eb80c40dc771fa0246ec5a40",
"assets/workflow/%25E3%2583%25AD%25E3%2582%25B3%25E3%2583%25A2%25E3%2582%25B3.yaml": "b1bead598befc4fa6cee2b613347d5b3",
"assets/workflow/%25E3%2581%259D%25E3%2581%25BC%25E3%2582%258D.yaml": "de50696916bb0ca470fc5f5e5eac754a",
"assets/workflow/%25E7%25B4%2585%25E8%258C%25B6.yaml": "4eb920d76378b5ecf238643a76803a34",
"assets/workflow/%25E9%2599%25B8%25E4%25B8%258A%25E6%2595%2599%25E5%25AE%25A4.yaml": "d433288fbe2065b7cd069b967ca4aa9b",
"assets/workflow/%25E3%2583%2581%25E3%2583%25BC%25E3%2582%25BA%25E3%2582%25B9%25E3%2583%2595%25E3%2583%25AC.yaml": "7a26b23e0af67f8fdaac918e882cb8ad",
"assets/AssetManifest.json": "afc603d8df0147c556438433f6257e20",
"index.html": "eb06e752727b54181b27cd4e011a1bc3",
"/": "eb06e752727b54181b27cd4e011a1bc3"
};

// The application shell files that are downloaded before a service worker can
// start.
const CORE = [
  "/",
"main.dart.js",
"index.html",
"assets/NOTICES",
"assets/AssetManifest.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      // Provide a no-cache param to ensure the latest version is downloaded.
      return cache.addAll(CORE.map((value) => new Request(value, {'cache': 'no-cache'})));
    })
  );
});

// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');

      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        return;
      }

      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});

// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#')) {
    key = '/';
  }
  // If the URL is not the the RESOURCE list, skip the cache.
  if (!RESOURCES[key]) {
    return event.respondWith(fetch(event.request));
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache. Ensure the resources are not cached
        // by the browser for longer than the service worker expects.
        var modifiedRequest = new Request(event.request, {'cache': 'no-cache'});
        return response || fetch(modifiedRequest).then((response) => {
          cache.put(event.request, response.clone());
          return response;
        });
      })
    })
  );
});

self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data == 'skipWaiting') {
    return self.skipWaiting();
  }

  if (event.message = 'downloadOffline') {
    downloadOffline();
  }
});

// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey in Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
