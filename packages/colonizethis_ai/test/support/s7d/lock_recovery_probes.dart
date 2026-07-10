// S7-D lock-recovery diagnostic counters and invariants (Refs #2847 / #3941).
// Split from `seed42_s7d_feedstock_helpers.dart`.

import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart'
    show ObserverGoalPhase;
import 'package:colonizethis_ai/src/planning/cast_iron_labour_gate.dart'
    show
        isCastIronLabourPopulationBoundForLockRecoverySeller,
        otherGreatPowerFabricHeld;
import 'package:colonizethis_ai/src/planning/treasury_planner.dart'
    show kTreasuryOfferPriorityUrgent, otherGreatPowerOfferableFabricHeld;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'extraction_probes.dart';
import 'supply_probes.dart';

/// Structural-invariant assertions over the S7-D diagnostic per-GP counter
/// maps (Refs #2847). Extracted from
/// `seed42_observer_conquest_s7d_diagnostic_test.dart` to keep that file at or
/// below the repo non-comment line limit (`repo.dart_file_non_comment_line_size`).
///
/// The diagnostic deliberately does not pin arm-fire counts so the planner can
/// be tuned freely without churn here; these assertions only guard the
/// instrumentation itself (the counters partition / bound each other as their
/// definitions require). Each `[gpId]` map is expected to contain an entry for
/// every id in [gpIds].
void assertSeed42S7dStructuralInvariants({
  required List<String> gpIds,
  required Map<String, Map<ObserverGoalPhase, int>> phaseCounts,
  required Map<String, int> rebuildReadyNoBuildTurns,
  required Map<String, int> rebuildReadyNoBuildMissingInputTurns,
  required Map<String, int> rebuildReadyNoBuildInputsPresentTurns,
  required Map<String, int> feedstockExtractionGateActiveTurns,
  required Map<String, int> feedstockGateIdleBuilderPresentTurns,
  required Map<String, int> feedstockGateImprovedTileOwnedTurns,
  required Map<String, int> feedstockGateValidBuildImprovementCandidateTurns,
  required Map<String, int> feedstockGateImprovementCostAffordableTurns,
  required Map<String, int> feedstockGateImprovementLumberAffordableTurns,
  required Map<String, int> feedstockGateImprovementCastIronAffordableTurns,
  required Map<String, int> feedstockAcquisitionTargetActiveTurns,
  required Map<String, int> feedstockAcquisitionTargetWithFieldArmyTurns,
  required Map<String, int> castIronLabourPeasantRecruitGateTurns,
  required Map<String, int> castIronLabourPeasantRecruitAffordableTurns,
  required Map<String, int> castIronLabourPeasantRecruitFabricStarvedTurns,
  required Map<String, int>
  castIronLabourPeasantRecruitMarketFabricStarvedTurns,
  required Map<String, int>
  castIronLabourPeasantRecruitMarketFabricUnofferedTurns,
  required Map<String, int> castIronLabourPeasantRecruitFabricBidEmittedTurns,
  required Map<String, int> castIronLabourPeasantRecruitFabricBidAbsentTurns,
  required Map<String, int> castIronLabourPeasantRecruitFabricDealAsBuyerTurns,
  required Map<String, int> fabricRecipeFeasibleTurns,
  required Map<String, int> fabricRecipeLabourFeasibleTurns,
  required Map<String, int> castIronMarketOfferPresentTurns,
  required Map<String, int> castIronMarketOfferAbsentTurns,
  required Map<String, int> castIronFeedstockExtractionLabourFutileTurns,
}) {
  for (final gpId in gpIds) {
    expect(
      phaseCounts[gpId]!.values.fold<int>(0, (a, b) => a + b),
      100,
      reason: '$gpId phase-count total should equal turn count',
    );
    // Refs #2847 H8: structural invariant on the conversion-gap split.
    // Every rebuild-ready turn with no military build is attributed to
    // exactly one of the two mutually exclusive sub-causes, so the parts
    // must sum to the whole. This guards the instrumentation itself
    // without pinning the (freely tunable) per-GP counts.
    expect(
      rebuildReadyNoBuildMissingInputTurns[gpId]! +
          rebuildReadyNoBuildInputsPresentTurns[gpId]!,
      rebuildReadyNoBuildTurns[gpId],
      reason:
          '$gpId rebuild-ready no-build turns must split into '
          'missing-input + inputs-present sub-causes',
    );
    // Refs #2847 H8-extraction: the disambiguation sub-counters are each
    // measured only on a feedstock-gate-active turn, so neither can exceed
    // the gate-active total. Guards the instrumentation gating itself
    // without pinning the (freely tunable) per-GP counts.
    expect(
      feedstockGateIdleBuilderPresentTurns[gpId]!,
      lessThanOrEqualTo(feedstockExtractionGateActiveTurns[gpId]!),
      reason:
          '$gpId idle-Builder-present turns cannot exceed the '
          'feedstock-extraction-gate-active turns',
    );
    expect(
      feedstockGateImprovedTileOwnedTurns[gpId]!,
      lessThanOrEqualTo(feedstockExtractionGateActiveTurns[gpId]!),
      reason:
          '$gpId improved-feedstock-tile-owned turns cannot exceed the '
          'feedstock-extraction-gate-active turns',
    );
    // Refs #2847 H8-extraction missing-candidate disambiguation: both
    // sub-counters are measured only on a feedstock-gate-active turn, so
    // neither can exceed the gate-active total. Guards the instrumentation
    // gating itself without pinning the (freely tunable) per-GP counts.
    expect(
      feedstockGateValidBuildImprovementCandidateTurns[gpId]!,
      lessThanOrEqualTo(feedstockExtractionGateActiveTurns[gpId]!),
      reason:
          '$gpId valid-feedstock-build_improvement-candidate turns cannot '
          'exceed the feedstock-extraction-gate-active turns',
    );
    expect(
      feedstockGateImprovementCostAffordableTurns[gpId]!,
      lessThanOrEqualTo(feedstockExtractionGateActiveTurns[gpId]!),
      reason:
          '$gpId feedstock improvement-cost-affordable turns cannot exceed '
          'the feedstock-extraction-gate-active turns',
    );
    // Refs #2847 H8-extraction per-component affordability split: each
    // per-material counter is measured only on a gate-active turn, and the
    // combined (lumber AND castIron) counter can never exceed either
    // component on its own. Guards the localization instrumentation without
    // pinning the (freely tunable) per-GP counts.
    expect(
      feedstockGateImprovementLumberAffordableTurns[gpId]!,
      lessThanOrEqualTo(feedstockExtractionGateActiveTurns[gpId]!),
      reason:
          '$gpId feedstock improvement-lumber-affordable turns cannot '
          'exceed the feedstock-extraction-gate-active turns',
    );
    expect(
      feedstockGateImprovementCastIronAffordableTurns[gpId]!,
      lessThanOrEqualTo(feedstockExtractionGateActiveTurns[gpId]!),
      reason:
          '$gpId feedstock improvement-castIron-affordable turns cannot '
          'exceed the feedstock-extraction-gate-active turns',
    );
    expect(
      feedstockGateImprovementCostAffordableTurns[gpId]!,
      lessThanOrEqualTo(feedstockGateImprovementLumberAffordableTurns[gpId]!),
      reason:
          '$gpId combined improvement-cost-affordable turns cannot exceed '
          'the lumber-component-affordable turns (combined requires both)',
    );
    expect(
      feedstockGateImprovementCostAffordableTurns[gpId]!,
      lessThanOrEqualTo(feedstockGateImprovementCastIronAffordableTurns[gpId]!),
      reason:
          '$gpId combined improvement-cost-affordable turns cannot exceed '
          'the castIron-component-affordable turns (combined requires both)',
    );
    // Refs #2847 H8-extraction acquisition-thread localization: the
    // field-army subset is recorded only on an acquisition-target-active
    // turn, so it can never exceed the active total, and neither counter
    // can exceed the 100-turn run. Guards the instrumentation gating itself
    // without pinning the (freely tunable) per-GP counts.
    expect(
      feedstockAcquisitionTargetWithFieldArmyTurns[gpId]!,
      lessThanOrEqualTo(feedstockAcquisitionTargetActiveTurns[gpId]!),
      reason:
          '$gpId acquisition-target-with-field-army turns cannot exceed '
          'the acquisition-target-active turns',
    );
    expect(
      feedstockAcquisitionTargetActiveTurns[gpId]!,
      lessThanOrEqualTo(100),
      reason:
          '$gpId acquisition-target-active turns cannot exceed the '
          '100-turn run length',
    );
    // Refs #2847 peasant-recruit localization: the affordable and
    // fabric-starved sub-counters partition the #3303 gate-active turns,
    // and the gate total cannot exceed the 100-turn run. Guards the
    // instrumentation gating itself without pinning the (freely tunable)
    // per-GP counts.
    expect(
      castIronLabourPeasantRecruitAffordableTurns[gpId]! +
          castIronLabourPeasantRecruitFabricStarvedTurns[gpId]!,
      castIronLabourPeasantRecruitGateTurns[gpId],
      reason:
          '$gpId peasant-recruit gate-active turns must split into '
          'affordable + fabric-starved sub-causes',
    );
    expect(
      castIronLabourPeasantRecruitGateTurns[gpId]!,
      lessThanOrEqualTo(100),
      reason:
          '$gpId peasant-recruit gate-active turns cannot exceed the '
          '100-turn run length',
    );
    // Refs #2847 § S7-D market-fabric localization: the market-fabric-starved
    // counter is a strict refinement of the fabric-starved turns (gate active
    // AND recruit unpayable AND no other GP holds fabric), so it can never
    // exceed the fabric-starved total. Guards the instrumentation gating
    // itself without pinning the (freely tunable) per-GP counts.
    expect(
      castIronLabourPeasantRecruitMarketFabricStarvedTurns[gpId]!,
      lessThanOrEqualTo(castIronLabourPeasantRecruitFabricStarvedTurns[gpId]!),
      reason:
          '$gpId peasant-recruit market-fabric-starved turns cannot exceed '
          'the fabric-starved turns (market-starved requires fabric-starved)',
    );
    // Refs #2847 § S7-D market-fabric offer/acquisition localization: the
    // market-fabric-unoffered counter is also a subset of the fabric-starved
    // turns (gate active AND recruit unpayable AND holders present yet none
    // offerable), AND it is mutually exclusive with the market-fabric-starved
    // counter (one requires `otherGreatPowerFabricHeld <= 0`, the other
    // `> 0`), so the two offer-side subsets together cannot exceed the
    // fabric-starved total. Guards the instrumentation gating itself without
    // pinning the (freely tunable) per-GP counts.
    expect(
      castIronLabourPeasantRecruitMarketFabricUnofferedTurns[gpId]!,
      lessThanOrEqualTo(castIronLabourPeasantRecruitFabricStarvedTurns[gpId]!),
      reason:
          '$gpId peasant-recruit market-fabric-unoffered turns cannot exceed '
          'the fabric-starved turns (unoffered requires fabric-starved)',
    );
    expect(
      castIronLabourPeasantRecruitMarketFabricStarvedTurns[gpId]! +
          castIronLabourPeasantRecruitMarketFabricUnofferedTurns[gpId]!,
      lessThanOrEqualTo(castIronLabourPeasantRecruitFabricStarvedTurns[gpId]!),
      reason:
          '$gpId market-fabric-starved and market-fabric-unoffered turns are '
          'disjoint fabric-starved subsets, so their sum cannot exceed the '
          'fabric-starved total',
    );
    // Refs #2847 § S7-D buyer-side fabric acquisition: bid-emitted and
    // bid-absent counters are each measured only on fabric-starved turns with
    // offerable counterparty supply, so neither can exceed the fabric-starved
    // total; deals-as-buyer cannot exceed bid-emitted turns on the same axis.
    expect(
      castIronLabourPeasantRecruitFabricBidEmittedTurns[gpId]!,
      lessThanOrEqualTo(castIronLabourPeasantRecruitFabricStarvedTurns[gpId]!),
      reason:
          '$gpId peasant-recruit fabric-bid-emitted turns cannot exceed the '
          'fabric-starved turns',
    );
    expect(
      castIronLabourPeasantRecruitFabricBidAbsentTurns[gpId]!,
      lessThanOrEqualTo(castIronLabourPeasantRecruitFabricStarvedTurns[gpId]!),
      reason:
          '$gpId peasant-recruit fabric-bid-absent turns cannot exceed the '
          'fabric-starved turns',
    );
    expect(
      castIronLabourPeasantRecruitFabricBidEmittedTurns[gpId]! +
          castIronLabourPeasantRecruitFabricBidAbsentTurns[gpId]!,
      lessThanOrEqualTo(castIronLabourPeasantRecruitFabricStarvedTurns[gpId]!),
      reason:
          '$gpId fabric-bid-emitted and fabric-bid-absent turns are disjoint '
          'buyer-side subsets of offerable-supply fabric-starved turns',
    );
    expect(
      castIronLabourPeasantRecruitFabricDealAsBuyerTurns[gpId]!,
      lessThanOrEqualTo(
        castIronLabourPeasantRecruitFabricBidEmittedTurns[gpId]!,
      ),
      reason:
          '$gpId peasant-recruit fabric deals-as-buyer turns cannot exceed '
          'fabric-bid-emitted turns on the same axis',
    );
    // Refs #2847 § S7-D fabric circular-labour localization: a fabric run is
    // labour-feasible only when it is also materially feasible
    // (`feasibleRuns` incorporates the input check), so the labour-feasible
    // count can never exceed the material-feasible count. Guards the
    // instrumentation without pinning the (freely tunable) per-GP counts.
    expect(
      fabricRecipeLabourFeasibleTurns[gpId]!,
      lessThanOrEqualTo(fabricRecipeFeasibleTurns[gpId]!),
      reason:
          '$gpId fabric labour-feasible turns cannot exceed the fabric '
          'material-feasible turns (labour-feasible requires material-feasible)',
    );
    // Refs #2847 § castIron market-supply wall: every feedstock-extraction
    // gate-active turn is classified as exactly one of castIron-offer-present
    // or castIron-offer-absent, so the two partition the gate-active total.
    // Guards the instrumentation gating itself without pinning the (freely
    // tunable) per-GP counts.
    expect(
      castIronMarketOfferPresentTurns[gpId]! +
          castIronMarketOfferAbsentTurns[gpId]!,
      feedstockExtractionGateActiveTurns[gpId],
      reason:
          '$gpId castIron market-offer present + absent turns must partition '
          'the feedstock-extraction-gate-active turns',
    );
    // Refs #2847 § S7-D castIron-feedstock order-matching off-critical path:
    // the labour-futile counter is measured only on a feedstock-extraction-
    // gate-active turn (raw labour ceiling below the castIron labourPerOutput),
    // so it can never exceed the gate-active total. Guards the instrumentation
    // gating itself without pinning the (freely tunable) per-GP counts.
    expect(
      castIronFeedstockExtractionLabourFutileTurns[gpId]!,
      lessThanOrEqualTo(feedstockExtractionGateActiveTurns[gpId]!),
      reason:
          '$gpId castIron-feedstock-extraction labour-futile turns cannot '
          'exceed the feedstock-extraction-gate-active turns',
    );
  }
}

