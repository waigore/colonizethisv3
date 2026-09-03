// Viewport-adaptive width pins for ProductionCommodityBreakdownDialog
// (SPEC/ui/production-commodity-breakdown-dialog.md, Refs #2862 S8c / C6).

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_commodity_breakdown_dialog.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('ProductionCommodityBreakdownDialog '
      '(SPEC/ui/production-commodity-breakdown-dialog.md)', () {
    Future<void> pumpDialog(
      WidgetTester tester, {
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
      // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
      await tester.pumpWidget(
        buildAppShell(
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          child: Scaffold(
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
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    // S8c — viewport-adaptive dialog width pins (Refs #2862 S8c / C6).

    testWidgets(
      'wide viewport (>= 900 dp) drops Scrollbar chrome and uses wide maxWidth',
      (WidgetTester tester) async {
        // 900 dp viewport hits the threshold exactly; the wide path
        // applies (>= comparison).
        await pumpDialog(tester);

        final shell = tester.widget<CtDialogShell>(find.byType(CtDialogShell));
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

        final shell = tester.widget<CtDialogShell>(find.byType(CtDialogShell));
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
          reason: 'narrow viewport must keep horizontal SingleChildScrollView',
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
  });
}
