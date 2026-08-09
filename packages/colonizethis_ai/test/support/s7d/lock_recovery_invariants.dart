// S7-D lock-recovery diagnostic structural invariants (Refs #2847 / #3941 / #4079 Slice D).
// Split from the former monolithic lock_recovery_probes.dart.

import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart'
    show ObserverGoalPhase;
import 'package:colonizethis_test/test.dart';

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