/// Tallies the per-GP submitted trade-order counters for one turn from the
/// merged order list the resolver will apply (Refs #2924 Step 0). Mirrors the
/// inline scan it replaced: each offer bumps [tradeOfferCount] (plus
/// [tradeUrgentOfferCount] / [improvementInputOffersEmitted] /
/// [castIronFeedstockOffersEmitted] where the order qualifies); each bid bumps
/// [tradeBidCount] (plus the regiment- / improvement-input and castIron-
/// feedstock bid counters where the commodity matches). Carry-forward
/// world-market re-injections are excluded by construction — the caller passes
/// only the AI-emitted merged orders. Read-only over the supplied maps except
/// for the counter bumps. Extracted to keep the diagnostic test file at or
/// below the repo non-comment line limit.
void recordSeed42S7dTradeOrderCounters({
  required List<String> gpIds,
  required Map<String, List<TradeOrder>> tradeOrdersByPlayerId,
  required Set<String> regimentInputCommodityIds,
  required Set<String> improvementInputCommodityIds,
  required Set<String> castIronFeedstockIds,
  required Map<String, int> tradeOfferCount,
  required Map<String, int> tradeUrgentOfferCount,
  required Map<String, int> tradeBidCount,
  required Map<String, int> improvementInputOffersEmitted,
  required Map<String, int> castIronFeedstockOffersEmitted,
  required Map<String, int> regimentInputBidsEmitted,
  required Map<String, int> improvementInputBidsEmitted,
  required Map<String, int> castIronFeedstockBidsEmitted,
}) {
  for (final gpId in gpIds) {
    final tradeOrders = tradeOrdersByPlayerId[gpId];
    if (tradeOrders == null) continue;
    for (final order in tradeOrders) {
      _recordSeed42S7dTradeOrderCounter(
        gpId: gpId,
        order: order,
        regimentInputCommodityIds: regimentInputCommodityIds,
        improvementInputCommodityIds: improvementInputCommodityIds,
        castIronFeedstockIds: castIronFeedstockIds,
        tradeOfferCount: tradeOfferCount,
        tradeUrgentOfferCount: tradeUrgentOfferCount,
        tradeBidCount: tradeBidCount,
        improvementInputOffersEmitted: improvementInputOffersEmitted,
        castIronFeedstockOffersEmitted: castIronFeedstockOffersEmitted,
        regimentInputBidsEmitted: regimentInputBidsEmitted,
        improvementInputBidsEmitted: improvementInputBidsEmitted,
        castIronFeedstockBidsEmitted: castIronFeedstockBidsEmitted,
      );
    }
  }
}

