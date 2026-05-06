@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PWA web assets', () {
    late Map<String, dynamic> manifest;

    setUpAll(() {
      manifest =
          jsonDecode(File('web/manifest.json').readAsStringSync())
              as Map<String, dynamic>;
    });

    test('manifest has installable product metadata', () {
      expect(manifest['name'], 'Flip-Out');
      expect(manifest['short_name'], 'Flip-Out');
      expect(manifest['id'], '.');
      expect(manifest['start_url'], '.');
      expect(manifest['scope'], '.');
      expect(manifest['display'], 'standalone');
      expect(manifest['background_color'], '#f8fafc');
      expect(manifest['theme_color'], '#0d9488');
      expect(manifest['description'], contains('No-Limit Holdem'));
      expect(manifest['prefer_related_applications'], isFalse);
    });

    test('manifest includes required any and maskable icons', () {
      final icons = (manifest['icons'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      expect(
        icons,
        contains(
          allOf(
            containsPair('src', 'icons/Icon-192.png'),
            containsPair('sizes', '192x192'),
            containsPair('type', 'image/png'),
          ),
        ),
      );
      expect(
        icons,
        contains(
          allOf(
            containsPair('src', 'icons/Icon-512.png'),
            containsPair('sizes', '512x512'),
            containsPair('type', 'image/png'),
          ),
        ),
      );
      expect(
        icons,
        contains(
          allOf(
            containsPair('src', 'icons/Icon-maskable-192.png'),
            containsPair('sizes', '192x192'),
            containsPair('purpose', 'maskable'),
          ),
        ),
      );
      expect(
        icons,
        contains(
          allOf(
            containsPair('src', 'icons/Icon-maskable-512.png'),
            containsPair('sizes', '512x512'),
            containsPair('purpose', 'maskable'),
          ),
        ),
      );

      for (final icon in icons) {
        final source = icon['src'] as String;
        final file = File('web/$source');
        expect(file.existsSync(), isTrue, reason: '$source must exist');
        expect(file.lengthSync(), greaterThan(0), reason: '$source is empty');
      }
    });

    test('index registers the custom PWA service worker', () {
      final index = File('web/index.html').readAsStringSync();

      expect(index, contains('<link rel="manifest" href="manifest.json">'));
      expect(index, contains('pwa_service_worker.js'));
      expect(index, contains("navigator.serviceWorker.register"));
      expect(index, contains('Flip-Out'));
    });

    test('custom service worker handles fetches for app shell caching', () {
      final serviceWorker = File('web/pwa_service_worker.js');
      expect(serviceWorker.existsSync(), isTrue);

      final source = serviceWorker.readAsStringSync();
      expect(source, contains("self.addEventListener('install'"));
      expect(source, contains("self.addEventListener('activate'"));
      expect(source, contains("self.addEventListener('fetch'"));
      expect(source, contains('caches.open'));
      expect(source, contains('index.html'));
    });

    test('custom service worker awaits navigation fallback cache matches', () {
      final source = File('web/pwa_service_worker.js').readAsStringSync();

      expect(
        source,
        contains(
          "return (await cache.match('./')) || "
          "(await cache.match('index.html'));",
        ),
      );
      expect(source, isNot(contains("|| cache.match('index.html')")));
    });
  });
}
