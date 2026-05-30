// Widget test pin for the `Province Overlay` → `Standalone (mobile)`
// Widgetbook use case under `app/lib/widgetbook/catalog_part1.dart`.
//
// Pins two SPEC contracts (Refs #2870 R22 / S9):
//
//  1. The use case is wired into the public `provinceOverlayDirectories`
//     getter under the canonical folder + name (so renaming or removing
//     it surfaces here in CI before reviewers lose the mobile-viewport
//     story for `ProvinceSeaZoneDetailOverlay`).
//  2. The builder pumps without exceptions inside the shared
//     `mobileViewport` (360 × 640 dp `MediaQuery.size`) frame, per
//     `SPEC/ui/mobile-adaptation.md` § 6 and the Widgetbook contract in
//     `SPEC/ui/province-sea-zone-detail-overlay.md`.
//
// At 360 dp (< `kNarrowBreakpoint` = 600 dp) the overlay renders its
// narrow body (`mainAxisSize: MainAxisSize.min`, ~33 % viewport-height
// cap) per `SPEC/ui/in-game-shell-narrow.md` § Province/sea zone detail
// overlay; the pump assertion guards the AC that the narrow story is
// reviewable in Widgetbook without resizing the host window.

import 'dart:ui' as ui;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:colonizethis_app/widgetbook/catalog.dart';

/// Pre-warm the brass nine-patch into Flame's image cache so the
/// overlay's panel chrome (which can reference Flame-cached assets via
/// shared Ct primitives) lays out at declared height. Best-effort; the
/// pump assertions only require the use case to mount.
Future<void> _preWarmFlameImageCache() async {
  try {
    final bytes = await rootBundle.load(
      'assets/images/ui_button_nine_patch.png',
    );
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    Flame.images.add('ui_button_nine_patch.png', frame.image);
  } catch (_) {
    // Best-effort.
  }
}

WidgetbookUseCase _useCase(
  List<WidgetbookNode> directories, {
  required String folderName,
  required String useCaseName,
}) {
  final folder = directories
      .whereType<WidgetbookFolder>()
      .firstWhere(
        (folder) => folder.name == folderName,
        orElse: () =>
            fail('Missing Widgetbook folder: $folderName (got: $directories)'),
      );
  final children = folder.children ?? const <WidgetbookNode>[];
  final useCase = children
      .whereType<WidgetbookUseCase>()
      .firstWhere(
        (uc) => uc.name == useCaseName,
        orElse: () => fail(
          'Missing use case "$useCaseName" in folder "$folderName" '
          '(got: ${children.map((c) => c.name).toList()})',
        ),
      );
  return useCase;
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_preWarmFlameImageCache);

  group(
    'Province Overlay Widgetbook mobile-viewport story (Refs #2870 R22 / S9)',
    () {
      testWidgets(
        'Standalone (mobile) is wired into provinceOverlayDirectories under '
        'the canonical folder + name',
        (WidgetTester tester) async {
          final useCase = _useCase(
            provinceOverlayDirectories,
            folderName: 'Province Overlay',
            useCaseName: 'Standalone (mobile)',
          );
          expect(useCase.builder, isNotNull);
        },
      );

      testWidgets(
        'Standalone (mobile) builder pumps at 360 × 640 dp without '
        'exceptions (exercises < 600 dp narrow body)',
        (WidgetTester tester) async {
          // Match the surface bound by the production `mobileViewport`
          // helper (`SizedBox(width: 360, height: 640)`) so the explicit
          // MediaQuery the helper overlays maps to the surface bounds.
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.binding.setSurfaceSize(const Size(360, 640));

          final useCase = _useCase(
            provinceOverlayDirectories,
            folderName: 'Province Overlay',
            useCaseName: 'Standalone (mobile)',
          );

          await tester.pumpWidget(
            MediaQuery(
              data: const MediaQueryData(size: Size(360, 640)),
              child: MaterialApp(
                home: Scaffold(
                  body: Builder(
                    builder: (BuildContext ctx) => useCase.builder(ctx),
                  ),
                ),
              ),
            ),
          );
          // The overlay reads debug-init game data lazily through the
          // demo getters; let async work settle before sampling.
          await tester.pumpAndSettle(const Duration(milliseconds: 200));

          expect(
            tester.takeException(),
            isNull,
            reason:
                'Mobile-viewport story must pump without exceptions per '
                'SPEC/ui/mobile-adaptation.md § 6 and the Widgetbook AC in '
                'SPEC/ui/province-sea-zone-detail-overlay.md (the '
                '< 600 dp narrow body caps height to ~33 % of the '
                'viewport per SPEC/ui/in-game-shell-narrow.md).',
          );
        },
      );
    },
  );
}