/// Records the per-GP counter bumps for a single merged [order] (Refs #2924
/// Step 0). Extracted from [recordSeed42S7dTradeOrderCounters] so the scan loop
/// stays within the repo control-flow nesting-depth limit; behavior is
/// identical to the inline offer/bid handling it replaced. Read-only over the
/// supplied sets except for the counter bumps.
void _recordSeed42S7dTradeOrderCounter({
  required String gpId,
  required TradeOrder order,
  required Set<String> regimentInputCommodityIds,
  required Set<String> improvementInputCommodityIds,
  required Set<String> castIronFeedstockIds,
  required Map<String, int> tradeOfferCount,
  required Map<String, int> tradeUrgentOfferCount,
  required Map<String, int> tradeBidCount,
  required Map<String, int> improvementInputOffersEmitted,
  required Map<String, int> castIronFeedstockOffersEmitted,
  required Map<String, int> regimentInputBidsEmitted,
  required Map<String, int> improvementInputBidsEmitted,
  required Map<String, int> castIronFeedstockBidsEmitted,
}) {
  if (order.type == TradeOrderType.offer) {
    bumpCounter(tradeOfferCount, gpId);
    if (order.priority >= kTreasuryOfferPriorityUrgent) {
      bumpCounter(tradeUrgentOfferCount, gpId);
    }
    if (improvementInputCommodityIds.contains(order.commodityId)) {
      bumpCounter(improvementInputOffersEmitted, gpId);
    }
    if (castIronFeedstockIds.contains(order.commodityId)) {
      bumpCounter(castIronFeedstockOffersEmitted, gpId);
    }
    return;
  }
  if (order.type != TradeOrderType.bid) return;
  bumpCounter(tradeBidCount, gpId);
  if (regimentInputCommodityIds.contains(order.commodityId)) {
    bumpCounter(regimentInputBidsEmitted, gpId);
  }
  if (improvementInputCommodityIds.contains(order.commodityId)) {
    bumpCounter(improvementInputBidsEmitted, gpId);
  }
  if (castIronFeedstockIds.contains(order.commodityId)) {
    bumpCounter(castIronFeedstockBidsEmitted, gpId);
  }
}

