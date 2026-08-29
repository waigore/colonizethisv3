import 'dart:convert';

import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import '../support/cheapest_regiment_build_treasury_cost.dart';
import '../support/seed42_observer_campaign.dart';
import 'seed42_observer_world_market_lock_recovery_diagnostic_collect.dart';

void runWorldMarketLockRecoveryDiagnosticTest() {
  test(
    'seed 42 turn 100 Path F world-market diagnostic: per-GP per-turn '
    'trade emission / deal matching / treasury credit trace',
    () {
      final gpIds = [for (var i = 1; i <= 6; i++) 'gp$i'];
      final state = Seed42WorldMarketLockRecoveryDiagnosticState(gpIds);
      final threshold = cheapestRegimentBuildTreasuryCost();

      runSeed42ObserverCampaign(
        turns: 100,
        onBeforeResolve: (turn, fullAi, game, topology, tileMap) {
          state.onBeforeResolve(turn, fullAi, game, threshold);
        },
        onAfterResolve: (turn, game) {
          state.onAfterResolve(turn, game, threshold);
        },
      );

      final diagnostic = state.buildDiagnosticJson(threshold);
      CtLogger.level = Level.info;
      final log = aiLogger('s7d-world-market');
      log.i('S7D_WORLD_MARKET_DIAGNOSTIC_JSON_BEGIN');
      log.i(const JsonEncoder.withIndent('  ').convert(diagnostic));
      log.i('S7D_WORLD_MARKET_DIAGNOSTIC_JSON_END');

      for (final gpId in gpIds) {
        expect(state.treasuryAfterTurn[gpId]!.length, 100);
      }
    },
    skip:
        'Refs #2924: long-running (~3 min) per-GP per-turn world-market '
        'diagnostic. Re-run with `dart test --run-skipped` when the Path F '
        'lock-recovery surface changes.',
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
