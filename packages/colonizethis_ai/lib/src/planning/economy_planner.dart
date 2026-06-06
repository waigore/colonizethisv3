// Economy planner: worker allocation and cargo preference. SPEC/ai/economy-planner.md.

import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart';
import 'cast_iron_labour_gate.dart'
    show isCastIronLabourPeasantRecruitFabricShort;
import 'expand_phase_planner.dart' hide cheapestRegimentBuildTreasuryCost;
import 'phase_planner_dispatch.dart';
import 'phase_planner_economy_filter.dart';
import 'phase_planner_expand_economy.dart';
import 'planning_imports.dart';
import 'recipe_scoring.dart';
import 'treasury_planner.dart';

final _log = packageLogger('economy_planner');

/// Recipe-score boost for outputs that supply a missing cheapest-regiment
/// build input when the EXPAND regiment-rebuild directive is active
/// (Refs #2847 H8 production companion).
const double kRegimentBuildInputProductionScoreBoost = 50.0;

/// Recipe-score boost an **affluent supplier** applies to a domestically
/// produced improvement input (e.g. `castIron`) that a *peer* lock-recovery
/// seller needs but the world market structurally cannot supply (Refs #2847
/// H8-supply castIron source). Deliberately **small** — far below the
/// shortage-driven score of the supplier's own essential recipes
/// (`kShortageWeight * kShortageThreshold == 16`) — so the supplier only
/// converts **leftover** labour/feedstock into a releasable surplus and never
/// starves its own conquest economy. This keeps the +6 OW baseline for the
/// healthy GPs (gp1/gp2) safe by construction. Planner-internal (not a new
/// `ai_victory_config.dart` constant).
const double kSupplierBuildInputReleaseProductionScoreBoost = 5.0;

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
      // Refs #3122 orchestrator wiring: when the orchestrator will
      // recompute trade orders after domain planning (so pending
      // build / recruit / research costs feed the treasury budget),
      // return the empty list here to avoid emitting a stale planner
      // pass whose results would be discarded.
      tradeOrders: skipTradeOrderGeneration
          ? const <TradeOrder>[]
          : runTreasuryPlanner(
              game: game,
              playerId: view.playerId,
              stockpile: stockpile,
              productionAssignments: const [],
              treasury: player.treasury,
              tileMapByRegion: tileMapByRegion,
              topology: topology,
            ),
    );
  }

  final militaryRebuildCrisis = snapshot != null &&
      isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned) &&
      snapshot.threats.atWarWith.isNotEmpty &&
      regimentCountForPlayer(game, view.playerId) <
          kStalledMinRegimentCountWhenAtWar;

  final expandEconomy = phasePlan != null
      ? expandEconomyPlanFromPhasePlan(phasePlan)
      : ExpandEconomyPlan.defaultPlan;
  final missingRegimentBuildInputs =
      _missingCheapestRegimentBuildInputIds(stockpile);
  // Refs #2847 § H8-extraction (S7-D lumber re-localization): when the
  // improvement-input gate is active (a recovered, zero-regiment lock-recovery
  // seller that owns an unimproved feedstock tile), the level-0
  // `build_improvement` material is `{lumber: 1, castIron: 1}`. `castIron` is
  // *waived* at level 0 (`feedstockBootstrapBuildImprovementCastIronWaived`),
  // so the *binding* input is `lumber`, and seed-42 lumber market supply is
  // structurally thin (one offerer). The seller therefore produces **every**
  // producible level-0 improvement input it is short of from its own owned
  // feedstock — `lumber` from `timber` and `castIron` from `timber` + `iron` —
  // not just the market-absent `castIron` the prior castIron-only set covered.
  // The gate self-clears for any healthy GP (gp1/gp2), so the +6 OW baseline is
  // unaffected. SPEC/ai/economy-planner.md § Domestic improvement-input
  // production.
  final domesticImprovementInputOutputs =
      selfLockRecoverySellerNeededProducibleImprovementInputs(
        game,
        view.playerId,
      );
  // Refs #2847 § H8 production allocation (S7-D castIron production-assignment,
  // PR #3289): once a recovered lock-recovery seller improves its fabric
  // feedstock tile, `selfLockRecoverySellerNeededProducibleImprovementInputs`
  // goes empty (its gate keys on owning an *unimproved* `wool` / `cotton`
  // tile), so a seller that co-holds the `castIron` feedstock (`timber` +
  // `iron`) and runs the materially-feasible `castIron` recipe ~53 turns on
  // seed 42 (gp5) never stages it — a production-allocation gap. This adds the
  // **multi-input** producible improvement input (`castIron`) the seller is
  // short of, gated on it still owning a `timber` / `iron` feedstock tile, so
  // the domestic run is staged across the feasible window. Treasury-independent
  // (production spends no treasury), self-clears on regiment ownership, and
  // never routes the +6 baseline GPs (gp1 / gp2 hold regiments).
  // SPEC/ai/economy-planner.md § Domestic improvement-input production.
  final stageableImprovementInputs =
      selfLockRecoverySellerStageableImprovementInputs(game, view.playerId);
  // Refs #2847 § H8 production allocation: the boost stages the cheapest
  // regiment's build input (`fabric`) whenever the EXPAND rebuild directive is
  // active for a zero-regiment GP that is short the input — **independent of
  // treasury**. The phase planner already sets `forceCheapestRegimentBuild`
  // (arm A: `regimentCount == 0` + invadable OW frontier) regardless of
  // treasury "so the rebuild trap cannot stick" (expand_phase_planner.dart),
  // but the prior `player.treasury >= cheapestRegimentBuildTreasuryCost()`
  // clause re-imposed that exact trap on the *input*: the failing seed-42 GPs
  // sit below the regiment cost ~97 of 100 turns, so the build input was only
  // ever produced on the rare recovered turn — never staged ahead of it, so
  // the multi-turn feedstock -> fabric -> build chain could not finish inside
  // the brief recovery window. Producing the cheap input ahead of treasury is
  // harmless (labour is still capped, no treasury is spent) and self-clears the
  // moment the input lands or a regiment is owned (`regimentCount == 0` guard),
  // so the +6 OW baseline GPs (gp1 / gp2, holding regiments) are unaffected.
  // The actual build order still requires the treasury cost via the
  // orchestrator's build pipeline. SPEC/ai/economy-planner.md § Regiment
  // build-input production priority.
  // Refs #2847 § castIron labour peasant-recruit fabric bootstrap: the peasant
  // recruit row costs 2 `fabric` while the cheapest regiment build input only
  // requires 1, so a seller holding one unit is not in
  // `_missingCheapestRegimentBuildInputIds` yet still cannot pay the recruit
  // the #3303 boost emits. Stage domestic `fabric` production ahead of the
  // recruit whenever the castIron-labour peasant-recruitment flag is active
  // and the stockpile is short the recruit cost — gp5 already shows the
  // fabric recipe materially feasible ~48 turns on seed 42.
  final castIronLabourPeasantRecruitFabricBoost =
      expandEconomy.boostCastIronLabourPeasantRecruitment &&
      isCastIronLabourPeasantRecruitFabricShort(stockpile);
  final regimentBuildInputProductionBoost =
      (expandEconomy.forceCheapestRegimentBuild &&
          regimentCountForPlayer(game, view.playerId) == 0 &&
          missingRegimentBuildInputs.isNotEmpty) ||
      domesticImprovementInputOutputs.isNotEmpty ||
      stageableImprovementInputs.isNotEmpty ||
      castIronLabourPeasantRecruitFabricBoost;
  final boostedBuildInputOutputs = <String>{
    ...missingRegimentBuildInputs,
    ...domesticImprovementInputOutputs,
    ...stageableImprovementInputs,
    if (castIronLabourPeasantRecruitFabricBoost) CommodityCatalog.fabric.id,
  };

  // Refs #2847 H8-supply (S7-D lumber re-localization): an affluent supplier
  // over-produces the *producible* level-0 `build_improvement` inputs a *peer*
  // lock-recovery seller needs but cannot source from the market, so the
  // treasury planner can release the resulting surplus into the seller's bid.
  // On seed 42 the binding input is `lumber` (the level-0 cost is `{lumber: 1,
  // castIron: 1}` but `castIron` is waived at level 0, and lumber market supply
  // is structurally thin), with `castIron` covered for the post-waiver stage —
  // [peerLockRecoverySellerNeededProducibleImprovementInputs] returns exactly
  // the inputs a peer seller is short of (lumber and/or castIron), so the boost
  // tracks the actual demand instead of a hard-coded `{castIron}` set that the
  // seller does not need at level 0. The supplier role excludes a GP that is
  // itself a locked seller (its own self-path boost already covers it) and the
  // boost is intentionally small so only spare labour/feedstock is consumed —
  // the +6 OW baseline GPs are never starved. SPEC/ai/economy-planner.md
  // § Supplier improvement-input over-production for release.
  final supplierReleaseImprovementInputs =
      isBelowQuotaZeroNwLockRecoverySeller(game, view.playerId)
          ? const <String>{}
          : peerLockRecoverySellerNeededProducibleImprovementInputs(
              game,
              excludePlayerId: view.playerId,
            );

  // Refs #2847 H8-extraction feedstock co-availability: the multi-input
  // `castIron` recipe needs `timber` + `iron` together, but the single-input
  // `lumber_from_timber` recipe drains `timber` every turn, so the feedstock
  // never co-accumulates for one `castIron` run and the production boost above
  // is consulted only after `feasibleRuns(castIron) > 0`. Reserve one run's
  // feedstock for each domestically-produced improvement input the GP is
  // actively producing — its own seller-side need
  // (`domesticImprovementInputOutputs`) and the peer supplier-release need
  // (`supplierReleaseImprovementInputs`) — so competing recipes cannot consume
  // the reserved `timber` / `iron` while the multi-input recipe is still
  // assembling its feedstock. The reserve is bounded to one run and
  // self-clears when neither set targets a multi-input output.
  //
  // Refs #2847 § H8-extraction (S7-D lumber re-localization): the seller's own
  // domestic production set is restricted to its *multi-input* outputs for
  // reserve purposes. A single-input recipe (`lumber_from_timber`) has no
  // co-availability problem, so reserving its feedstock would needlessly
  // withhold `timber` — worse, marking the seller's `lumber` a reserve target
  // would let the single-input recipe drain the `timber` a co-located
  // multi-input `castIron` run is still assembling, defeating the seller's own
  // co-availability guarantee. The peer supplier-release set is left unchanged:
  // an affluent supplier reserves feedstock to co-accumulate its *own* released
  // surplus run (#3267), and the seller's `supplierReleaseImprovementInputs` is
  // always empty (locked sellers are excluded from the supplier role), so this
  // only relaxes the seller path while preserving the supplier's release sizing
  // and the +6 OW baseline.
  final feedstockReserveOutputIds = <String>{
    ..._multiInputImprovementOutputs(domesticImprovementInputOutputs),
    ..._multiInputImprovementOutputs(stageableImprovementInputs),
    ...supplierReleaseImprovementInputs,
  };

  final assignments = _allocateLabour(
    stockpile: stockpile,
    workers: workers,
    effectiveLabour: effectiveLabour,
    config: config,
    seeds: seeds,
    militaryRebuildCrisis: militaryRebuildCrisis,
    regimentBuildInputProductionBoost: regimentBuildInputProductionBoost,
    missingRegimentBuildInputIds: boostedBuildInputOutputs,
    supplierReleaseImprovementInputIds: supplierReleaseImprovementInputs,
    feedstockReserveOutputIds: feedstockReserveOutputIds,
  );

  final cargoPref = _cargoPreference(
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
          game: game,
          playerId: view.playerId,
          stockpile: stockpile,
          productionAssignments: assignments,
          treasury: player.treasury,
          tileMapByRegion: tileMapByRegion,
          topology: topology,
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

/// Commodity ids the cheapest regiment still needs in the stockpile before
/// `suggestBuildOrders` will surface it (Refs #2847 H8).
Set<String> _missingCheapestRegimentBuildInputIds(Stockpile stockpile) {
  final missing = <String>{};
  for (final entry in RegimentEconomyCatalog.peasantLevies.buildInputs.entries) {
    if (stockpile.quantityOf(entry.key) < entry.value) {
      missing.add(entry.key);
    }
  }
  return missing;
}

List<AssignedRecipe> _allocateLabour({
  required Stockpile stockpile,
  required WorkerPool workers,
  required int effectiveLabour,
  required AIConfig config,
  required AISeedBundle seeds,
  bool militaryRebuildCrisis = false,
  bool regimentBuildInputProductionBoost = false,
  Set<String> missingRegimentBuildInputIds = const {},
  Set<String> supplierReleaseImprovementInputIds = const {},
  Set<String> feedstockReserveOutputIds = const {},
}) {
  final recipes = ProductionRecipesCatalog.all;
  final agendaId = config.hiddenAgendaId;
  Stockpile virtual = stockpile;
  var remainingLabour = effectiveLabour;
  final result = <AssignedRecipe>[];

  // One production run's feedstock reserved for the multi-input improvement
  // recipes the GP is actively producing (Refs #2847 H8-extraction feedstock
  // co-availability). Empty when no such recipe is targeted, in which case
  // feasibility falls back to the unreduced stockpile (behaviour-equal).
  final feedstockReserve =
      _feedstockReserveForOutputs(feedstockReserveOutputIds);

  // Build feasible recipes with scores. Feasible = can run at least 1 full run.
  final candidates = <ScoredRecipe>[];
  for (final recipe in recipes) {
    final labourPerOutput = recipe.labourPerOutput;
    if (labourPerOutput <= 0) continue;
    // A reserve-target recipe consumes its own reserved feedstock, so it sees
    // the full stockpile; every other recipe sees the reserve withheld so it
    // cannot drain the feedstock the target recipe is assembling.
    final feasibilityStock =
        feedstockReserveOutputIds.contains(recipe.outputCommodityId)
            ? virtual
            : _stockpileWithReserve(virtual, feedstockReserve);
    final runs = feasibleRuns(
      recipe: recipe,
      stockpile: feasibilityStock,
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
    if (regimentBuildInputProductionBoost &&
        missingRegimentBuildInputIds.contains(recipe.outputCommodityId)) {
      score += kRegimentBuildInputProductionScoreBoost;
    }
    if (supplierReleaseImprovementInputIds.contains(recipe.outputCommodityId)) {
      score += kSupplierBuildInputReleaseProductionScoreBoost;
    }
    candidates.add(ScoredRecipe(recipe: recipe, score: score));
  }

  if (candidates.isEmpty) return result;

  if (_log.debugEnabled) {
    _log.d(
      'recipe eval playerId=${config.leaderId} effectiveLabour=$effectiveLabour '
      'candidates=${candidates.map((c) => "${c.recipe.id}:${c.score.toStringAsFixed(2)}").toList()}',
    );
  }

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
    final feasibilityStock =
        feedstockReserveOutputIds.contains(recipe.outputCommodityId)
            ? virtual
            : _stockpileWithReserve(virtual, feedstockReserve);
    final runs = feasibleRuns(
      recipe: recipe,
      stockpile: feasibilityStock,
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

  if (_log.debugEnabled) {
    _log.d(
      'allocation effectiveLabour=$effectiveLabour '
      'labourByRecipe=$labourByRecipe assignmentsCount=${result.length}',
    );
  }
  return result;
}

/// The subset of [outputIds] whose lowest-`id` producing recipe consumes more
/// than one distinct input commodity (Refs #2847 § H8-extraction feedstock
/// co-availability; S7-D lumber re-localization). Only these multi-input
/// outputs (e.g. `castIron` from `timber` + `iron`) can have a competing
/// single-input recipe drain their partial feedstock, so only they need a
/// feedstock reserve. Single-input outputs (e.g. `lumber` from `timber`) are
/// excluded: reserving their feedstock would needlessly withhold it and, by
/// marking them reserve targets, defeat the reserve they are meant to respect.
/// Deterministic over the static `ProductionRecipesCatalog`; returns the empty
/// set when [outputIds] is empty so feasibility falls back to the unreduced
/// stockpile (behaviour-equal).
Set<String> _multiInputImprovementOutputs(Set<String> outputIds) {
  if (outputIds.isEmpty) return const <String>{};
  final result = <String>{};
  for (final outputId in outputIds) {
    final recipe = _lowestIdRecipeProducingOutput(outputId);
    if (recipe == null) continue;
    if (recipe.inputQuantities.length > 1) result.add(outputId);
  }
  return result;
}

/// The production recipe with the lowest `id` whose output is [outputId], or
/// `null` when no recipe produces it. Deterministic over the static
/// `ProductionRecipesCatalog`; uses the O(1) `producing` index instead of an
/// O(recipes) full-catalog scan (Refs #3288 step 5).
ProductionRecipe? _lowestIdRecipeProducingOutput(String outputId) {
  ProductionRecipe? best;
  for (final recipe in ProductionRecipesCatalog.producing(outputId)) {
    if (best == null || recipe.id.compareTo(best.id) < 0) best = recipe;
  }
  return best;
}

/// One production run's input requirements for each output id in
/// [outputIds], summed across outputs. Used to reserve the multi-input
/// feedstock (`timber` + `iron` for `castIron`) a domestically-produced
/// improvement input needs so single-input competitors (`lumber_from_timber`)
/// cannot drain it before the multi-input recipe accumulates a full run
/// (Refs #2847 H8-extraction feedstock co-availability). Deterministic: the
/// lowest-`id` recipe is chosen per output via the O(1) `producing` index
/// (Refs #3288 step 5) and reserve accumulation is order-independent. Returns
/// an empty map when [outputIds] is empty.
Map<CommodityId, int> _feedstockReserveForOutputs(Set<String> outputIds) {
  if (outputIds.isEmpty) return const {};
  final reserve = <CommodityId, int>{};
  for (final out in outputIds) {
    final recipe = _lowestIdRecipeProducingOutput(out);
    if (recipe == null) continue;
    for (final entry in recipe.inputQuantities.entries) {
      reserve[entry.key] = (reserve[entry.key] ?? 0) + entry.value;
    }
  }
  return reserve;
}

/// [base] with each [reserve] quantity withheld (clamped at zero). The
/// reserved feedstock is invisible to non-target recipes so they cannot
/// consume it (Refs #2847 H8-extraction feedstock co-availability). Returns
/// [base] unchanged when [reserve] is empty.
Stockpile _stockpileWithReserve(Stockpile base, Map<CommodityId, int> reserve) {
  if (reserve.isEmpty) return base;
  var adjusted = base;
  for (final entry in reserve.entries) {
    final have = adjusted.quantityOf(entry.key);
    final reduce = entry.value < have ? entry.value : have;
    if (reduce > 0) adjusted = adjusted.applyDelta(entry.key, -reduce);
  }
  return adjusted;
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