/// Records buyer-side `fabric` bid emission for the S7-D peasant-recruit
/// localization (Refs #2847 § buyer-side fabric acquisition). On each
/// fabric-starved gp this turn with offerable counterparty fabric supply
/// (`otherGreatPowerOfferableFabricHeld > 0`), bumps [emittedTurns] when the gp
/// emitted a `fabric` bid in [tradeOrdersByPlayerId], else [absentTurns].
/// Read-only over `(game, tradeOrdersByPlayerId)` except the counter bumps;
/// extracted to keep the diagnostic test file at or below the repo non-comment
/// line limit.
void recordSeed42S7dFabricBidCounters({
  required Game game,
  required Set<String> fabricStarvedThisTurn,
  required Map<String, List<TradeOrder>> tradeOrdersByPlayerId,
  required Map<String, int> emittedTurns,
  required Map<String, int> absentTurns,
}) {
  const fabricCommodityId = 'fabric';
  for (final gpId in fabricStarvedThisTurn) {
    if (otherGreatPowerOfferableFabricHeld(game, gpId) <= 0) continue;
    final tradeOrders = tradeOrdersByPlayerId[gpId];
    final emittedFabricBid =
        tradeOrders != null &&
        tradeOrders.any(
          (order) =>
              order.type == TradeOrderType.bid &&
              order.commodityId == fabricCommodityId,
        );
    if (emittedFabricBid) {
      bumpCounter(emittedTurns, gpId);
    } else {
      bumpCounter(absentTurns, gpId);
    }
  }
}

