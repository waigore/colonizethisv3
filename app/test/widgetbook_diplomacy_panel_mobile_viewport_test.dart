// Widget test pin for the `Diplomacy Panel` → `Mobile viewport — narrow
// rows (≤ 500 dp)` Widgetbook use case added by Refs #2870 R22 / S9.
//
// Pins two SPEC contracts:
//
//  1. The use case is wired into the public `diplomacyPanelDirectories`
//     getter (so renaming or removing it surfaces here in CI before
//     reviewers lose the mobile-viewport story for the diplomacy
//     surface).
//  2. The builder mounts without exceptions inside the shared
//     `mobileViewport` (360 × 640 dp `MediaQuery.size`) frame and
//     selects the narrow `_DiplomacyRow` body — a `Column` — for at
//     least one rendered faction row, per
//     `SPEC/ui/diplomacy-panel.md` § Responsive layout and the issue's
//     AC "Mobile-viewport Widgetbook story renders narrow rows".
//
// The narrow body is the deterministic signal that the responsive
// variant is reviewable in Widgetbook without resizing — at 360 dp
// (< `kDiplomacyRowNarrowMaxWidth` = 500 dp) the diplomacy faction-row
// body builder selects the `Column` arrangement.

import 'dart:ui' as ui;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';
import 'package:colonizethis_app/widgetbook/catalog.dart';

/// Pre-warm the brass nine-patch into Flame's image cache so action
/// buttons inside the diplomacy panel lay out at their declared height
/// (matches the helper used by `diplomacy_panel_narrow_layout_test.dart`
/// and `panels_320dp_min_viewport_test.dart`).
Future<void> _preWarmFlameImageCache() async {
  try {
    final bytes = await rootBundle.load(
      'assets/images/ui_button_nine_patch.png',
    );
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    Flame.images.add('ui_button_nine_patch.png', frame.image);
  } catch (_) {
    // Best-effort: the layout assertion below only requires the body
    // widget type, not pixel-perfect chrome.
  }
}

/// Locate the single use-case with [useCaseName] inside the
/// [WidgetbookFolder] whose name matches [folderName], failing with a
/// readable matcher message if the folder or use case is missing.
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
    'Diplomacy Panel Widgetbook mobile-viewport story (Refs #2870 R22 / S9)',
    () {
      testWidgets(
        'use case is wired into diplomacyPanelDirectories under the '
        'canonical folder + name',
        (WidgetTester tester) async {
          final useCase = _useCase(
            diplomacyPanelDirectories,
            folderName: 'Diplomacy Panel',
            useCaseName: 'Mobile viewport — narrow rows (≤ 500 dp)',
          );
          // Smoke: the getter returns a builder closure (the constructor
          // contract for `WidgetbookUseCase`). The deeper pump assertion
          // lives in the second test below so this one fails fast on
          // wiring regressions even if the panel itself becomes
          // expensive to mount.
          expect(useCase.builder, isNotNull);
        },
      );

      testWidgets(
        'builder pumps at 360 × 640 dp without exceptions and selects the '
        'narrow Column body for at least one faction row',
        (WidgetTester tester) async {
          // Match the surface bound by the production `mobileViewport`
          // helper (`SizedBox(width: 360, height: 640)`) so the explicit
          // MediaQuery the helper overlays maps to the surface bounds.
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.binding.setSurfaceSize(const Size(360, 640));

          final useCase = _useCase(
            diplomacyPanelDirectories,
            folderName: 'Diplomacy Panel',
            useCaseName: 'Mobile viewport — narrow rows (≤ 500 dp)',
          );

          // `mobileViewport` inside the story calls `MediaQuery.of(context)`,
          // which requires a MediaQuery ancestor — Widgetbook itself
          // provides one at runtime via the addon chain. In tests we
          // supply one explicitly (sized to the test surface) so the
          // inner copyWith resolves cleanly to 360 × 640.
          await tester.pumpWidget(
            MediaQuery(
              data: const MediaQueryData(size: Size(360, 640)),
              child: Builder(
                builder: (BuildContext ctx) => useCase.builder(ctx),
              ),
            ),
          );
          // Drive past the post-mount frame so async font / image
          // dependencies inside the panel settle before we sample the
          // widget tree.
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 16));

          expect(
            tester.takeException(),
            isNull,
            reason:
                'Mobile-viewport story must pump without exceptions per '
                'SPEC/ui/mobile-adaptation.md § 6 and the new AC in '
                'SPEC/ui/diplomacy-panel.md.',
          );

          // Locate at least one faction-row body keyed by the public
          // `kDiplomacyRowBodyKeyPrefix` prefix and confirm it is a
          // `Column` (narrow variant per
          // `SPEC/ui/diplomacy-panel.md` § Responsive layout).
          final Finder bodyFinder = find.byWidgetPredicate(
            (Widget w) {
              final Key? key = w.key;
              if (key is! ValueKey<String>) return false;
              return key.value.startsWith(kDiplomacyRowBodyKeyPrefix);
            },
            description:
                'faction-row body keyed by kDiplomacyRowBodyKeyPrefix',
          );
          expect(
            bodyFinder,
            findsWidgets,
            reason:
                'Debug-init-game must seed at least one discovered '
                'faction so the diplomacy panel surfaces a row body.',
          );
          final Widget firstBody = tester.widget(bodyFinder.first);
          expect(
            firstBody,
            isA<Column>(),
            reason:
                'At the mobileViewport (360 dp ≤ kDiplomacyRowNarrowMaxWidth = '
                '500 dp), SPEC/ui/diplomacy-panel.md § Responsive layout '
                'requires the narrow Column body so action buttons drop '
                'below the info column.',
          );
        },
      );
    },
  );
}
