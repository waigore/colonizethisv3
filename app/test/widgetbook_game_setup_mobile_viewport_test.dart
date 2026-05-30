// Widget test pin for the `Game Setup` → `Default (mobile)` Widgetbook
// use case under `app/lib/widgetbook/catalog.dart`.
//
// Pins two SPEC contracts (Refs #2870 R22 / S9):
//
//  1. The use case is wired into the public `gameSetupDirectories`
//     getter (so renaming or removing it surfaces here in CI before
//     reviewers lose the mobile-viewport story for the Game Setup
//     surface).
//  2. The builder pumps without exceptions inside the shared
//     `mobileViewport` (360 × 640 dp `MediaQuery.size`) frame, per
//     `SPEC/ui/mobile-adaptation.md` § 6 and the Game Setup Widgetbook
//     contract in `SPEC/ui/game-setup.md`.
//
// At 360 dp (< `kGameSetupNarrowMaxWidth` = 500 dp) the slot rows stack
// vertically per `SPEC/ui/game-setup.md` § Mobile; the pump assertion
// guards the AC that the narrow story is reviewable in Widgetbook
// without resizing the host window.

import 'dart:ui' as ui;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:colonizethis_app/widgetbook/catalog.dart';

/// Pre-warm the brass nine-patch into Flame's image cache so the
/// pixelArt Game Setup story (consumed by some sibling stories) lays
/// out at declared height, even though the mobile use case under test
/// uses the `plain` variant. Best-effort; tests do not require pixel-
/// perfect chrome.
Future<void> _preWarmFlameImageCache() async {
  try {
    final bytes = await rootBundle.load(
      'assets/images/ui_button_nine_patch.png',
    );
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    Flame.images.add('ui_button_nine_patch.png', frame.image);
  } catch (_) {
    // Best-effort: layout assertions only require the use case to mount.
  }
}

WidgetbookUseCase _useCase(
  List<WidgetbookNode> directories, {
  required String folderName,
  required String useCaseName,
}) {
  final folder = directories.whereType<WidgetbookFolder>().firstWhere(
    (folder) => folder.name == folderName,
    orElse: () =>
        fail('Missing Widgetbook folder: $folderName (got: $directories)'),
  );
  final children = folder.children ?? const <WidgetbookNode>[];
  final useCase = children.whereType<WidgetbookUseCase>().firstWhere(
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
    'Game Setup Widgetbook mobile-viewport story (Refs #2870 R22 / S9)',
    () {
      testWidgets(
        'Default (mobile) is wired into gameSetupDirectories under the '
        'canonical folder + name',
        (WidgetTester tester) async {
          final useCase = _useCase(
            gameSetupDirectories,
            folderName: 'Game Setup',
            useCaseName: 'Default (mobile)',
          );
          expect(useCase.builder, isNotNull);
        },
      );

      testWidgets(
        'Default (mobile) builder pumps at 360 × 640 dp without exceptions '
        '(exercises < 500 dp slot stacking)',
        (WidgetTester tester) async {
          // Match the surface bound by the production `mobileViewport`
          // helper (`SizedBox(width: 360, height: 640)`) so the explicit
          // MediaQuery the helper overlays maps to the surface bounds.
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.binding.setSurfaceSize(const Size(360, 640));

          final useCase = _useCase(
            gameSetupDirectories,
            folderName: 'Game Setup',
            useCaseName: 'Default (mobile)',
          );

          await tester.pumpWidget(
            MediaQuery(
              data: const MediaQueryData(size: Size(360, 640)),
              child: MaterialApp(
                home: Builder(
                  builder: (BuildContext ctx) => useCase.builder(ctx),
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 16));

          expect(
            tester.takeException(),
            isNull,
            reason:
                'Mobile-viewport story must pump without exceptions per '
                'SPEC/ui/mobile-adaptation.md § 6 and the Widgetbook AC in '
                'SPEC/ui/game-setup.md (the < 500 dp narrow override stacks '
                'each player-slot row at the 360 dp story width).',
          );
        },
      );
    },
  );
}
