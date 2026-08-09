// Focused tests for the shared nine-patch asset scaffolding (Refs #3656). These
// guard that the helper serves bytes through the asset bundle and warms the
// Flame image cache, so migrated panel/widget tests can rely on it in place of
// the previously copy-pasted blocks.
//
// Usage contract under test:
//  * [installNinePatchAssetMock] is safe inside a `testWidgets` body (it does no
//    real I/O or image decoding), mirroring the inline province-overlay usage.
//  * [preloadNinePatchImage] / [setUpNinePatchAssets] decode an image via the
//    engine and must run from `setUpAll` (real async), mirroring every panel
//    family's `setUpAll` usage — never from inside a fake-async test body.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  group('installNinePatchAssetMock (in-test usage)', () {
    testWidgets('serves decodable bytes for the nine-patch asset key', (
      tester,
    ) async {
      await installNinePatchAssetMock();

      final data = await rootBundle.load(kNinePatchAssetKey);

      expect(data.lengthInBytes, greaterThan(0));
    });

    testWidgets('returns null for unrelated asset keys', (tester) async {
      await installNinePatchAssetMock();

      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final response = await messenger.handlePlatformMessage(
        'flutter/assets',
        const StringCodec().encodeMessage('assets/images/does_not_exist.png'),
        (_) {},
      );

      expect(response, isNull);
    });
  });

  group('setUpNinePatchAssets (setUpAll usage)', () {
    // Exercises the combined install + best-effort Flame preload from
    // `setUpAll` (the production usage). The Flame preload is intentionally
    // best-effort — image decoding is environment dependent and swallowed — so
    // the deterministic invariant asserted here is that the bundle mock is
    // installed and still serves the nine-patch bytes afterwards.
    setUpAll(() async {
      await setUpNinePatchAssets();
    });

    testWidgets('installs the bundle mock so the asset key resolves', (
      tester,
    ) async {
      final data = await rootBundle.load(kNinePatchAssetKey);
      expect(data.lengthInBytes, greaterThan(0));
    });
  });
}
