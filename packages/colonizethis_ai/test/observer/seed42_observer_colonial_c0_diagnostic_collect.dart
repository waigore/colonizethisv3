// Per-turn COLONIAL C0 diagnostic collection helpers (Refs #2852 / #4602 Slice E).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_ai/src/planning/army_conquest_prep.dart'
    show regimentCountForPlayer;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'seed42_observer_colonial_c0_diagnostic_cases.dart';

int seed42ColonialC0NwCountOwnedBy(Game game, String gpId) =>
    game.worldState.newWorld.provinces.where((p) => p.ownerId == gpId).length;

void recordSeed42ColonialC0DiagnosticBeforeResolve({
  required int turn,
  required int turns,
  required List<String> gpIds,
  required int cheapestRegimentCost,
  required Game game,
  required MapTopology topology,
  required Map<String, Map<ObserverGoalPhase, int>> phaseCounts,
  required Map<String, int?> firstColonialTurn,
  required Map<String, Map<String, int>> acquisitionMethodCounts,
  required Map<String, Map<String, int>> armEligibilityCounts,
  required Map<String, Map<String, int>> acquisitionTargetPicks,
  required Map<String, Map<String, int>> colonialPeacePicks,
  required Map<String, Map<String, Object?>> lastSnapshotFields,
}) {
  for (final gpId in gpIds) {
    final view = buildPlayerView(game, topology, gpId);
    final snap = AIWorldSnapshot.fromPlayerView(view, topology: topology);
    final outcome = runPhasePlanners(game: game, snapshot: snap);

    phaseCounts[gpId]![outcome.phase] =
        (phaseCounts[gpId]![outcome.phase] ?? 0) + 1;

    if (outcome.phase == ObserverGoalPhase.colonial) {
      firstColonialTurn[gpId] ??= turn;
      final counts = armEligibilityCounts[gpId]!;
      counts['colonialTurns'] = counts['colonialTurns']! + 1;

      final acq = outcome.colonialAcquisitionTarget;
      if (acq == null) {
        acquisitionMethodCounts[gpId]!['null'] =
            acquisitionMethodCounts[gpId]!['null']! + 1;
      } else {
        final key = acq.method.name;
        acquisitionMethodCounts[gpId]![key] =
            (acquisitionMethodCounts[gpId]![key] ?? 0) + 1;
        acquisitionTargetPicks[gpId]![acq.targetFactionId] =
            (acquisitionTargetPicks[gpId]![acq.targetFactionId] ?? 0) + 1;
      }

      final peaceKey = outcome.colonialPeaceTargetFactionIdsSorted.isEmpty
          ? '(none)'
          : outcome.colonialPeaceTargetFactionIdsSorted.join(',');
      colonialPeacePicks[gpId]![peaceKey] =
          (colonialPeacePicks[gpId]![peaceKey] ?? 0) + 1;

      if (snap.colonial.invadableNewWorldProvinceIdsSorted.isEmpty) {
        counts['nwInvadableEmpty'] = counts['nwInvadableEmpty']! + 1;
        continue;
      }

      final invadable = snap.colonial.invadableNewWorldProvinceIdsSorted;
      final provinceOwner = getProvinceOwnerMap(game);
      final treasury = snap.economy.treasury;
      final regiments = regimentCountForPlayer(game, gpId);
      final prospected =
          game.worldState.playerProspectedTiles[gpId] ?? const <String>{};
      final purchasedByTile = game.worldState.purchasedTilesByTileKey;

      var arm1JoinEmpireEligible = false;
      var arm2PurchaseLandEligible = false;
      var arm3HasNonWarNonGpOwner = false;
      for (final provinceId in invadable) {
        final ownerId = provinceOwner[provinceId];
        if (ownerId == null) continue;
        if (game.playerById(ownerId) != null) continue;

        if (!arm1JoinEmpireEligible) {
          final overture = getOverture(game, gpId, ownerId);
          final relation = getRelation(game, gpId, ownerId);
          if (overture != null &&
              overture.stage == OvertureStage.nap &&
              relation != null &&
              relation.score >= relationScoreMinFriendly &&
              treasury >= joinEmpireCostForMinorOrTribe(game, ownerId)) {
            arm1JoinEmpireEligible = true;
          }
        }

        if (!arm2PurchaseLandEligible) {
          final relation = getRelation(game, gpId, ownerId);
          final overture = getOverture(game, gpId, ownerId);
          if ((relation == null || !relation.atWar) &&
              overture != null &&
              overture.hasEmbassy &&
              provinceHasValidPurchaseLandTileForC0Diagnostic(
                world: game.worldState,
                provinceId: provinceId,
                treasury: treasury,
                prospected: prospected,
                purchasedByTile: purchasedByTile,
              )) {
            arm2PurchaseLandEligible = true;
          }
        }

        if (!arm3HasNonWarNonGpOwner) {
          final relation = getRelation(game, gpId, ownerId);
          if (relation == null || !relation.atWar) {
            arm3HasNonWarNonGpOwner = true;
          }
        }
      }

      final arm2HasIdleMerchant = hasIdleMerchantForC0Diagnostic(
        game.worldState,
        gpId,
      );
      final arm3RegimentsGte1 = regiments >= 1;
      final arm3TreasuryGte = treasury >= cheapestRegimentCost;

      if (arm1JoinEmpireEligible) {
        counts['arm1JoinEmpireEligible'] = counts['arm1JoinEmpireEligible']! + 1;
      }
      if (arm2HasIdleMerchant) {
        counts['arm2HasIdleMerchant'] = counts['arm2HasIdleMerchant']! + 1;
        if (arm2PurchaseLandEligible) {
          counts['arm2PurchaseLandEligible'] =
              counts['arm2PurchaseLandEligible']! + 1;
        }
      }
      if (arm3RegimentsGte1) {
        counts['arm3RegimentsGte1'] = counts['arm3RegimentsGte1']! + 1;
      }
      if (arm3TreasuryGte) {
        counts['arm3TreasuryGteCheapestRegiment'] =
            counts['arm3TreasuryGteCheapestRegiment']! + 1;
      }
      if (arm3RegimentsGte1 && arm3TreasuryGte && arm3HasNonWarNonGpOwner) {
        counts['arm3DeclareWarEligible'] =
            counts['arm3DeclareWarEligible']! + 1;
      }
    }

    if (turn == turns - 1) {
      final player = game.playerById(gpId);
      lastSnapshotFields[gpId] = <String, Object?>{
        'observerPhase': outcome.phase.name,
        'oldWorldProvincesOwned': snap.conquest.oldWorldProvincesOwned,
        'nwProvincesOwned': seed42ColonialC0NwCountOwnedBy(game, gpId),
        'nwInvadableCount':
            snap.colonial.invadableNewWorldProvinceIdsSorted.length,
        'invadableProvinceCount': snap.conquest.invadableProvinceIdsSorted.length,
        'treasury': player?.treasury,
        'regimentCount': regimentCountForPlayer(game, gpId),
        'idleMerchant': hasIdleMerchantForC0Diagnostic(game.worldState, gpId),
        'cheapestRegimentBuildTreasuryCost': cheapestRegimentCost,
      };
    }
  }
}