/// Records castIron market-offer presence/absence for the S7-D
/// feedstock-extraction localization (Refs #2847 § castIron market-supply
/// wall). On each gp whose regiment-build-input feedstock-extraction gate is
/// active this turn ([feedstockGateActiveThisTurn]), scans
/// [tradeOrdersByPlayerId] for any *other* faction emitting a
/// [castIronCommodityId] offer this turn and bumps [presentTurns] when one
/// exists, else [absentTurns].
///
/// The level-0 `build_improvement` cost a locked seller must clear to extract
/// its fabric feedstock requires one unit of the manufactured `castIron`
/// (`work_order_costs.dart` § `workOrderCostBuildImprovement`). The treasury
/// planner's direct-acquisition branch
/// (`treasury_regiment_bootstrap.dart` Pass 1 → `_marketHasStandingOfferSupplyFromOthers`)
/// only bids `castIron` directly when some other Great Power offers it;
/// otherwise it falls back to bidding the production feedstock (`timber` +
/// `iron`) for a domestic run. A flat-zero [presentTurns] across the run proves
/// the direct-acquisition branch is permanently closed — every Great Power
/// consumes its `castIron` for Old World military builds and never offers a
/// surplus (corroborated by `gpCastIronHeldAtTurn99 == 0` for every GP) — so
/// the only remaining path to the improvement input is the domestic castIron
/// run, which the labour-aware `gpCastIronRecipeLabourFeasibleTurns == 0`
/// counter shows is itself labour-walled (`castIron` `labourPerOutput` exceeds
/// a lock-recovery seller's effective labour). Read-only over the supplied maps
/// except the counter bumps; extracted to keep the diagnostic test file at or
/// below the repo non-comment line limit.
void recordSeed42S7dCastIronMarketOfferCounters({
  required Set<String> feedstockGateActiveThisTurn,
  required Map<String, List<TradeOrder>> tradeOrdersByPlayerId,
  required String castIronCommodityId,
  required Map<String, int> presentTurns,
  required Map<String, int> absentTurns,
}) => recordSeed42S7dOtherFactionOfferCounters(
  activeThisTurn: feedstockGateActiveThisTurn,
  tradeOrdersByPlayerId: tradeOrdersByPlayerId,
  commodityId: castIronCommodityId,
  presentTurns: presentTurns,
  absentTurns: absentTurns,
);

