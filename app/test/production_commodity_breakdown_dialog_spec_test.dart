// Pins SPEC/ui/production-commodity-breakdown-dialog.md contract for the
// read-only commodity breakdown modal opened from ProductionScreen.

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_dialog_shell.dart';
import 'package:colonizethis_app/features/game/widgets/production_commodity_breakdown_dialog.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/providers/production_allocation_provider.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

import 'support/panel_test_fixtures.dart';

class _SeededProductionDesiredOutputNotifier
    extends ProductionDesiredOutputNotifier {
  _SeededProductionDesiredOutputNotifier(this._initial);

  final Map<String, int> _initial;

  @override
  Map<String, int> build() => _initial;
}

void main() {
  suppressLogsForTests();

  group(
    'ProductionCommodityBreakdownDialog '
    '(SPEC/ui/production-commodity-breakdown-dialog.md)',
    () {
      Future<void> pumpDialog(
        WidgetTester tester, {
        Map<String, int>? desiredOutput,
        Size surfaceSize = const Size(900, 1400),
      }) async {
        addTearDown(tester.view.reset);
        tester.view.physicalSize = surfaceSize;
        tester.view.devicePixelRatio = 1.0;

        // Lightweight fixture (no ~7-11s getDebugInitGameResult() map
        // generation, Refs #3656). The delta-colour pins below are driven by the
        // economy-preview pipeline's Consumption/Production phases off the
        // player's workerPool labour + stockpile commodities, not owned tiles, so
        // a tile-less hand-built game reproduces them (topology / tileMapByRegion
        // contribute nothing here).
        final game = buildProductionBreakdownDeltaTestGame();
        final humanPlayerId = game.players.firstWhere((p) => p.isHuman).id;
        final player = game.playerById(humanPlayerId) ?? game.players.first;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              if (desiredOutput != null)
                productionDesiredOutputProvider.overrideWith(
                  () => _SeededProductionDesiredOutputNotifier(desiredOutput),
                ),
            ],
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
                          topology: const MapTopology(),
                          tileMapByRegion: null,
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
        'renders one DataTable with leading + per-phase + total columns',
        (WidgetTester tester) async {
          await pumpDialog(tester);
          expect(find.byType(ProductionCommodityBreakdownDialog), findsOneWidget);
          expect(find.byType(DataTable), findsOneWidget);

          final dataTable = tester.widget<DataTable>(find.byType(DataTable));
          final expected = 1 + EconomyPreviewStockpilePhase.values.length + 1;
          expect(dataTable.columns.length, expected);
        },
      );

      testWidgets(
        'renders the commodity-breakdown title and a Close button',
        (WidgetTester tester) async {
          await pumpDialog(tester);
          expect(find.text('Commodity breakdown'), findsOneWidget);
          expect(
            find.widgetWithText(CtNinePatchButton, 'Close'),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'title text uses EditorialMonoclePalette.accent (Refs #2862 S4)',
        (WidgetTester tester) async {
          await pumpDialog(tester);
          final title = tester.widget<Text>(find.text('Commodity breakdown'));
          expect(title.style?.color, EditorialMonoclePalette.accent);
        },
      );

      testWidgets(
        'zero delta cells use EditorialMonoclePalette.muted (Refs #2862 S4)',
        (WidgetTester tester) async {
          await pumpDialog(tester);
          final zeroCells = tester
              .widgetList<Text>(find.text('0'))
              .where((t) => t.style?.color == EditorialMonoclePalette.muted);
          expect(zeroCells, isNotEmpty);
        },
      );

      testWidgets(
        'positive delta cells use EditorialMonoclePalette.success (Refs #2862 S4)',
        (WidgetTester tester) async {
          await pumpDialog(
            tester,
            desiredOutput: const {'lumber_from_timber': 5},
          );
          final positiveCells = tester
              .widgetList<Text>(find.textContaining('+'))
              .where((t) => t.style?.color == EditorialMonoclePalette.success);
          expect(positiveCells, isNotEmpty);
        },
      );

      testWidgets(
        'negative delta cells use EditorialMonoclePalette.danger (Refs #2862 S4)',
        (WidgetTester tester) async {
          await pumpDialog(
            tester,
            desiredOutput: const {'lumber_from_timber': 5},
          );
          final negativeCells = tester
              .widgetList<Text>(
                find.byWidgetPredicate(
                  (w) =>
                      w is Text &&
                      w.data != null &&
                      w.data!.startsWith('-') &&
                      w.style?.color == EditorialMonoclePalette.danger,
                ),
              )
              .toList();
          expect(negativeCells, isNotEmpty);
        },
      );

      testWidgets(
        'showDialog route uses EditorialMonoclePalette.dialogScrim barrier',
        (WidgetTester tester) async {
          await pumpDialog(tester);
          final route = ModalRoute.of(
            tester.element(find.byType(ProductionCommodityBreakdownDialog)),
          );
          expect(route?.barrierColor, EditorialMonoclePalette.dialogScrim);
        },
      );

      testWidgets(
        'tapping Close dismisses the dialog and emits no bus events',
        (WidgetTester tester) async {
          var eventCount = 0;
          final bus = AppEventBus.create();
          final sub = bus.on<AppEvent>().listen((_) => eventCount++);
          addTearDown(sub.cancel);

          await pumpDialog(tester);
          final closeButton = find.widgetWithText(CtNinePatchButton, 'Close');
          await tester.ensureVisible(closeButton);
          await tester.pumpAndSettle();
          await tester.tap(closeButton);
          await tester.pumpAndSettle();

          expect(
            find.byType(ProductionCommodityBreakdownDialog),
            findsNothing,
          );
          expect(eventCount, 0);
        },
      );

      // S8c — viewport-adaptive dialog width pins (Refs #2862 S8c / C6).

      testWidgets(
        'wide viewport (>= 900 dp) drops Scrollbar chrome and uses wide maxWidth',
        (WidgetTester tester) async {
          // 900 dp viewport hits the threshold exactly; the wide path
          // applies (>= comparison).
          await pumpDialog(tester);

          final shell = tester.widget<CtDialogShell>(
            find.byType(CtDialogShell),
          );
          expect(
            shell.maxWidth,
            kProductionBreakdownDialogWideMaxWidth,
            reason:
                'wide viewport must use kProductionBreakdownDialogWideMaxWidth',
          );

          // Wide layout drops the visible Scrollbar wrapper around the
          // DataTable: there should be no Scrollbar ancestor of the
          // DataTable. The underlying horizontal SingleChildScrollView
          // is retained so the DataTable measures to its intrinsic
          // width (and stays inside the dialog's content column) but
          // the dialog does not advertise a scroll affordance the user
          // does not need at the wide viewport.
          final scrollbarAroundTable = find.ancestor(
            of: find.byType(DataTable),
            matching: find.byType(Scrollbar),
          );
          expect(
            scrollbarAroundTable,
            findsNothing,
            reason:
                'wide viewport must drop the Scrollbar chrome around the '
                'DataTable so it does not advertise a scroll affordance '
                'the user does not need',
          );

          // Column count is preserved — no phase column hidden.
          final dataTable = tester.widget<DataTable>(find.byType(DataTable));
          expect(
            dataTable.columns.length,
            1 + EconomyPreviewStockpilePhase.values.length + 1,
          );
        },
      );

      testWidgets(
        'narrow viewport (< 900 dp) keeps horizontal Scrollbar fallback and narrow maxWidth',
        (WidgetTester tester) async {
          // 720 dp viewport is strictly below the wide threshold so the
          // historical Scrollbar + SingleChildScrollView path applies.
          await pumpDialog(tester, surfaceSize: const Size(720, 1400));

          final shell = tester.widget<CtDialogShell>(
            find.byType(CtDialogShell),
          );
          expect(
            shell.maxWidth,
            kProductionBreakdownDialogNarrowMaxWidth,
            reason:
                'narrow viewport must use kProductionBreakdownDialogNarrowMaxWidth',
          );

          // Narrow path mounts a horizontal SingleChildScrollView under a
          // visible Scrollbar so every phase column remains reachable on
          // small viewports.
          final horizontalScrolls = find.byWidgetPredicate(
            (w) =>
                w is SingleChildScrollView &&
                w.scrollDirection == Axis.horizontal,
          );
          expect(
            horizontalScrolls,
            findsOneWidget,
            reason:
                'narrow viewport must keep horizontal SingleChildScrollView',
          );

          final scrollbar = tester.widget<Scrollbar>(
            find.ancestor(
              of: find.byType(DataTable),
              matching: find.byType(Scrollbar),
            ),
          );
          expect(scrollbar.thumbVisibility, isTrue);

          final dataTable = tester.widget<DataTable>(find.byType(DataTable));
          expect(
            dataTable.columns.length,
            1 + EconomyPreviewStockpilePhase.values.length + 1,
          );
        },
      );
    },
  );
}
