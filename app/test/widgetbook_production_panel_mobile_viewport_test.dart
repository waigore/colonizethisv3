// Widget test pin for the `Production Panel` → `Full availability (mobile)`
// Widgetbook use case under `app/lib/widgetbook/catalog_part2.dart`.
//
// Pins three SPEC contracts (Refs #2870 R22 / S9):
//
//  1. The use case is wired into the public `productionPanelDirectories`
//     getter (so renaming or removing it surfaces here in CI before
//     reviewers lose the mobile-viewport story for the production
//     surface).
//  2. The builder mounts without exceptions inside the shared
//     `mobileViewport` (360 × 640 dp `MediaQuery.size`) frame, per
//     `SPEC/ui/mobile-adaptation.md` § 6 and `SPEC/ui/production-panel.md`
//     § Widgetbook.
//  3. At 360 dp the production panel selects its **narrow** layout branch,
//     deterministically signalled by `kProductionPanelNarrowLayoutKey`
//     mounted on the `_ProductionPanelNarrowLayout` subtree, per
//     `SPEC/ui/production-panel.md` § Acceptance criteria — Narrow layout
//     key. The companion `kProductionPanelWideLayoutKey` MUST NOT be
//     present in the same render so the test fails loudly if a future
//     change accidentally mounts both branches at narrow widths.
//
// Together these pins enforce that the player-app exposes a reviewable
// `< 600 dp` Production-panel story without window-resizing the
// Widgetbook host (so cross-cutting `Refs #2870` mobile-adaptation review
// can catch overflow / layout regressions before they land), and that the
// SPEC § Narrow layout key contract continues to hold in CI.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:colonizethis_app/features/game/widgets/production_panel.dart';
import 'package:colonizethis_app/widgetbook/catalog.dart';

/// Locate the single use-case with [useCaseName] inside the
/// [WidgetbookFolder] whose name matches [folderName], failing with a
/// readable matcher message if the folder or use case is missing. Mirrors
/// the helper used by `widgetbook_diplomacy_panel_mobile_viewport_test.dart`.
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

  group(
    'Production Panel Widgetbook mobile-viewport story (Refs #2870 R22 / S9)',
    () {
      testWidgets(
        'Full availability (mobile) is wired into productionPanelDirectories '
        'under the canonical folder + name',
        (WidgetTester tester) async {
          final useCase = _useCase(
            productionPanelDirectories,
            folderName: 'Production Panel',
            useCaseName: 'Full availability (mobile)',
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
        'Partial availability (mobile) is wired into productionPanelDirectories '
        'under the canonical folder + name',
        (WidgetTester tester) async {
          final useCase = _useCase(
            productionPanelDirectories,
            folderName: 'Production Panel',
            useCaseName: 'Partial availability (mobile)',
          );
          expect(useCase.builder, isNotNull);
        },
      );

      testWidgets(
        'Full availability (mobile) builder pumps at 360 × 640 dp without '
        'exceptions and selects the narrow layout branch '
        '(kProductionPanelNarrowLayoutKey)',
        (WidgetTester tester) async {
          // Match the surface bound by the production `mobileViewport`
          // helper (`SizedBox(width: 360, height: 640)`) so the explicit
          // MediaQuery the helper overlays maps to the surface bounds.
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.binding.setSurfaceSize(const Size(360, 640));

          final useCase = _useCase(
            productionPanelDirectories,
            folderName: 'Production Panel',
            useCaseName: 'Full availability (mobile)',
          );

          // `mobileViewport` inside the story calls `MediaQuery.of(context)`,
          // which requires a MediaQuery ancestor — Widgetbook itself
          // provides one at runtime via the addon chain. In tests we
          // supply one explicitly (sized to the test surface) so the
          // inner copyWith resolves cleanly to 360 × 640.
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
                'SPEC/ui/mobile-adaptation.md § 6 and the Widgetbook AC in '
                'SPEC/ui/production-panel.md.',
          );

          expect(
            find.byKey(kProductionPanelNarrowLayoutKey),
            findsOneWidget,
            reason:
                'At 360 dp (< kNarrowBreakpoint = 600 dp), '
                'SPEC/ui/production-panel.md § Acceptance criteria — Narrow '
                'layout key requires the narrow layout subtree keyed by '
                'kProductionPanelNarrowLayoutKey so the Available subpanel '
                'stacks above the Allocation subpanel inside a scrollable '
                'container.',
          );
          expect(
            find.byKey(kProductionPanelWideLayoutKey),
            findsNothing,
            reason:
                'The wide layout subtree must not be mounted at narrow '
                'widths so the SPEC § Narrow layout key contract holds for '
                'exactly one branch per render.',
          );
        },
      );
    },
  );
}