/// Shared other-faction sell-offer present/absent tally backing the castIron
/// and `fabric` market-offer recorders (Refs #2847). For each gp in
/// [activeThisTurn], scans [tradeOrdersByPlayerId] for any *other* faction
/// emitting a [commodityId] sell offer this turn and bumps [presentTurns] when
/// one exists, else [absentTurns]. The gp's own offer never counts as supply,
/// and bids (demand) are ignored. Read-only over the supplied maps except the
/// counter bumps; extracted so the two single-commodity recorders share one
/// scan loop.
void recordSeed42S7dOtherFactionOfferCounters({
  required Set<String> activeThisTurn,
  required Map<String, List<TradeOrder>> tradeOrdersByPlayerId,
  required String commodityId,
  required Map<String, int> presentTurns,
  required Map<String, int> absentTurns,
}) {
  for (final gpId in activeThisTurn) {
    var offeredByOther = false;
    for (final entry in tradeOrdersByPlayerId.entries) {
      if (entry.key == gpId) continue;
      final offered = entry.value.any(
        (order) =>
            order.type == TradeOrderType.offer &&
            order.commodityId == commodityId,
      );
      if (offered) {
        offeredByOther = true;
        break;
      }
    }
    if (offeredByOther) {
      bumpCounter(presentTurns, gpId);
    } else {
      bumpCounter(absentTurns, gpId);
    }
  }
}

