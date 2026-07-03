// Widget test pin for the `Production Panel` → `Full availability` and
// `Partial availability` Widgetbook use cases under
// `app/lib/widgetbook/catalog_part1.dart` / `catalog_part2.dart`.
//
// Pins the SPEC/ui/production-panel.md § Widgetbook + § Integration
// contract that production stories are wired through `ProviderScope` and
// the same preview helpers the running app uses, so the Available
// **Breakdown** button is visible and tapping it opens the live
// `ProductionCommodityBreakdownDialog` (Refs #2862 S6).
//
// Three pins:
//
//  1. The `Full availability` and `Partial availability` stories are
//     wired into the canonical `productionPanelDirectories` folder under
//     their expected names so renaming or removing either surfaces in CI
//     before reviewers lose the dark-theme review surface.
//  2. The `Full availability` story pumps without exceptions in the
//     editorial-monocle Widgetbook host, and the Available **Breakdown**
//     `CtActionTextButton` is mounted (text `Breakdown` per
//     `production_breakdown` l10n). Without the SPEC § Widgetbook
//     ProviderScope wiring the `onOpenCommodityBreakdown` callback would
//     be `null` and the button would not render.
//  3. Tapping the **Breakdown** button opens the live
//     `ProductionCommodityBreakdownDialog` (per
//     SPEC/ui/production-panel.md § Acceptance criteria — Breakdown live
//     update) and the dialog itself pumps without exceptions.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:colonizethis_app/features/game/widgets/chrome/ct_action_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/production_commodity_breakdown_dialog.dart';
import 'package:colonizethis_app/widgetbook/catalog.dart';
import 'support/widgetbook_test_harness.dart';

WidgetbookUseCase findWidgetbookUseCase(
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
  return children
      .whereType<WidgetbookUseCase>()
      .firstWhere(
        (uc) => uc.name == useCaseName,
        orElse: () => fail(
          'Missing use case "$useCaseName" in folder "$folderName" '
          '(got: ${children.map((c) => c.name).toList()})',
        ),
      );
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'Production Panel Widgetbook live-breakdown wiring (Refs #2862 S6)',
    () {
      testWidgets(
        'Full availability is wired into productionPanelDirectories under '
        'the canonical folder + name',
        (WidgetTester tester) async {
          final useCase = findWidgetbookUseCase(
            productionPanelDirectories,
            folderName: 'Production Panel',
            useCaseName: 'Full availability',
          );
          expect(useCase.builder, isNotNull);
        },
      );

      testWidgets(
        'Partial availability is wired into productionPanelDirectories under '
        'the canonical folder + name',
        (WidgetTester tester) async {
          final useCase = findWidgetbookUseCase(
            productionPanelDirectories,
            folderName: 'Production Panel',
            useCaseName: 'Partial availability',
          );
          expect(useCase.builder, isNotNull);
        },
      );

      testWidgets(
        'Full availability builder pumps without exceptions and renders the '
        'Available Breakdown button (SPEC § Widgetbook — ProviderScope + '
        'preview helpers so Breakdown is visible)',
        (WidgetTester tester) async {
          addTearDown(() => tester.binding.setSurfaceSize(null));
          // Keep the surface large enough for the wide layout so the
          // Available subpanel paints its full header row (the SPEC
          // narrow stack at <600 dp also renders the Breakdown button,
          // but the wide layout matches the default story viewport).
          await tester.binding.setSurfaceSize(const Size(900, 700));

          final useCase = findWidgetbookUseCase(
            productionPanelDirectories,
            folderName: 'Production Panel',
            useCaseName: 'Full availability',
          );

          await tester.pumpWidget(
            Builder(builder: (BuildContext ctx) => useCase.builder(ctx)),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 16));

          expect(
            tester.takeException(),
            isNull,
            reason:
                'Widgetbook story must pump without exceptions per '
                'SPEC/ui/production-panel.md § Widgetbook (Refs #2862 S6).',
          );

          final breakdownButton = find.widgetWithText(
            CtActionTextButton,
            'Breakdown',
          );
          expect(
            breakdownButton,
            findsOneWidget,
            reason:
                'SPEC/ui/production-panel.md § Widgetbook requires '
                'production stories to wire ProviderScope + preview helpers '
                'so the Available "Breakdown" CtActionTextButton renders '
                '(onOpenCommodityBreakdown != null). Refs #2862 S6 / S10.',
          );
        },
      );

      testWidgets(
        'Tapping the Available Breakdown button opens the live '
        'ProductionCommodityBreakdownDialog (SPEC § AC — Breakdown live update)',
        (WidgetTester tester) async {
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.binding.setSurfaceSize(const Size(1100, 900));

          final useCase = findWidgetbookUseCase(
            productionPanelDirectories,
            folderName: 'Production Panel',
            useCaseName: 'Full availability',
          );

          await tester.pumpWidget(
            Builder(builder: (BuildContext ctx) => useCase.builder(ctx)),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 16));

          expect(
            find.byType(ProductionCommodityBreakdownDialog),
            findsNothing,
            reason:
                'The Breakdown dialog must only mount after the user taps '
                'the Available Breakdown button (no auto-open).',
          );

          final breakdownButton = find.widgetWithText(
            CtActionTextButton,
            'Breakdown',
          );
          expect(breakdownButton, findsOneWidget);

          await tester.tap(breakdownButton);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 16));

          expect(
            tester.takeException(),
            isNull,
            reason:
                'Opening the live Breakdown dialog must not throw — '
                'SPEC/ui/production-panel.md § Widgetbook + § AC Breakdown '
                'live update (Refs #2862 S6).',
          );
          expect(
            find.byType(ProductionCommodityBreakdownDialog),
            findsOneWidget,
            reason:
                'Tapping the Available "Breakdown" button must push the '
                'live ProductionCommodityBreakdownDialog onto the story\'s '
                'Navigator per SPEC/ui/production-panel.md § Widgetbook '
                '(Refs #2862 S6).',
          );
        },
      );
    },
  );
}
