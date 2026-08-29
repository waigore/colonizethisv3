// S7-D lock-recovery diagnostic structural invariants (Refs #2847 / #3941 / #4079 Slice D).
// Split from the former monolithic lock_recovery_probes.dart.

import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart'
    show ObserverGoalPhase;
import 'package:colonizethis_test/test.dart';

import 'lock_recovery_invariants_peasant_recruit.dart';

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
    assertSeed42S7dPeasantRecruitStructuralInvariants(
      gpId: gpId,
      feedstockExtractionGateActiveTurns: feedstockExtractionGateActiveTurns,
      castIronLabourPeasantRecruitGateTurns: castIronLabourPeasantRecruitGateTurns,
      castIronLabourPeasantRecruitAffordableTurns:
          castIronLabourPeasantRecruitAffordableTurns,
      castIronLabourPeasantRecruitFabricStarvedTurns:
          castIronLabourPeasantRecruitFabricStarvedTurns,
      castIronLabourPeasantRecruitMarketFabricStarvedTurns:
          castIronLabourPeasantRecruitMarketFabricStarvedTurns,
      castIronLabourPeasantRecruitMarketFabricUnofferedTurns:
          castIronLabourPeasantRecruitMarketFabricUnofferedTurns,
      castIronLabourPeasantRecruitFabricBidEmittedTurns:
          castIronLabourPeasantRecruitFabricBidEmittedTurns,
      castIronLabourPeasantRecruitFabricBidAbsentTurns:
          castIronLabourPeasantRecruitFabricBidAbsentTurns,
      castIronLabourPeasantRecruitFabricDealAsBuyerTurns:
          castIronLabourPeasantRecruitFabricDealAsBuyerTurns,
      fabricRecipeFeasibleTurns: fabricRecipeFeasibleTurns,
      fabricRecipeLabourFeasibleTurns: fabricRecipeLabourFeasibleTurns,
      castIronMarketOfferPresentTurns: castIronMarketOfferPresentTurns,
      castIronMarketOfferAbsentTurns: castIronMarketOfferAbsentTurns,
      castIronFeedstockExtractionLabourFutileTurns:
          castIronFeedstockExtractionLabourFutileTurns,
    );
  }
}