/// Records `fabric` market-offer presence/absence for the S7-D peasant-recruit
/// fabric localization (Refs #2847 § fabric offer-side split).
///
/// On each gp whose castIron-labour peasant-recruit fabric market path is
/// active this turn ([fabricMarketPathActiveThisTurn]), scans
/// [tradeOrdersByPlayerId] for any *other* faction emitting a `fabric` offer
/// and bumps [presentTurns] when one exists, else [absentTurns].
///
/// Complements [otherGreatPowerFabricHeld] (gross holdings) and
/// [otherGreatPowerOfferableFabricHeld] (planner-scope offerable proxy): a
/// positive holdings / offerable total with a flat-zero [presentTurns] across
/// the run localizes the closed market door to the **trade-order emission**
/// layer (holders retain `fabric` in stockpile but never emit a sell offer)
/// rather than to buyer-side bid/match. Read-only over the supplied maps except
/// the counter bumps; extracted to keep the diagnostic test file at or below
/// the repo non-comment line limit.
void recordSeed42S7dFabricMarketOfferCounters({
  required Set<String> fabricMarketPathActiveThisTurn,
  required Map<String, List<TradeOrder>> tradeOrdersByPlayerId,
  required Map<String, int> presentTurns,
  required Map<String, int> absentTurns,
}) => recordSeed42S7dOtherFactionOfferCounters(
  activeThisTurn: fabricMarketPathActiveThisTurn,
  tradeOrdersByPlayerId: tradeOrdersByPlayerId,
  commodityId: 'fabric',
  presentTurns: presentTurns,
  absentTurns: absentTurns,
);

/// True iff [playerId] owns at least one idle Builder for which the work-order
/// engine **accepts** a `build_improvement` on an owned unimproved feedstock
/// tile (a member of [feedstockIds]) — i.e. `getValidWorkOrderTileKeys` (the
/// same validator chain `suggestWorkOrders` runs) actually emits a candidate
/// the Full-AI civilian selection could route the Builder onto this turn.
///
/// This is the decisive split for the H8-extraction missing-candidate
/// hypothesis (Refs #2847): with an idle Builder present
/// (`gpFeedstockGateIdleBuilderPresentTurns` == gate-active turns) and an
/// unimproved feedstock tile owned (`gpUnimprovedFeedstockTileOwnedTurns` ==
/// 100) yet `gpFeedstockGateImprovedTileOwnedTurns` == 0, a near-zero count
/// here confirms the work-order validator suppresses the candidate before any
/// selection boost applies (the #3234 boost only biases a candidate that
/// exists); a high count would instead re-point the break downstream to the
/// selection / orchestrator / phase-filter stage. Read-only —
/// `getValidWorkOrderTileKeys` does not mutate game state.
void recordSeed42S7dCastIronLabourCounters({
  required Game game,
  required String gpId,
  required ({
    bool peasantRecruitGate,
    bool peasantRecruitAffordable,
    bool holdsFabricFeedstock,
    bool fabricRecipeFeasible,
    bool fabricRecipeLabourFeasible,
    bool castIronMaterialFeasible,
    bool castIronLabourFeasible,
    bool castIronLabourFoodStarved,
    bool castIronLabourPopulationBound,
    bool castIronOwnsFeedstockTile,
  })
  ci,
  required Set<String> fabricStarvedThisTurn,
  required Map<String, int> castIronLabourPeasantRecruitGateTurns,
  required Map<String, int> castIronLabourPeasantRecruitAffordableTurns,
  required Map<String, int> castIronLabourPeasantRecruitFabricStarvedTurns,
  required Map<String, int>
  castIronLabourPeasantRecruitMarketFabricStarvedTurns,
  required Map<String, int>
  castIronLabourPeasantRecruitMarketFabricUnofferedTurns,
  required Map<String, int> feedstockInStockpileTurns,
  required Map<String, int> fabricRecipeFeasibleTurns,
  required Map<String, int> fabricRecipeLabourFeasibleTurns,
  required Map<String, int> castIronRecipeFeasibleTurns,
  required Map<String, int> castIronRecipeLabourFeasibleTurns,
  required Map<String, int> castIronLabourFoodStarvedTurns,
  required Map<String, int> castIronLabourPopulationBoundTurns,
  required Map<String, int> castIronFeasibleOwnsFeedstockTileTurns,
}) {
  if (ci.peasantRecruitGate) {
    bumpCounter(castIronLabourPeasantRecruitGateTurns, gpId);
    if (ci.peasantRecruitAffordable) {
      bumpCounter(castIronLabourPeasantRecruitAffordableTurns, gpId);
    } else {
      bumpCounter(castIronLabourPeasantRecruitFabricStarvedTurns, gpId);
      fabricStarvedThisTurn.add(gpId);
      recordSeed42S7dPeasantRecruitFabricMarketSubCause(
        game: game,
        gpId: gpId,
        marketFabricStarvedTurns:
            castIronLabourPeasantRecruitMarketFabricStarvedTurns,
        marketFabricUnofferedTurns:
            castIronLabourPeasantRecruitMarketFabricUnofferedTurns,
      );
    }
  }
  if (ci.holdsFabricFeedstock) {
    bumpCounter(feedstockInStockpileTurns, gpId);
  }
  if (ci.fabricRecipeFeasible) {
    bumpCounter(fabricRecipeFeasibleTurns, gpId);
    if (ci.fabricRecipeLabourFeasible) {
      bumpCounter(fabricRecipeLabourFeasibleTurns, gpId);
    }
  }
  if (ci.castIronMaterialFeasible) {
    bumpCounter(castIronRecipeFeasibleTurns, gpId);
    // Split the material-feasible turns by the planner's labour gate and by the
    // staging gate's tile-ownership precondition.
    recordSeed42S7dCastIronLabourFork(
      gpId: gpId,
      castIronLabourFeasible: ci.castIronLabourFeasible,
      castIronLabourFoodStarved: ci.castIronLabourFoodStarved,
      castIronLabourPopulationBound: ci.castIronLabourPopulationBound,
      castIronRecipeLabourFeasibleTurns: castIronRecipeLabourFeasibleTurns,
      castIronLabourFoodStarvedTurns: castIronLabourFoodStarvedTurns,
      castIronLabourPopulationBoundTurns: castIronLabourPopulationBoundTurns,
    );
    if (ci.castIronOwnsFeedstockTile) {
      bumpCounter(castIronFeasibleOwnsFeedstockTileTurns, gpId);
    }
  }
}

