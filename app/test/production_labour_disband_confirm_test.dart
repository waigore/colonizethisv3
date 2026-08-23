// Disband confirm before immediate trained-worker demotion.
// SPEC/ui/production-panel.md § Disband (immediate). Refs #4601.

import 'package:colonizethis_app/features/game/widgets/production/production_labour_disband_confirm.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_labour_helpers.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_labour_section.dart';
import 'package:colonizethis_app/widgets/ct_confirm_dialog.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'production_labour_section_test_support.dart';
import 'production_labour_test_fixtures.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();
  final l10n = productionLabourSectionL10n;

  Player journeymanPlayer() => productionLabourGpWithPool(
    peasants: 2,
    journeymen: 1,
    treasury: 800,
    stockpile: {CommodityCatalog.paper.id: 12, CommodityCatalog.fabric.id: 4},
  );

  Future<void> pumpDisbandHost(
    WidgetTester tester, {
    required void Function(Game Function() read, void Function(Game) write)
    bindGame,
    double width = 800,
  }) async {
    var game = productionLabourEmptyGame(players: [journeymanPlayer()]);
    bindGame(() => game, (next) => game = next);
    await tester.pumpWidget(
      buildAppShell(
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: const [Locale('en')],
        viewport: Size(width, 640),
        child: Scaffold(
          body: SizedBox(
            width: width,
            height: 640,
            child: StatefulBuilder(
              builder: (context, setState) {
                final player = game.players.first;
                return ProductionLabourSection(
                  player: player,
                  currentOrders: const Orders(),
                  canEdit: true,
                  callbacks: ProductionLabourCallbacks(
                    onAppendRecruitOrder: (_) {},
                    onPopLastRecruitOrder: (_) {},
                    onDisband: (tier) {
                      confirmAndApplyImmediateLabourDisband(
                        context: context,
                        tier: tier,
                        canEdit: true,
                        readGame: () => game,
                        writeGame: (next) => setState(() => game = next),
                        playerId: player.id,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await pumpSettleCapped(tester);
  }

  group('Labour Disband confirm', () {
    testWidgets('tap Disband shows confirm and does not mutate until Confirm', (
      WidgetTester tester,
    ) async {
      late Game Function() readGame;
      await pumpDisbandHost(
        tester,
        bindGame: (read, write) {
          readGame = read;
        },
      );

      await tester.tap(productionLabourDisbandFinder(WorkerTier.journeyman));
      await pumpSettleCapped(tester);

      expect(find.byType(CtConfirmDialog), findsOneWidget);
      expect(readGame().players.first.workerPool.journeymen, 1);
      expect(readGame().players.first.workerPool.peasants, 2);

      await tester.tap(
        find.descendant(
          of: find.byType(CtConfirmDialog),
          matching: find.text(l10n.production_labourDisband),
        ),
      );
      await pumpSettleCapped(tester);

      expect(find.byType(CtConfirmDialog), findsNothing);
      final pool = readGame().players.first.workerPool;
      expect(pool.journeymen, 0);
      expect(pool.peasants, 3);
      expect(readGame().players.first.treasury, 800);
      expect(
        readGame().players.first.stockpile.quantityOf(
          CommodityCatalog.paper.id,
        ),
        12,
      );
      expect(
        readGame().players.first.stockpile.quantityOf(
          CommodityCatalog.fabric.id,
        ),
        4,
      );
    });

    testWidgets('Cancel leaves the pool unchanged', (
      WidgetTester tester,
    ) async {
      late Game Function() readGame;
      await pumpDisbandHost(
        tester,
        bindGame: (read, write) {
          readGame = read;
        },
      );
      await tester.tap(productionLabourDisbandFinder(WorkerTier.journeyman));
      await pumpSettleCapped(tester);
      await tester.tap(find.text(l10n.common_cancel));
      await pumpSettleCapped(tester);
      expect(find.byType(CtConfirmDialog), findsNothing);
      expect(readGame().players.first.workerPool.journeymen, 1);
      expect(readGame().players.first.workerPool.peasants, 2);
    });

    testWidgets('Escape dismisses without mutating', (
      WidgetTester tester,
    ) async {
      late Game Function() readGame;
      await pumpDisbandHost(
        tester,
        bindGame: (read, write) {
          readGame = read;
        },
      );
      await tester.tap(productionLabourDisbandFinder(WorkerTier.journeyman));
      await pumpSettleCapped(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await pumpSettleCapped(tester);
      expect(find.byType(CtConfirmDialog), findsNothing);
      expect(readGame().players.first.workerPool.journeymen, 1);
    });

    testWidgets('confirm copy names rank, peasant now, and no refund', (
      WidgetTester tester,
    ) async {
      await pumpDisbandHost(tester, bindGame: (read, write) {});
      await tester.tap(productionLabourDisbandFinder(WorkerTier.journeyman));
      await pumpSettleCapped(tester);
      final name = l10n.production_workerSingularJourneyman;
      expect(
        find.text(l10n.production_labourDisbandConfirmTitle(name)),
        findsOneWidget,
      );
      expect(
        find.text(l10n.production_labourDisbandConfirmBody(name)),
        findsOneWidget,
      );
      expect(find.textContaining('WorkerTier'), findsNothing);
    });

    testWidgets('confirm wraps at 320 dp without overflow', (
      WidgetTester tester,
    ) async {
      await pumpDisbandHost(tester, bindGame: (read, write) {}, width: 320);
      await tester.tap(productionLabourDisbandFinder(WorkerTier.journeyman));
      await pumpSettleCapped(tester);
      expect(find.byType(CtConfirmDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.text(l10n.common_cancel), findsOneWidget);
    });

    testWidgets('observe mode does not mount Disband', (
      WidgetTester tester,
    ) async {
      await pumpProductionLabourSection(
        tester,
        player: journeymanPlayer(),
        canEdit: false,
      );
      expect(find.text(l10n.production_labourDisband), findsNothing);
      expect(find.byType(CtConfirmDialog), findsNothing);
    });
  });
}