Map<String, Object?> buildSeed42ColonialC0DiagnosticJson({
  required int turns,
  required List<String> gpIds,
  required Game initialGame,
  required Game finalGame,
  required Map<String, Map<ObserverGoalPhase, int>> phaseCounts,
  required Map<String, int?> firstColonialTurn,
  required Map<String, Map<String, int>> acquisitionMethodCounts,
  required Map<String, Map<String, int>> acquisitionTargetPicks,
  required Map<String, Map<String, int>> colonialPeacePicks,
  required Map<String, Map<String, int>> armEligibilityCounts,
  required Map<String, Map<String, Object?>> lastSnapshotFields,
}) {
  final nwStart = <String, int>{
    for (final gpId in gpIds)
      gpId: seed42ColonialC0NwCountOwnedBy(initialGame, gpId),
  };
  final nwEnd = <String, int>{
    for (final gpId in gpIds)
      gpId: seed42ColonialC0NwCountOwnedBy(finalGame, gpId),
  };
  final nwGains = <String, int>{
    for (final gpId in gpIds) gpId: nwEnd[gpId]! - nwStart[gpId]!,
  };
  final nwOwnerDistribution = <String, int>{};
  for (final province in finalGame.worldState.newWorld.provinces) {
    final ownerId = province.ownerId ?? '(unowned)';
    nwOwnerDistribution[ownerId] = (nwOwnerDistribution[ownerId] ?? 0) + 1;
  }

  return <String, Object?>{
    'issue': 2852,
    'subtask': 'C0',
    'seed': 42,
    'turns': turns,
    'gpNwOwnedStart': nwStart,
    'gpNwOwnedEnd': nwEnd,
    'gpNwGain': nwGains,
    'nwOwnerDistribution': nwOwnerDistribution,
    'gpFirstColonialTurn': firstColonialTurn,
    'gpPhaseTurnCount': {
      for (final gpId in gpIds)
        gpId: {
          for (final entry in phaseCounts[gpId]!.entries)
            entry.key.name: entry.value,
        },
    },
    'gpAcquisitionMethodCounts': acquisitionMethodCounts,
    'gpAcquisitionTargetPicks': acquisitionTargetPicks,
    'gpColonialPeacePickDistribution': colonialPeacePicks,
    'gpArmEligibilityCounts': armEligibilityCounts,
    'gpTerminalSnapshot': lastSnapshotFields,
  };
}
