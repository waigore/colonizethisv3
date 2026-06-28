import 'dart:io';

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  group('preloadEditorialMonocleFonts', () {
    test('skipInTests returns without loading fonts', () async {
      await expectLater(
        preloadEditorialMonocleFonts(skipInTests: true),
        completes,
      );
    });

    test('loads bundled Cinzel display weights when not skipped', () async {
      GoogleFonts.config.allowRuntimeFetching = false;
      await expectLater(
        preloadEditorialMonocleFonts(skipInTests: false),
        completes,
      );
    });

    test('propagates load failures instead of swallowing them', () {
      final String themesSrc = File('lib/config/themes.dart').readAsStringSync();
      expect(themesSrc, contains('rethrow'));
      expect(
        themesSrc,
        isNot(contains('// Intentionally swallowed')),
      );
    });
  });

  group('production font bootstrap policy', () {
    test('main.dart disables google_fonts runtime fetching', () {
      final String mainSrc = File('lib/main.dart').readAsStringSync();
      expect(
        mainSrc,
        contains('GoogleFonts.config.allowRuntimeFetching = false'),
      );
    });

    test('pubspec bundles Cinzel under google_fonts/', () {
      final String pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('- google_fonts/'));
      expect(pubspec, contains('family: Cinzel'));
      expect(pubspec, contains('google_fonts/Cinzel-Regular.ttf'));
      expect(pubspec, contains('google_fonts/Cinzel-Bold.ttf'));
    });

    test('bundled Cinzel TTF files exist on disk', () {
      for (final String name in <String>[
        'Cinzel-Regular.ttf',
        'Cinzel-Medium.ttf',
        'Cinzel-SemiBold.ttf',
        'Cinzel-Bold.ttf',
      ]) {
        expect(
          File('google_fonts/$name').existsSync(),
          isTrue,
          reason: 'missing bundled font $name',
        );
      }
    });
  });
}
