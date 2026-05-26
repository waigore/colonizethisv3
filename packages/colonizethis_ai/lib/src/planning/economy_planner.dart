// Economy planner: worker allocation and cargo preference. SPEC/ai/economy-planner.md.

import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart';
import 'expand_phase_planner.dart';
import 'phase_planner_dispatch.dart';
import 'phase_planner_economy_filter.dart';
import 'planning_imports.dart';
import 'recipe_scoring.dart';

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
  final regimentCounts = regimentTypeCountsForPlayer(
    game.worldState,
    view.playerId,
  );
  final shipCounts = shipTypeCountsForPlayer(game.worldState, view.playerId);
  final effectiveLabour = effectiveLabourForWorkers(
    workers: workers,
    stockpile: stockpile,
    regimentCountsById: regimentCounts,
    shipCountsById: shipCounts,
  );

  final belowQuotaPeaceTreasuryRecovery = _resolveBelowQuotaPeaceTreasuryRecovery(
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
      cargoPreference: _cargoPreference(
        game,
        view.playerId,
        config,
        colonial: colonial,
        belowQuotaPeaceTreasuryRecovery: belowQuotaPeaceTreasuryRecovery,
      ),
    );
  }

  final militaryRebuildCrisis = snapshot != null &&
      isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned) &&
      snapshot.threats.atWarWith.isNotEmpty &&
      regimentCountForPlayer(game, view.playerId) <
          kStalledMinRegimentCountWhenAtWar;

  final assignments = _allocateLabour(
    stockpile: stockpile,
    workers: workers,
    effectiveLabour: effectiveLabour,
    config: config,
    seeds: seeds,
    militaryRebuildCrisis: militaryRebuildCrisis,
  );

  final cargoPref = _cargoPreference(
    game,
    view.playerId,
    config,
    colonial: colonial,
    belowQuotaPeaceTreasuryRecovery: belowQuotaPeaceTreasuryRecovery,
  );
  _log.i(
    'economy plan playerId=${view.playerId} '
    'cargoPreference=$cargoPref productionAssignmentsCount=${assignments.length}',
  );
  return EconomyPlan(
    productionAssignments: assignments,
    cargoPreference: cargoPref,
  );
}

CargoPreference _cargoPreference(
  Game game,
  String playerId,
  AIConfig config, {
  ColonialSummary colonial = const ColonialSummary(),
  bool belowQuotaPeaceTreasuryRecovery = false,
}) {
  final domainWeights = getDomainWeightsForLeader(config.personalityId);
  final agendaId = config.hiddenAgendaId;
  // Trade-oriented agendas/personalities favour cargo.
  var economyWeight = domainWeights.economy;
  if (belowQuotaPeaceTreasuryRecovery) {
    economyWeight += kBelowQuotaPeaceTreasuryRecoveryCargoBoost;
  }
  if (colonial.invadableNewWorldProvinceIdsSorted.isNotEmpty ||
      colonial.adjacentNewWorldOwnerFactionIdsSorted.isNotEmpty) {
    economyWeight += kColonialCargoPreferenceEconomyBoost;
  }
  if (colonial.newWorldProvincesOwned == 0 &&
      colonial.adjacentNewWorldOwnerFactionIdsSorted.isNotEmpty) {
    economyWeight += kColonialCargoPreferenceNoNwColoniesBoost;
  }
  if (economyWeight < 30) {
    _log.d('cargoPreference none economyWeight=$economyWeight');
    return CargoPreference.none;
  }
  // Strong when economy is high and agenda is trade-related.
  final tradeBias = agendaId == 'industrial_trader' || agendaId == 'merchant'
      ? 20
      : agendaId == 'navigator'
      ? 15
      : 0;
  final pref = economyWeight >= 70 + tradeBias
      ? CargoPreference.strongCargo
      : economyWeight >= 50 + tradeBias
      ? CargoPreference.preferCargo
      : CargoPreference.none;
  _log.d(
    'cargoPreference eval playerId=$playerId '
    'economyWeight=$economyWeight agendaId=$agendaId tradeBias=$tradeBias result=$pref',
  );
  return pref;
}

