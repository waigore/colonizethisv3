// Per-GP state for the seed-42 S7-D diagnostic campaign (Refs #3997 / #4079 Slice D).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;

import 'supply_probes.dart';
import 's7d_campaign_rollup_explorer_counters.dart';
import 's7d_campaign_rollup_trade_counters.dart';
import 's7d_campaign_rollup_feedstock_counters.dart';
import 's7d_campaign_rollup_feedstock_labour_counters.dart';
import 's7d_campaign_rollup_feedstock_extraction_gate_counters.dart';

/// Owns all mutable observation state for one S7-D campaign run.
class Seed42S7dCampaignRollup
    with
        Seed42S7dCampaignRollupExplorerCounters,
        Seed42S7dCampaignRollupTradeCounters,
        Seed42S7dCampaignRollupFeedstockCounters,
        Seed42S7dCampaignRollupFeedstockLabourCounters,
        Seed42S7dCampaignRollupFeedstockExtractionGateCounters {
  Seed42S7dCampaignRollup(this.gpIds);

  final List<String> gpIds;

  Map<String, int> zeroPerGp() => {for (final gpId in gpIds) gpId: 0};

  // Per-GP rollups; populated as the simulation advances.
  late final phaseCounts = <String, Map<ObserverGoalPhase, int>>{
    for (final gpId in gpIds)
      gpId: <ObserverGoalPhase, int>{
        for (final ph in ObserverGoalPhase.values) ph: 0,
      },
  };
  late final declareWarPicks = <String, Map<String, int>>{
    for (final gpId in gpIds) gpId: <String, int>{},
  };
  late final peaceTargetPicks = <String, Map<String, int>>{
    for (final gpId in gpIds) gpId: <String, int>{},
  };
  late final economyArmCounts = <String, Map<String, int>>{
    for (final gpId in gpIds)
      gpId: <String, int>{
        'forceCheapestRegimentBuild': 0,
        'boostTreasuryRecoveryCargo': 0,
      },
  };
  late final invadableEmptyTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  late final atWarTurnsByPeer = <String, Map<String, int>>{
    for (final gpId in gpIds) gpId: <String, int>{},
  };
  late final treasuryUnderCheapestTurns = zeroPerGp();
  late final lastSnapshotFields = <String, Map<String, Object?>>{};

  // Refs #2847 regiment-accumulation surface (post-#2924 / World
  // Market merge). Treasury starvation is no longer the dominant
  // EXPAND-lock blocker for the failing GPs; the new question is
  // whether the standing regiment count actually grows once the GP
  // can afford a build. These per-GP rollups capture the regiment
  // trajectory (peak / turns at zero / turns at-or-above the cheapest
  // build cost) and the number of military `BuildUnitOrder`s the AI
  // actually emits each turn, so a future tuning implementer can tell
  // apart "the build order is never emitted/accepted" from "regiments
  // are built but immediately lost in the peer-war zero-sum churn".
  late final regimentPeak = <String, int>{for (final gpId in gpIds) gpId: 0};
  late final regimentTurnsAtZero = zeroPerGp();
  late final treasuryAtOrAboveCheapestTurns = zeroPerGp();
  late final militaryBuildOrdersEmitted = zeroPerGp();

  // Refs #2847 H8 conversion-gap isolation. The headline H8 finding is
  // that `forceCheapestRegimentBuild` fires 85-100 turns while
  // `gpMilitaryBuildOrdersEmitted` stays at 2-4 and `gpRegimentTurnsAtZero`
  // is 39-59 for gp3 / gp5 / gp6. These accumulators split the gap into
  // its proximate sub-causes so a tuning implementer can tell apart
  // "the cheapest-regiment input (fabric) is never in the stockpile when
  // the GP is ready to build" (production / market-acquisition gap) from
  // "fabric is present and the GP is ready, yet no military build is
  // emitted" (a downstream suggestion / build-pick gate). A turn counts
  // as *rebuild-ready* when the EXPAND directive is active, treasury can
  // afford the cheapest regiment, and the GP holds zero regiments — the
  // exact condition under which the lost starting army should be
  // replaced. The cheapest regiment (`peasant_levies`) requires a single
  // unit of fabric, so fabric availability is the proximate input gate.
  late final cheapestRegimentInputs =
      RegimentEconomyCatalog.peasantLevies.buildInputs;
  late final fabricInStockpileTurns = zeroPerGp();
  late final rebuildReadyTurns = zeroPerGp();
  late final rebuildReadyNoBuildTurns = zeroPerGp();
  late final rebuildReadyNoBuildMissingInputTurns = zeroPerGp();
  late final rebuildReadyNoBuildInputsPresentTurns = zeroPerGp();
  // Cheapest-regiment input commodity ids (e.g. fabric) and the bid /
  // fill counters that prove whether the #3226 lock-recovery build-input
  // bid carve-out actually secures the input from the world market. A
  // high bid count with a near-zero fill count localizes the gap to
  // world-market *supply* (no seller / no production feedstock) rather
  // than the planner failing to bid.
  late final regimentInputCommodityIds = cheapestRegimentInputs.keys.toSet();
  late final regimentInputBidsEmitted = zeroPerGp();
  late final regimentInputDealsAsBuyer = zeroPerGp();

  // Refs #2847 H8-extraction supply-side localization. The level-0
  // `build_improvement` material (lumber + cast iron) is the prerequisite a
  // locked seller's routed Builder needs but cannot afford
  // (`gpFeedstockGateImprovementCostAffordableTurns == 0`). The
  // improvement-input bid carve-out and the treasury-independent supplier
  // release set both target these commodities, yet the seller never ends up
  // holding them. These counters split that supply gap into its proximate
  // links so a tuning implementer can tell apart, in order: (a) no GP / tribe
  // *offers* the inputs at all (`gpImprovementInputOffersEmitted` flat zero =>
  // nobody holds a releasable surplus); (b) offers exist but the seller's bid
  // never *fills* (`gpImprovementInputDealsAsBuyer` flat zero alongside
  // non-zero offers => price / priority / bid-cap matching gap); or (c) deals
  // fill but the input is consumed before the gate observes it
  // (`gpImprovementInputHeldAtTurn99` zero alongside non-zero buyer deals).
  // Read-only; the (freely tunable) counts can move as later supply slices
  // land.
  late final improvementInputCommodityIds = workOrderCostBuildImprovement(
    0,
  ).keys.toSet();
  late final improvementInputOffersEmitted = zeroPerGpCounter(gpIds);
  late final improvementInputBidsEmitted = zeroPerGpCounter(gpIds);
  late final improvementInputDealsAsBuyer = zeroPerGpCounter(gpIds);
  late final improvementInputHeldAtTurn99 = zeroPerGpCounter(gpIds);

  /// Per-turn scratch state shared between harness callbacks.
  late final pendingTurnScratch = <String, Object>{};
}
