import 'dart:convert';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/army_conquest_prep.dart'
    show regimentCountForPlayer;
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

/// Seed-42 turn-150 COLONIAL-arm C0 diagnostic (Refs #2852).
///
/// Per #2852 § C0, this test mirrors the #2847 § S7-D pattern for the
/// COLONIAL phase: run the 150-turn seed-42 scenario (matching the
/// `--verify-colonial-expansion` parameters captured by #2848 S0) and
/// record, per GP per turn:
///
///   * `observerGoalPhaseFor` phase classification.
///   * For COLONIAL-phase turns: the `planColonialAcquisition`
///     [AcquisitionMethod] chosen (`joinEmpire` / `purchaseLand` /
///     `declareWar`) or `null` when no method is reachable.
///   * Per-arm eligibility flags (was at least one NW invadable
///     province satisfying that arm's gates this turn?) so the C1
///     scope decision can see which gates abort the acquisition:
///       - Method 1 (Join Empire): non-GP owner with overture stage
///         `nap`, relation ≥ Friendly, treasury ≥
///         [joinEmpireCostForMinorOrTribe].
///       - Method 2 (purchase_land): idle Merchant present, plus at
///         least one province with non-war embassy-stage owner and a
///         tile satisfying the per-tile gates (resource / mineral
///         prospect / not-yet-purchased / treasury ≥ [purchaseLandCost]).
///       - Method 3 (declareWar): regiments ≥ 1, treasury ≥ cheapest
///         regiment cost, plus at least one non-GP non-at-war owner in
///         the NW invadable list.
///   * Snapshot fields gating the arms: NW invadable count, NW
///     provinces already owned by this GP, treasury, regiment count,
///     idle Merchant flag.
///
/// The aggregated per-GP rollup (first COLONIAL turn, terminal NW
/// ownership, per-arm acquisition counts, per-arm eligibility counts)
/// is emitted as a structured JSON dump for inclusion in the C0
/// diagnostic note on the issue / PR description. The test asserts
/// only that the diagnostic data was collected (per-GP phase-count
/// totals match the turn count) — it does **not** pin any arm-fire
/// counts so the diagnostic surface can move freely as the planner is
/// tuned in subsequent slices.
///
/// ## How to refresh
///
/// Skipped by default (long-running, ~6 minutes on the project
/// reference host because the test runs for 150 turns vs the
/// #2847 S7-D's 100). Run manually with:
///
/// ```
/// (cd packages/colonizethis_ai && dart test \
///     test/seed42_observer_colonial_c0_diagnostic_test.dart \
///     --run-skipped)
/// ```
///
/// and copy the `C0_DIAGNOSTIC_JSON_*`-delimited block into a fresh
/// comment on issue #2852 if the diagnostic surface shifts after a
/// tuning slice lands.
void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  test(
    'seed 42 turn 150 C0 diagnostic: per-GP COLONIAL acquisition trace',
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

      final gpIds = [for (var i = 1; i <= 6; i++) 'gp$i'];

      int nwCountOwnedBy(Game g, String gpId) => g.worldState.newWorld.provinces
          .where((p) => p.ownerId == gpId)
          .length;

      final nwStart = <String, int>{
        for (final gpId in gpIds) gpId: nwCountOwnedBy(game, gpId),
      };

      // Per-GP rollups; populated as the simulation advances.
      final phaseCounts = <String, Map<ObserverGoalPhase, int>>{
        for (final gpId in gpIds)
          gpId: <ObserverGoalPhase, int>{
            for (final ph in ObserverGoalPhase.values) ph: 0,
          },
      };
      final firstColonialTurn = <String, int?>{
        for (final gpId in gpIds) gpId: null,
      };
      // Acquisition outcome counts on COLONIAL turns.
      final acquisitionMethodCounts = <String, Map<String, int>>{
        for (final gpId in gpIds)
          gpId: <String, int>{
            'joinEmpire': 0,
            'purchaseLand': 0,
            'declareWar': 0,
            'null': 0,
          },
      };
      // Per-arm eligibility counts on COLONIAL turns (independent of
      // which arm actually fired -- captures whether each arm *could*
      // have fired this turn under its own gate set). These let C1 see
      // which gate set is the binding constraint when the acquisition
      // came back null.
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
      // Aggregate distribution of acquisition target faction ids picked.
      final acquisitionTargetPicks = <String, Map<String, int>>{
        for (final gpId in gpIds) gpId: <String, int>{},
      };
      // Aggregate distribution of colonial peace target sets.
      final colonialPeacePicks = <String, Map<String, int>>{
        for (final gpId in gpIds) gpId: <String, int>{},
      };
      final lastSnapshotFields = <String, Map<String, Object?>>{};

      const turns = 150;
      final cheapestRegimentCost = cheapestRegimentBuildTreasuryCost();

      for (var t = 0; t < turns; t++) {
        for (final gpId in gpIds) {
          final view = buildPlayerView(game, topo, gpId);
          final snap = AIWorldSnapshot.fromPlayerView(view, topology: topo);
          final outcome = runPhasePlanners(game: game, snapshot: snap);

          phaseCounts[gpId]![outcome.phase] =
              (phaseCounts[gpId]![outcome.phase] ?? 0) + 1;

          if (outcome.phase == ObserverGoalPhase.colonial) {
            firstColonialTurn[gpId] ??= t;
            final counts = armEligibilityCounts[gpId]!;
            counts['colonialTurns'] = counts['colonialTurns']! + 1;

            // Acquisition outcome.
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

            // Per-arm eligibility flags. Each flag is evaluated using
            // the same helpers `planColonialAcquisition` consults so
            // the diagnostic mirrors the planner's view exactly.
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
                    _provinceHasValidPurchaseLandTileForDiagnostic(
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

            final arm2HasIdleMerchant = _hasIdleMerchantForDiagnostic(
              game.worldState,
              gpId,
            );
            final arm3RegimentsGte1 = regiments >= 1;
            final arm3TreasuryGte = treasury >= cheapestRegimentCost;

            if (arm1JoinEmpireEligible) {
              counts['arm1JoinEmpireEligible'] =
                  counts['arm1JoinEmpireEligible']! + 1;
            }
            if (arm2HasIdleMerchant) {
              counts['arm2HasIdleMerchant'] =
                  counts['arm2HasIdleMerchant']! + 1;
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
            if (arm3RegimentsGte1 &&
                arm3TreasuryGte &&
                arm3HasNonWarNonGpOwner) {
              counts['arm3DeclareWarEligible'] =
                  counts['arm3DeclareWarEligible']! + 1;
            }
          }

          // Cache the terminal-turn snapshot fields for the final rollup.
          if (t == turns - 1) {
            final player = game.playerById(gpId);
            lastSnapshotFields[gpId] = <String, Object?>{
              'observerPhase': outcome.phase.name,
              'oldWorldProvincesOwned': snap.conquest.oldWorldProvincesOwned,
              'nwProvincesOwned': nwCountOwnedBy(game, gpId),
              'nwInvadableCount':
                  snap.colonial.invadableNewWorldProvinceIdsSorted.length,
              'invadableProvinceCount':
                  snap.conquest.invadableProvinceIdsSorted.length,
              'treasury': player?.treasury,
              'regimentCount': regimentCountForPlayer(game, gpId),
              'idleMerchant': _hasIdleMerchantForDiagnostic(
                game.worldState,
                gpId,
              ),
              'cheapestRegimentBuildTreasuryCost': cheapestRegimentCost,
            };
          }
        }

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
      }

      final nwGains = <String, int>{
        for (final gpId in gpIds)
          gpId: nwCountOwnedBy(game, gpId) - nwStart[gpId]!,
      };
      final nwEnd = <String, int>{
        for (final gpId in gpIds) gpId: nwCountOwnedBy(game, gpId),
      };
      // Count tribe-held NW provinces (the C0 diagnostic's
      // `ColonialSummary` detection cross-check at the world level).
      final nwOwnerDistribution = <String, int>{};
      for (final province in game.worldState.newWorld.provinces) {
        final ownerId = province.ownerId ?? '(unowned)';
        nwOwnerDistribution[ownerId] = (nwOwnerDistribution[ownerId] ?? 0) + 1;
      }

      final diagnostic = <String, Object?>{
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
      // Re-enable info-level logging so the structured diagnostic JSON
      // surfaces in stdout via the package logger (the simulation above
      // intentionally ran with logging off to suppress planner noise).
      // Routing through `aiLogger` keeps this test compliant with the
      // disallowed-AST `avoid_print_suppression` rule while preserving
      // greppable BEGIN/END markers for issue-comment transcription.
      CtLogger.level = Level.info;
      final log = aiLogger('c0-diagnostic');
      log.i('C0_DIAGNOSTIC_JSON_BEGIN');
      log.i(const JsonEncoder.withIndent('  ').convert(diagnostic));
      log.i('C0_DIAGNOSTIC_JSON_END');

      // Lightweight assertion: data was actually collected. The diagnostic
      // does not pin arm-fire counts so the planner can be tuned freely
      // in C2 (or kept untouched if C1 defers) without churn here.
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

/// Mirror of `_hasIdleMerchant` (private to
/// `colonial_phase_planner.dart`) — the diagnostic must use the same
/// idle-Merchant scan the planner consults so eligibility flags align
/// with the production gate.
bool _hasIdleMerchantForDiagnostic(WorldState world, String playerId) {
  for (final unit in allUnitsFromWorld(world)) {
    if (unit.ownerId == playerId &&
        unit.type == kUnitTypeMerchant &&
        unit.status == UnitStatus.idle) {
      return true;
    }
  }
  return false;
}

/// Mirror of `_provinceHasValidPurchaseLandTile` (private to
/// `colonial_phase_planner.dart`) — the diagnostic mirrors the per-tile
/// gates of `precheckPurchaseLand` so the `arm2PurchaseLandEligible`
/// flag aligns with the production planner's view exactly.
bool _provinceHasValidPurchaseLandTileForDiagnostic({
  required WorldState world,
  required String provinceId,
  required int treasury,
  required Set<String> prospected,
  required Map<String, String> purchasedByTile,
}) {
  for (final entry in world.resourceByTileKey.entries) {
    final tileKey = entry.key;
    if (Unit.provinceIdFromTileKey(tileKey) != provinceId) continue;
    final resourceId = entry.value;
    if (resourceId.isEmpty) continue;
    if (purchasedByTile.containsKey(tileKey)) continue;
    if (kMineralResourceIds.contains(resourceId) &&
        !prospected.contains(tileKey)) {
      continue;
    }
    if (treasury < purchaseLandCost(resourceId)) continue;
    return true;
  }
  return false;
}