List<AssignedRecipe> _allocateLabour({
  required Stockpile stockpile,
  required WorkerPool workers,
  required int effectiveLabour,
  required AIConfig config,
  required AISeedBundle seeds,
  bool militaryRebuildCrisis = false,
}) {
  final recipes = ProductionRecipesCatalog.all;
  final agendaId = config.hiddenAgendaId;
  Stockpile virtual = stockpile;
  var remainingLabour = effectiveLabour;
  final result = <AssignedRecipe>[];

  // Build feasible recipes with scores. Feasible = can run at least 1 full run.
  final candidates = <ScoredRecipe>[];
  for (final recipe in recipes) {
    final labourPerOutput = recipe.labourPerOutput;
    if (labourPerOutput <= 0) continue;
    final runs = feasibleRuns(
      recipe: recipe,
      stockpile: virtual,
      remainingLabour: remainingLabour,
    );
    if (runs <= 0) continue;

    var score = scoreRecipe(
      recipe: recipe,
      stockpile: virtual,
      workers: workers,
      agendaId: agendaId,
    );
    if (militaryRebuildCrisis && _isMilitaryInputRecipe(recipe)) {
      score += 40;
    }
    candidates.add(ScoredRecipe(recipe: recipe, score: score));
  }

  if (candidates.isEmpty) return result;

  _log.d(
    'recipe eval playerId=${config.leaderId} effectiveLabour=$effectiveLabour '
    'candidates=${candidates.map((c) => "${c.recipe.id}:${c.score.toStringAsFixed(2)}").toList()}',
  );

  // Sort by score descending; use seed for tie-break.
  candidates.sort((a, b) {
    final c = b.score.compareTo(a.score);
    if (c != 0) return c;
    return a.recipe.id.compareTo(b.recipe.id);
  });

  virtual = stockpile;
  remainingLabour = effectiveLabour;
  final labourByRecipe = <String, int>{};

  for (final scored in candidates) {
    if (remainingLabour <= 0) break;
    final recipe = scored.recipe;
    final runs = feasibleRuns(
      recipe: recipe,
      stockpile: virtual,
      remainingLabour: remainingLabour,
    );
    if (runs <= 0) continue;

    final labourUsed = runs * recipe.labourPerOutput;
    labourByRecipe[recipe.id] = (labourByRecipe[recipe.id] ?? 0) + labourUsed;
    remainingLabour -= labourUsed;
    for (final entry in recipe.inputQuantities.entries) {
      virtual = virtual.applyDelta(entry.key, -entry.value * runs);
    }
    virtual = virtual.applyDelta(
      recipe.outputCommodityId,
      recipe.outputQuantity * runs,
    );
  }

  for (final entry in labourByRecipe.entries) {
    result.add(
      AssignedRecipe(recipeId: entry.key, assignedLabour: entry.value),
    );
  }

  _log.d(
    'allocation effectiveLabour=$effectiveLabour '
    'labourByRecipe=$labourByRecipe assignmentsCount=${result.length}',
  );
  return result;
}

bool _isMilitaryInputRecipe(ProductionRecipe recipe) {
  const militaryOutputIds = {
    'castIron',
    'steel',
    'bronze',
    'lumber',
    'fabric',
    'iron',
    'timber',
  };
  return militaryOutputIds.contains(recipe.outputCommodityId);
}

/// Resolves the EXPAND-phase "below-quota peace treasury recovery" cargo
/// boost trigger for `runEconomyPlanner`.
///
/// When [phasePlan] is supplied (Refs #2509 S5), the resolver routes the
/// two rebuild-trap arms through the phase-planner economy resolvers
/// instead of the legacy `colonial_pressure.dart` predicates:
///
/// - Zero-regiments rebuild arm ->
///   [resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive]
/// - Insufficient-regiments + treasury arm ->
///   [resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive]
///   paired with the same effective-treasury threshold used by the legacy
///   compute (`treasury + pendingRichesTreasuryDelta(...) <
///   cheapestRegimentBuildTreasuryCost()`).
///
/// Phase-derived `bool` is field-equal to the legacy
/// [isBelowQuotaPeaceTreasuryRecovery] compute under EXPAND / COLONIAL-lite
/// because both phases require
/// `oldWorldProvincesOwned < kObserverConquestMinOwProvincesPerGp` at
/// entry via [observerGoalPhaseFor], satisfying the legacy
/// `isBelowObserverConquestQuota` guard structurally. Under COLONIAL and
/// DEVELOP the phase resolvers collapse to `false`, mirroring the
/// suppression matrix established for the orchestrator's economy
/// build-pass slice (`_appendEconomyBuildOrders`).
///
/// When [phasePlan] is `null`, the helper falls back to the legacy
/// compute so test callers and other unmigrated entry points that
/// pre-date the S5 threading stay behaviour-equal on the
/// no-`phasePlan` path. When [snapshot] is `null`, the cargo boost
/// cannot be evaluated and the return is `false` (matches the prior
/// guard).
bool _resolveBelowQuotaPeaceTreasuryRecovery({
  required Game game,
  required PlayerView view,
  required AIWorldSnapshot? snapshot,
  required PhasePlanOutcome? phasePlan,
  required int treasury,
  required Stockpile stockpile,
}) {
  if (snapshot == null) {
    return false;
  }
  final regimentCount = regimentCountForPlayer(game, view.playerId);
  final atWarWithAnyGreatPower = snapshot.threats.atWarWith.any(
    (id) => game.playerById(id) != null,
  );
  final hasInvadableProvinces =
      snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty;
  if (phasePlan == null) {
    return isBelowQuotaPeaceTreasuryRecovery(
      oldWorldProvincesOwned: snapshot.conquest.oldWorldProvincesOwned,
      regimentCount: regimentCount,
      atWarWithAnyGreatPower: atWarWithAnyGreatPower,
      hasInvadableProvinces: hasInvadableProvinces,
      treasury: treasury,
      stockpile: stockpile,
    );
  }
  if (resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive(
    phasePlan: phasePlan,
    regimentCount: regimentCount,
    hasInvadableProvinces: hasInvadableProvinces,
  )) {
    return true;
  }
  if (!resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive(
    phasePlan: phasePlan,
    regimentCount: regimentCount,
    atWarWithAnyGreatPower: atWarWithAnyGreatPower,
    hasInvadableProvinces: hasInvadableProvinces,
  )) {
    return false;
  }
  final effectiveTreasury =
      treasury + pendingRichesTreasuryDelta(stockpile: stockpile);
  return effectiveTreasury < cheapestRegimentBuildTreasuryCost();
}
