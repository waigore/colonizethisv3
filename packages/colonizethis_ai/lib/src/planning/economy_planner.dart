// Economy planner: worker allocation and cargo preference. SPEC/ai/economy-planner.md.

import '../perception/perception_snapshot.dart';
import 'growth_stage.dart';
import 'phase_planner_dispatch.dart';
import 'economy_planner_cargo.dart';
import 'economy_planner_labour.dart';
import 'economy_planner_production_boost.dart';
import 'effective_labour_state.dart';
import 'planning_imports.dart';
import 'treasury_planner.dart';

export 'economy_planner_constants.dart';
export 'economy_planner_labour.dart' show LabourAllocationInput;

final _log = packageLogger('economy_planner');

/// Runs the economy planner for one AI-controlled player. Deterministic given
/// [game], [view], [config], and [seeds]. Returns production assignments and
/// cargo preference. SPEC/ai/economy-planner.md.
///
/// When [phasePlan] is supplied (Refs #2509 S5), the below-quota peace
/// treasury-recovery cargo boost is derived from the dispatched
/// [PhasePlanOutcome] via the phase-planner economy resolvers
/// (`resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive` and
/// `resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive`)
/// rather than the legacy `isBelowQuotaPeaceTreasuryRecovery` compute
/// (`colonial_pressure.dart`). The phase-derived path is field-equal to the
/// legacy compute under EXPAND / COLONIAL-lite because both phases require
/// `oldWorldProvincesOwned < kObserverConquestMinOwProvincesPerGp` at entry
/// via [observerGoalPhaseFor]; the legacy compute's `isBelowObserverConquestQuota`
/// guard is therefore satisfied structurally and the remaining
/// regiment / war / invadable arms route through the phase resolvers. When
/// [phasePlan] is `null` (test callers and other unmigrated entry points
/// that pre-date the S5 threading), the planner falls back to the legacy
/// `isBelowQuotaPeaceTreasuryRecovery` compute so existing fixtures stay
/// behaviour-equal on the no-`phasePlan` path.
EconomyPlan runEconomyPlanner({
  required Game game,
  required PlayerView view,
  required AIConfig config,
  required AISeedBundle seeds,
  ColonialSummary colonial = const ColonialSummary(),
  AIWorldSnapshot? snapshot,
  PhasePlanOutcome? phasePlan,
  Map<String, TileMapResult>? tileMapByRegion,
  MapTopology? topology,
  bool skipTradeOrderGeneration = false,
  bool growthStagePlannerEnabled = kGrowthStagePlannerEnabled,
  Map<String, ExtractionTotals>? extractionById,
}) {
  final player = game.playerById(view.playerId);
  if (player == null) {
    _log.w('no player for ${view.playerId}');
    return const EconomyPlan(
      productionAssignments: [],
      cargoPreference: CargoPreference.none,
    );
  }

  final stockpile = player.stockpile;
  final workers = player.workerPool;
  final effectiveLabour = EffectiveLabourState.fromGame(
    game,
    view.playerId,
  ).compute();

  final belowQuotaPeaceTreasuryRecovery =
      resolveBelowQuotaPeaceTreasuryRecovery(
        game: game,
        view: view,
        snapshot: snapshot,
        phasePlan: phasePlan,
        treasury: player.treasury,
        stockpile: stockpile,
      );

  if (effectiveLabour <= 0) {
    return EconomyPlan(
      productionAssignments: [],
      cargoPreference: economyPlannerCargoPreference(
        game,
        view.playerId,
        config,
        colonial: colonial,
        belowQuotaPeaceTreasuryRecovery: belowQuotaPeaceTreasuryRecovery,
      ),
      // Refs #3122 orchestrator wiring: when the orchestrator will
      // recompute trade orders after domain planning (so pending
      // build / recruit / research costs feed the treasury budget),
      // return the empty list here to avoid emitting a stale planner
      // pass whose results would be discarded.
      tradeOrders: skipTradeOrderGeneration
          ? const <TradeOrder>[]
          : runTreasuryPlanner(
              TreasuryPlannerInput(
                game: game,
                playerId: view.playerId,
                stockpile: stockpile,
                productionAssignments: const [],
                treasury: player.treasury,
                snapshot: snapshot,
                tileMapByRegion: tileMapByRegion,
                topology: topology,
                extractionById: extractionById,
              ),
            ),
    );
  }

  final productionBoost = resolveEconomyPlannerProductionBoost(
    game: game,
    playerId: view.playerId,
    stockpile: stockpile,
    snapshot: snapshot,
    phasePlan: phasePlan,
  );

  final growthStage = growthStagePlannerEnabled
      ? GrowthStage.compute(game, view.playerId, snapshot: snapshot)
      : null;

  final assignments = allocateLabour(
    LabourAllocationInput(
      stockpile: stockpile,
      workers: workers,
      effectiveLabour: effectiveLabour,
      config: config,
      seeds: seeds,
      techUnlocked: player.techUnlocked,
      militaryRebuildCrisis: productionBoost.militaryRebuildCrisis,
      regimentBuildInputProductionBoost: growthStagePlannerEnabled
          ? false
          : productionBoost.regimentBuildInputProductionBoost,
      missingRegimentBuildInputIds: growthStagePlannerEnabled
          ? const <String>{}
          : productionBoost.boostedBuildInputOutputs,
      supplierReleaseImprovementInputIds: growthStagePlannerEnabled
          ? const <String>{}
          : productionBoost.supplierReleaseImprovementInputs,
      feedstockReserveOutputIds: growthStagePlannerEnabled
          ? const <String>{}
          : productionBoost.feedstockReserveOutputIds,
      castIronLabourPeasantRecruitFabricBoost: growthStagePlannerEnabled
          ? false
          : productionBoost.castIronLabourPeasantRecruitFabricBoost,
      growthStage: growthStage,
    ),
  );

  final cargoPref = economyPlannerCargoPreference(
    game,
    view.playerId,
    config,
    colonial: colonial,
    belowQuotaPeaceTreasuryRecovery: belowQuotaPeaceTreasuryRecovery,
  );
  // Refs #3122 orchestrator wiring: when the orchestrator will
  // recompute trade orders after domain planning, the planner pass
  // here would run with an empty `currentOrders` and any pending
  // build / recruit / research costs would contribute zero to the
  // budget. Skipping the call in that mode avoids the wasted work.
  final tradeOrders = skipTradeOrderGeneration
      ? const <TradeOrder>[]
      : runTreasuryPlanner(
          TreasuryPlannerInput(
            game: game,
            playerId: view.playerId,
            stockpile: stockpile,
            productionAssignments: assignments,
            treasury: player.treasury,
            snapshot: snapshot,
            tileMapByRegion: tileMapByRegion,
            topology: topology,
            extractionById: extractionById,
          ),
        );
  _log.i(
    'economy plan playerId=${view.playerId} '
    'cargoPreference=$cargoPref productionAssignmentsCount=${assignments.length} '
    'tradeOrdersCount=${tradeOrders.length}',
  );
  return EconomyPlan(
    productionAssignments: assignments,
    cargoPreference: cargoPref,
    tradeOrders: tradeOrders,
  );
}
