import 'dart:convert';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import '../support/cheapest_regiment_build_treasury_cost.dart';
import '../support/seed42_observer_campaign.dart';
import 'seed42_observer_colonial_c0_diagnostic_collect.dart';

void runC0ColonialDiagnosticTest() {
  test(
    'seed 42 turn 150 C0 diagnostic: per-GP COLONIAL acquisition trace',
    () {
      final gpIds = [for (var i = 1; i <= 6; i++) 'gp$i'];
      final phaseCounts = <String, Map<ObserverGoalPhase, int>>{
        for (final gpId in gpIds)
          gpId: <ObserverGoalPhase, int>{
            for (final ph in ObserverGoalPhase.values) ph: 0,
          },
      };
      final firstColonialTurn = <String, int?>{
        for (final gpId in gpIds) gpId: null,
      };
      final acquisitionMethodCounts = <String, Map<String, int>>{
        for (final gpId in gpIds)
          gpId: <String, int>{
            'joinEmpire': 0,
            'purchaseLand': 0,
            'declareWar': 0,
            'null': 0,
          },
      };
      final armEligibilityCounts = <String, Map<String, int>>{
        for (final gpId in gpIds)
          gpId: <String, int>{
            'colonialTurns': 0,
            'nwInvadableEmpty': 0,
            'arm1JoinEmpireEligible': 0,
            'arm2HasIdleMerchant': 0,
            'arm2PurchaseLandEligible': 0,
            'arm3RegimentsGte1': 0,
            'arm3TreasuryGteCheapestRegiment': 0,
            'arm3DeclareWarEligible': 0,
          },
      };
      final acquisitionTargetPicks = <String, Map<String, int>>{
        for (final gpId in gpIds) gpId: <String, int>{},
      };
      final colonialPeacePicks = <String, Map<String, int>>{
        for (final gpId in gpIds) gpId: <String, int>{},
      };
      final lastSnapshotFields = <String, Map<String, Object?>>{};

      const turns = 150;
      final cheapestRegimentCost = cheapestRegimentBuildTreasuryCost();

      final campaign = runSeed42ObserverCampaign(
        turns: turns,
        onBeforeResolve: (turn, fullAi, game, topology, tileMap) {
          recordSeed42ColonialC0DiagnosticBeforeResolve(
            turn: turn,
            turns: turns,
            gpIds: gpIds,
            cheapestRegimentCost: cheapestRegimentCost,
            game: game,
            topology: topology,
            phaseCounts: phaseCounts,
            firstColonialTurn: firstColonialTurn,
            acquisitionMethodCounts: acquisitionMethodCounts,
            armEligibilityCounts: armEligibilityCounts,
            acquisitionTargetPicks: acquisitionTargetPicks,
            colonialPeacePicks: colonialPeacePicks,
            lastSnapshotFields: lastSnapshotFields,
          );
        },
      );

      final diagnostic = buildSeed42ColonialC0DiagnosticJson(
        turns: turns,
        gpIds: gpIds,
        initialGame: campaign.initialGame,
        finalGame: campaign.finalGame,
        phaseCounts: phaseCounts,
        firstColonialTurn: firstColonialTurn,
        acquisitionMethodCounts: acquisitionMethodCounts,
        acquisitionTargetPicks: acquisitionTargetPicks,
        colonialPeacePicks: colonialPeacePicks,
        armEligibilityCounts: armEligibilityCounts,
        lastSnapshotFields: lastSnapshotFields,
      );
      CtLogger.level = Level.info;
      final log = aiLogger('c0-diagnostic');
      log.i('C0_DIAGNOSTIC_JSON_BEGIN');
      log.i(const JsonEncoder.withIndent('  ').convert(diagnostic));
      log.i('C0_DIAGNOSTIC_JSON_END');

      for (final gpId in gpIds) {
        expect(
          phaseCounts[gpId]!.values.fold<int>(0, (a, b) => a + b),
          turns,
          reason: '$gpId phase-count total should equal turn count',
        );
      }
    },
    skip:
        'Refs #2852 C0: long-running (~6 min) per-GP COLONIAL-arm '
        'diagnostic. Captured findings live in the C0 diagnostic note '
        'on issue #2852 / the implementing PR description. Re-run with '
        '`dart test --run-skipped` when the diagnostic surface shifts '
        'after a tuning slice lands.',
    timeout: const Timeout(Duration(minutes: 25)),
  );
}