/// Records the peasant-recruit fabric-starved market sub-cause split for [gpId]
/// (Refs #2847 § S7-D market-fabric localization).
///
/// Of the fabric-starved recruit turns, bumps [marketFabricStarvedTurns] when no
/// other great power holds any `fabric` to sell (the recruit `fabric` can be
/// neither produced nor bought), else bumps [marketFabricUnofferedTurns] when
/// holders exist but every one withholds its `fabric` via the regiment-rebuild
/// offer-retention carve-out (the market door is closed at the offer/retention
/// layer, not at holdings). Read-only over `game` except the counter bumps.
void recordSeed42S7dPeasantRecruitFabricMarketSubCause({
  required Game game,
  required String gpId,
  required Map<String, int> marketFabricStarvedTurns,
  required Map<String, int> marketFabricUnofferedTurns,
}) {
  if (otherGreatPowerFabricHeld(game, gpId) <= 0) {
    bumpCounter(marketFabricStarvedTurns, gpId);
    return;
  }
  if (otherGreatPowerOfferableFabricHeld(game, gpId) <= 0) {
    bumpCounter(marketFabricUnofferedTurns, gpId);
  }
}

/// Records the castIron material-feasible labour fork for [gpId] (Refs #2847
/// § S7-D).
///
/// On a material-feasible turn, bumps exactly one of the three labour-stage
/// counters following the planner's labour-gate precedence: labour-feasible,
/// else food-starved, else population-bound. A material-feasible turn that is
/// none of these (e.g. another labour gate) bumps no labour-stage counter.
void recordSeed42S7dCastIronLabourFork({
  required String gpId,
  required bool castIronLabourFeasible,
  required bool castIronLabourFoodStarved,
  required bool castIronLabourPopulationBound,
  required Map<String, int> castIronRecipeLabourFeasibleTurns,
  required Map<String, int> castIronLabourFoodStarvedTurns,
  required Map<String, int> castIronLabourPopulationBoundTurns,
}) {
  if (castIronLabourFeasible) {
    bumpCounter(castIronRecipeLabourFeasibleTurns, gpId);
    return;
  }
  if (castIronLabourFoodStarved) {
    bumpCounter(castIronLabourFoodStarvedTurns, gpId);
    return;
  }
  if (castIronLabourPopulationBound) {
    bumpCounter(castIronLabourPopulationBoundTurns, gpId);
  }
}
