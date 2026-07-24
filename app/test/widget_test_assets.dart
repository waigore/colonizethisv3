// Shared widget-test asset scaffolding for the nine-patch button image
// (Refs #3656). Many app panel/widget tests render `CtNinePatchButton`, which
// resolves `assets/images/ui_button_nine_patch.png` via the asset bundle and a
// preloaded Flame image cache. Before this helper, the asset-bundle mock and
// the Flame cache preload were copy-pasted across ~20+ test files; this
// centralizes both behaviors so call sites share one implementation
// (`colonizethis-component-structure.mdc`: extract at 2+ uses).

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Logical asset key for the nine-patch button image, as resolved through the
/// Flutter asset bundle.
const String kNinePatchAssetKey = 'assets/images/ui_button_nine_patch.png';

/// Flame image-cache key the panel widgets look up (the asset basename) plus
/// the full asset key, both registered for resilience across invocation dirs.
const List<String> _kNinePatchFlameCacheKeys = <String>[
  'ui_button_nine_patch.png',
  kNinePatchAssetKey,
];

// 1x1 transparent PNG served for the nine-patch asset key. The nine-patch
// widgets only require decodable bytes for layout, not the production artwork,
// so an embedded constant keeps the mock free of real `dart:io` file I/O.
//
// Using `Uint8List.fromList` guarantees the backing buffer length equals the
// byte length, so `ByteData.view(...buffer)` exposes exactly the PNG bytes.
// Real file I/O is intentionally avoided here: this helper may be invoked from
// inside a `testWidgets` body (which runs in a fake-async zone where a real
// filesystem future never completes), so it must stay synchronous apart from
// microtask scheduling.
final Uint8List _ninePatchPngBytes = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+X2ioAAAAASUVORK5CYII=',
  ),
);

/// Installs a mock `flutter/assets` message handler that serves the nine-patch
/// button PNG bytes. Cleanup is registered via [addTearDown], so calling this
/// from `setUpAll` removes the handler after the suite and calling it from a
/// test body removes it after that test.
Future<void> installNinePatchAssetMock() async {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMessageHandler('flutter/assets', (message) async {
    final key = const StringCodec().decodeMessage(message);
    if (key == kNinePatchAssetKey) {
      return ByteData.view(_ninePatchPngBytes.buffer);
    }
    return null;
  });
  addTearDown(() {
    messenger.setMockMessageHandler('flutter/assets', null);
  });
}

/// Preloads the nine-patch image into the Flame image cache so widget tests are
/// stable regardless of the directory `flutter test` is invoked from. Failures
/// are swallowed: tests stay resilient when the asset cannot be decoded on a
/// given host.
Future<void> preloadNinePatchImage() async {
  try {
    final bytes = await rootBundle.load(kNinePatchAssetKey);
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    for (final key in _kNinePatchFlameCacheKeys) {
      Flame.images.add(key, frame.image);
    }
  } catch (_) {
    // Keep tests resilient when asset prewarm fails on this host.
  }
}

/// Convenience for the common `setUpAll` pattern: installs the asset mock and
/// then preloads the Flame cache. Equivalent to calling
/// [installNinePatchAssetMock] followed by [preloadNinePatchImage].
Future<void> setUpNinePatchAssets() async {
  await installNinePatchAssetMock();
  await preloadNinePatchImage();
}
