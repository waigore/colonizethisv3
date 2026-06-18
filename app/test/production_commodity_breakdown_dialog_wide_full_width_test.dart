// Pins the wide-viewport full-width column-distribution contract for the
// `ProductionCommodityBreakdownDialog` (PROD20001) per
// `SPEC/ui/production-commodity-breakdown-dialog.md` § Layout (Wide-path
// full-width column distribution) and § Acceptance Criteria (Refs #3509).
//
// On the wide path (viewport width >= 900 dp) the 7-column `DataTable` must
// fill the full `CtDialogShell` content column with no trailing gap: the
// `Commodity` column receives a larger share and the five phase columns plus
// `Total` share the remainder evenly. The narrow path is covered by
// `production_commodity_breakdown_dialog_spec_test.dart` and
// `production_commodity_breakdown_dialog_320dp_min_viewport_test.dart`.

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/production_commodity_breakdown_dialog.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

void main() {
  suppressLogsForTests();

  group(
    'productionBreakdownWideColumnContentWidths (Refs #3509)',
    () {
      test(
        'distributes the content budget so numeric columns are equal and the '
        'Commodity column is strictly wider; widths + chrome == availableWidth',
        () {
          const availableWidth = 832.0;
          const phaseColumnCount = 5;
          const columnSpacing = 24.0;
          const horizontalMargin = 12.0;

          final widths = productionBreakdownWideColumnContentWidths(
            availableWidth: availableWidth,
            phaseColumnCount: phaseColumnCount,
            columnSpacing: columnSpacing,
            horizontalMargin: horizontalMargin,
          );

          // Commodity + 5 phases + Total.
          expect(widths.length, phaseColumnCount + 2);

          final commodity = widths.first;
          final numeric = widths.skip(1).toList();

          for (final w in numeric) {
            expect(
              (w - numeric.first).abs() <= 1.0,
              isTrue,
              reason: 'all numeric column widths must be equal (±1 px)',
            );
            expect(
              commodity > w,
              isTrue,
              reason: 'Commodity column must be strictly wider than each '
                  'numeric column',
            );
          }

          final chrome =
              horizontalMargin * 2 + columnSpacing * (widths.length - 1);
          final total = widths.reduce((a, b) => a + b) + chrome;
          expect(
            (total - availableWidth).abs() <= 1.0,
            isTrue,
            reason:
                'distributed widths + chrome must equal availableWidth (±1 px) '
                'so the table fills the content column with no trailing gap',
          );
        },
      );

      test('returns non-negative widths for a degenerate / unbounded width', () {
        final unbounded = productionBreakdownWideColumnContentWidths(
          availableWidth: double.infinity,
          phaseColumnCount: 5,
          columnSpacing: 24,
          horizontalMargin: 12,
        );
        expect(unbounded.length, 7);
        expect(unbounded.every((w) => w >= 0), isTrue);

        final tooSmall = productionBreakdownWideColumnContentWidths(
          availableWidth: 10,
          phaseColumnCount: 5,
          columnSpacing: 24,
          horizontalMargin: 12,
        );
        expect(tooSmall.length, 7);
        expect(tooSmall.every((w) => w >= 0), isTrue);
      });
    },
  );

  group(
    'ProductionCommodityBreakdownDialog wide-path full width '
    '(SPEC/ui/production-commodity-breakdown-dialog.md, Refs #3509)',
    () {
      Future<void> pumpWide(
        WidgetTester tester, {
        Size surfaceSize = const Size(900, 1400),
      }) async {
        addTearDown(tester.view.reset);
        tester.view.physicalSize = surfaceSize;
        tester.view.devicePixelRatio = 1.0;

        final result = getDebugInitGameResult();
        final game = result.game;
        final humanPlayerId = game.players.firstWhere((p) => p.isHuman).id;
        final player = game.playerById(humanPlayerId) ?? game.players.first;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppThemes.editorialMonocle,
              localizationsDelegates:
                  AppLocalizationsBinding.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        barrierColor: EditorialMonoclePalette.dialogScrim,
                        builder: (_) => ProductionCommodityBreakdownDialog(
                          game: game,
                          player: player,
                          topology: result.combinedTopology,
                          tileMapByRegion: result.tileMapByRegion,
                          currentOrders: const Orders(),
                        ),
                      );
                    },
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
      }

      testWidgets(
        'DataTable fills the full CtDialogShell content column (no trailing gap)',
        (WidgetTester tester) async {
          await pumpWide(tester);

          expect(tester.takeException(), isNull);

          // Content-column width derived from the same constants the shell
          // uses: viewport - 2×Dialog.insetPadding - 2×body-padding. At a
          // 900 dp viewport the Dialog.insetPadding constrains the frame
          // below the 900 maxWidth cap. The DecoratedBox frame border is a
          // decoration painted over the child (it does not consume layout
          // space), so only the body padding is subtracted for the content
          // column.
          const viewport = 900.0;
          final frameWidth = viewport - 2 * CtSpacing.l; // inset padding
          final contentWidth = frameWidth - 2 * CtSpacing.l; // body padding

          final tableWidth =
              tester.getSize(find.byType(DataTable)).width;
          expect(
            (tableWidth - contentWidth).abs() <= 1.0,
            isTrue,
            reason:
                'wide-path DataTable width ($tableWidth) must equal the '
                'CtDialogShell content-column width ($contentWidth) within '
                '±1 px so no unused horizontal band remains to the right of '
                'the table',
          );
        },
      );

      testWidgets(
        'Commodity column is strictly wider than the equal numeric columns',
        (WidgetTester tester) async {
          await pumpWide(tester);

          double headerWidth(int index) => tester
              .getSize(
                find.byKey(ValueKey<String>('prodBreakdownHeaderCol_$index')),
              )
              .width;

          final commodity = headerWidth(0);
          final numericCount = EconomyPreviewStockpilePhase.values.length + 1;
          final numericWidths = <double>[
            for (var i = 1; i <= numericCount; i++) headerWidth(i),
          ];

          for (final w in numericWidths) {
            expect(
              (w - numericWidths.first).abs() <= 1.0,
              isTrue,
              reason: 'phase + Total columns must be equal width (±1 px)',
            );
            expect(
              commodity > w,
              isTrue,
              reason:
                  'Commodity column ($commodity) must be strictly wider than '
                  'each numeric column ($w)',
            );
          }
        },
      );

      testWidgets(
        'wide path mounts no horizontal SingleChildScrollView or Scrollbar',
        (WidgetTester tester) async {
          await pumpWide(tester);

          expect(tester.takeException(), isNull);

          final horizontalScroll = find.byWidgetPredicate(
            (w) =>
                w is SingleChildScrollView &&
                w.scrollDirection == Axis.horizontal,
          );
          expect(
            horizontalScroll,
            findsNothing,
            reason:
                'wide path sizes the table to fit exactly — no horizontal '
                'scroll viewport should mount',
          );

          final scrollbarAroundTable = find.ancestor(
            of: find.byType(DataTable),
            matching: find.byType(Scrollbar),
          );
          expect(scrollbarAroundTable, findsNothing);
        },
      );
    },
  );
}
