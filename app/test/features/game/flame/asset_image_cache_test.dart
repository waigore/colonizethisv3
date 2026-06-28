import 'dart:ui' as ui;

import 'package:colonizethis_app/features/game/flame/asset_image_cache.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  suppressLogsForTests();

  group('AssetImageCache', () {
    test('load decodes each asset once and marks isLoaded', () async {
      final cache = _FakeImageCache(const ['a', 'b', 'c']);
      expect(cache.isLoaded, isFalse);

      await cache.load();

      expect(cache.isLoaded, isTrue);
      expect(cache.decodeCalls, 3);
      expect(cache.getIcon('a'), isNotNull);
      expect(cache.hasIcon('b'), isTrue);
    });

    test('load is idempotent: a second call is a no-op', () async {
      final cache = _FakeImageCache(const ['a', 'b']);

      await cache.load();
      expect(cache.decodeCalls, 2);

      await cache.load();
      expect(cache.decodeCalls, 2, reason: 'second load must not re-decode');
      expect(cache.isLoaded, isTrue);
    });

    test('error path clears state, stays unloaded, and rethrows', () async {
      final cache = _FakeImageCache(const ['a', 'b'], failOn: 'b');

      await expectLater(cache.load(), throwsA(isA<StateError>()));

      expect(cache.isLoaded, isFalse);
      // Partial successes are cleared so a retry starts clean.
      expect(cache.getIcon('a'), isNull);
      expect(cache.hasIcon('a'), isFalse);
    });

    test('a failed load can be retried successfully', () async {
      final cache = _FakeImageCache(const ['a'], failOn: 'a');
      await expectLater(cache.load(), throwsA(isA<StateError>()));
      expect(cache.isLoaded, isFalse);

      cache.failOn = null;
      await cache.load();

      expect(cache.isLoaded, isTrue);
      expect(cache.getIcon('a'), isNotNull);
    });

    test('keyed getIcon/hasIcon guard null and empty ids', () async {
      final cache = _FakeImageCache(const ['a']);
      await cache.load();

      expect(cache.getIcon(null), isNull);
      expect(cache.getIcon(''), isNull);
      expect(cache.hasIcon(null), isFalse);
      expect(cache.hasIcon(''), isFalse);
      expect(cache.getIcon('missing'), isNull);
      expect(cache.hasIcon('missing'), isFalse);
    });
  });
}

ui.Image _makeImage() {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder);
  final picture = recorder.endRecording();
  return picture.toImageSync(1, 1);
}

class _FakeImageCache extends AssetImageCache {
  _FakeImageCache(this._ids, {this.failOn});

  final List<String> _ids;
  String? failOn;
  int decodeCalls = 0;

  @override
  Iterable<String> get assetIds => _ids;

  @override
  String assetPath(String assetId) => 'assets/$assetId.png';

  @override
  String get loadLogLabel => 'fake icons';

  @override
  Future<ui.Image> decodeAsset(String assetPath) async {
    decodeCalls++;
    final marker = failOn;
    if (marker != null && assetPath.contains('/$marker.png')) {
      throw StateError('boom: $assetPath');
    }
    return _makeImage();
  }

  ui.Image? getIcon(String? id) {
    if (id == null || id.isEmpty) return null;
    return imageForId(id);
  }

  bool hasIcon(String? id) {
    if (id == null || id.isEmpty) return false;
    return hasImageForId(id);
  }
}
