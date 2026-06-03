import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import 'support/faithful_full_ai_test_handoff.dart';

/// Seed-42 Path E lock-recovery declare-war acceptance regression (Refs #2924).
///
/// Pins the secondary AC: under the EXPAND geographic peer-war lock with
/// `treasury == 0` and `newWorldProvincesOwned == 0`, gp3–gp6 must emit
/// at least one NW-acquisition-supporting diplomatic order (`declareWar`
/// toward a tribe/minor) across the 100-turn campaign so the
/// declare-war → colonial military/naval → invasion chain can begin.
///
/// NW-bound army moves may remain zero until naval transport / home-army
/// mobility land (#2925 companion); this regression pins the upstream
/// diplomatic emission the issue's secondary AC requires.
///
/// Skipped by default (~3 min). Re-run with `dart test --run-skipped` when
/// the lock-recovery colonial acquisition surface changes.
void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  const failingGpIds = ['gp3', 'gp4', 'gp5', 'gp6'];

  test(
    'seed 42: gp3–gp6 each emit at least one tribal declareWar within 100 '
    'turns (Refs #2924 Path E)',
    () {
      final init = runInitGame(
        config: GameSetupConfig(seed: 42),
        options: const InitGameOptions(
          cellSize: 24,
          renderPng: false,
          skipFillLakes: false,
        ),
      );
      var game = applyFaithfulFullAiTestHandoff(init.game);
      final topo = init.combinedTopology;
      final tileMap = init.tileMapByRegion;

      final tribalDeclareWarCount = <String, int>{
        for (final gpId in failingGpIds) gpId: 0,
      };

      for (var t = 0; t < 100; t++) {
        final fullAi = generateOrdersForGameFullAI(
          game,
          topo,
          tileMapByRegion: tileMap,
        );
        for (final gpId in failingGpIds) {
          for (final order
              in fullAi.orders.diplomaticOrdersByPlayerId[gpId] ?? const []) {
            if (order.type == DiplomaticOrderType.declareWar &&
                !order.targetFactionId.startsWith('gp')) {
              tribalDeclareWarCount[gpId] = tribalDeclareWarCount[gpId]! + 1;
            }
          }
        }
        final merged = mergeOrderLists(
          humanOrders: const Orders(),
          aiOrders: fullAi.orders,
        );
        final assignments = fullAi.economyPlansByPlayerId.map(
          (pid, plan) => MapEntry(pid, plan.productionAssignments),
        );
        final result = validateOrdersAndResolveTurnFromTrustedOrders(
          game: fullAi.game,
          topology: topo,
          orders: merged,
          tileMapByRegion: tileMap,
          defaultAssignmentsByPlayerId: assignments,
        );
        expect(result, isA<TurnResolutionComplete>());
        game = (result as TurnResolutionComplete).game;
      }

      for (final gpId in failingGpIds) {
        expect(
          tribalDeclareWarCount[gpId]!,
          greaterThan(0),
          reason:
              'Refs #2924 Path E: $gpId must emit at least one tribal '
              'declareWar under the lock-recovery override '
              '(count=${tribalDeclareWarCount[gpId]}).',
        );
      }
    },
    skip:
        'Refs #2924: long-running seed-42 Path E acceptance (~3 min). '
        'Re-run with `dart test --run-skipped` after lock-recovery tuning.',
  );
}
