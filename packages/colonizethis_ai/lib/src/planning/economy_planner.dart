// Economy planner: worker allocation and cargo preference. SPEC/ai/economy-planner.md.

import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart';
import 'cast_iron_labour_gate.dart'
    show
        isCastIronLabourPeasantRecruitFabricShort,
        isCastIronLabourPopulationBoundForLockRecoverySeller;
import 'expand_phase_planner.dart' hide cheapestRegimentBuildTreasuryCost;
import 'growth_stage.dart';
import 'phase_planner_dispatch.dart';
import 'phase_planner_expand_economy.dart';
import 'ai_commodity_ids.dart';
import 'economy_planner_labour.dart';
import 'economy_planner_cargo.dart';
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

  final militaryRebuildCrisis =
      snapshot != null &&
      isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned) &&
      snapshot.threats.atWarWith.isNotEmpty &&
      regimentCountForPlayer(game, view.playerId) <
          kStalledMinRegimentCountWhenAtWar;

  final expandEconomy = phasePlan != null
      ? expandEconomyPlanFromPhasePlan(phasePlan)
      : ExpandEconomyPlan.defaultPlan;
  final missingRegimentBuildInputs = missingCheapestRegimentBuildInputIds(
    stockpile,
  );
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
  // `missingCheapestRegimentBuildInputIds` yet still cannot pay the recruit
  // the #3303 boost emits. Stage domestic `fabric` production whenever the
  // castIron-labour population-bound gate holds and the stockpile is short the
  // recruit cost — **independent of** `forceCheapestRegimentBuild` / treasury
  // so wool feedstock can accumulate across the ~31 gate turns on seed 42 even
  // when the EXPAND rebuild directive is inactive that turn. The orchestrator
  // recruit pass still requires `boostCastIronLabourPeasantRecruitment`.
  final castIronLabourPeasantRecruitFabricBoost =
      isCastIronLabourPopulationBoundForLockRecoverySeller(
        game: game,
        playerId: view.playerId,
      ) &&
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
    if (castIronLabourPeasantRecruitFabricBoost) kAiCommodityIds.fabric,
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
      isBelowQuotaZeroNwLockRecoverySeller(
        game,
        view.playerId,
        snapshot: snapshot,
      )
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
    ...multiInputImprovementOutputs(domesticImprovementInputOutputs),
    ...multiInputImprovementOutputs(stageableImprovementInputs),
    ...supplierReleaseImprovementInputs,
  };

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
      militaryRebuildCrisis: militaryRebuildCrisis,
      regimentBuildInputProductionBoost: growthStagePlannerEnabled
          ? false
          : regimentBuildInputProductionBoost,
      missingRegimentBuildInputIds: growthStagePlannerEnabled
          ? const <String>{}
          : boostedBuildInputOutputs,
      supplierReleaseImprovementInputIds: growthStagePlannerEnabled
          ? const <String>{}
          : supplierReleaseImprovementInputs,
      feedstockReserveOutputIds: growthStagePlannerEnabled
          ? const <String>{}
          : feedstockReserveOutputIds,
      castIronLabourPeasantRecruitFabricBoost: growthStagePlannerEnabled
          ? false
          : castIronLabourPeasantRecruitFabricBoost,
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
