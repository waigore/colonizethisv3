// Seed-42 100-turn per-turn World-Market lock-recovery diagnostic
// (Refs #2924, SPEC/ai/treasury-planner.md
// § "Seed-42 100-turn per-turn World-Market lock-recovery diagnostic").

import 'dart:convert';

import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import '../support/cheapest_regiment_build_treasury_cost.dart';
import '../support/seed42_observer_campaign.dart';
import '../support/seed42_observer_world_market_diagnostic_support.dart';
import 'seed42_observer_world_market_diagnostic_cases.dart';

void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  test(
    'seed 42 turn 100 World-Market lock-recovery per-turn diagnostic '
    '(Refs #2924)',
    () {
      final cheapest = cheapestRegimentBuildTreasuryCost();
      final state = Seed42WorldMarketPerTurnDiagnosticState();

      runSeed42ObserverCampaign(
        turns: 100,
        onBeforeResolve: (turn, fullAi, game, topo, tileMap) {
          state.onBeforeResolve(turn, fullAi, game, topo);
        },
        onAfterResolve: (turn, resolved) {
          state.onAfterResolve(turn, resolved);
        },
      );

      final diagnostic = state.buildDiagnosticJson(cheapest);
      CtLogger.level = Level.info;
      final log = aiLogger('wm2924-diagnostic');
      log.i('WM2924_DIAGNOSTIC_JSON_BEGIN');
      log.i(const JsonEncoder.withIndent('  ').convert(diagnostic));
      log.i('WM2924_DIAGNOSTIC_JSON_END');

      for (final gpId in kSeed42WorldMarketDiagnosticGreatPowerIds) {
        expect(
          state.perTurnRows[gpId]!.length,
          100,
          reason:
              'Refs #2924 per-turn diagnostic: $gpId per-turn row '
              'count should equal 100 (one record per turn).',
        );
      }
    },
    skip:
        'Refs #2924 per-turn World-Market lock-recovery diagnostic: '
        'long-running (~4 min) per-GP per-turn trace mirroring the S7-D '
        'skip pattern. Re-run with `dart test --run-skipped` and '
        'transcribe the WM2924_DIAGNOSTIC_JSON_BEGIN/END block into a '
        'comment on #2924 when the diagnostic surface shifts after a '
        'Path F tuning slice lands.',
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
