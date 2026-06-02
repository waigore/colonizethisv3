import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

/// Seed-42 Path F lock-recovery acceptance regression (Refs #2924).
///
/// Pins the primary AC: after 100 Full-AI turns on seed 42, gp3–gp6 each
/// cross `cheapestRegimentBuildTreasuryCost()` at least once from legitimate
/// world-market seller credits (no affordability bypass).
///
/// Skipped by default (~4 min). Re-run with `dart test --run-skipped` when
/// the lock-recovery surface changes.
void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  const failingGpIds = ['gp3', 'gp4', 'gp5', 'gp6'];

  test(
    'seed 42: gp3–gp6 each cross regiment treasury threshold within 100 turns '
    '(Refs #2924 Path F)',
    () {
      final init = runInitGame(
        config: GameSetupConfig(seed: 42),
        options: const InitGameOptions(
          cellSize: 24,
          renderPng: false,
          skipFillLakes: false,
        ),
      );
      var game = init.game.copyWith(
        aiControlByGpId: {for (final p in init.game.players) p.id: true},
      );
      final topo = init.combinedTopology;
      final tileMap = init.tileMapByRegion;

      final threshold = cheapestRegimentBuildTreasuryCost();
      final wasBrokeAfterStart = <String, bool>{
        for (final gpId in failingGpIds) gpId: false,
      };
      final recoveredAfterBroke = <String, bool>{
        for (final gpId in failingGpIds) gpId: false,
      };
      final maxTreasury = <String, int>{
        for (final gpId in failingGpIds) gpId: 0,
      };
      final lifetimeSellerCredit = <String, int>{
        for (final gpId in failingGpIds) gpId: 0,
      };

      for (var t = 0; t < 100; t++) {
        final fullAi = generateOrdersForGameFullAI(
          game,
          topo,
          tileMapByRegion: tileMap,
        );
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

        final activity = game.worldMarketState.lastTurnActivity;
        for (final entry in activity.entries) {
          for (final deal in entry.value.deals) {
            final seller = deal.sellerFactionId;
            if (!lifetimeSellerCredit.containsKey(seller)) continue;
            lifetimeSellerCredit[seller] = lifetimeSellerCredit[seller]! +
                (deal.quantity * deal.pricePerUnit).round();
          }
        }

        for (final gpId in failingGpIds) {
          final treasury = game.playerById(gpId)?.treasury ?? 0;
          if (treasury > maxTreasury[gpId]!) {
            maxTreasury[gpId] = treasury;
          }
          if (t > 0 && treasury < threshold) {
            wasBrokeAfterStart[gpId] = true;
          }
          if (wasBrokeAfterStart[gpId]! && treasury >= threshold) {
            recoveredAfterBroke[gpId] = true;
          }
        }
      }

      for (final gpId in failingGpIds) {
        expect(
          wasBrokeAfterStart[gpId],
          isTrue,
          reason: 'Refs #2924 fixture: $gpId should fall below $threshold '
              'during the 100-turn EXPAND lock (maxTreasury='
              '${maxTreasury[gpId]}).',
        );
        expect(
          recoveredAfterBroke[gpId],
          isTrue,
          reason: 'Refs #2924: $gpId never recovered to treasury >= $threshold '
              'after being broke (maxTreasury=${maxTreasury[gpId]}, '
              'lifetimeSellerCredit=${lifetimeSellerCredit[gpId]}).',
        );
      }
    },
    skip:
        'Refs #2924: long-running seed-42 Path F acceptance (~4 min). '
        'Re-run with `dart test --run-skipped` after lock-recovery tuning.',
  );
}
