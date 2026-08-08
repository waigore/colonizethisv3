import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'expand_phase_planner.dart';

/// Signature shared by every EXPAND-regime Great Power peace decider composed
/// by the ordered registries below (Refs #3749 step 5 — expand-peace decider
/// registry).
typedef ExpandPeaceDecider =
    Iterable<String> Function({
      required Game game,
      required AIWorldSnapshot snapshot,
    });

/// Adapts a `String?` single-target peace decider result to the
/// [ExpandPeaceDecider] `Iterable<String>` shape.
Iterable<String> singleTargetOrEmpty(String? target) =>
    target == null ? const <String>[] : <String>[target];

/// [ExpandPeaceDecider] wrapper for [stalledStrongerGpBlockerPeaceTarget].
Iterable<String> stalledStrongerGpBlockerPeaceDecider({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => singleTargetOrEmpty(
  stalledStrongerGpBlockerPeaceTarget(game: game, snapshot: snapshot),
);

/// [ExpandPeaceDecider] wrapper for [unwinnableSoleGpFrontierPeaceTarget].
Iterable<String> unwinnableSoleGpFrontierPeaceDecider({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => singleTargetOrEmpty(
  unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
);

/// [ExpandPeaceDecider] wrapper for [consolidateGainsSoleGpPeaceTarget].
Iterable<String> consolidateGainsSoleGpPeaceDecider({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => singleTargetOrEmpty(
  consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot),
);

/// Ordered survival / zero-regiment / mutual-exhausted peace deciders consumed
/// by [survivalGreatPowerPeaceTargets] (Refs #3749 step 5).
const List<ExpandPeaceDecider> kSurvivalGreatPowerPeaceDeciders =
    <ExpandPeaceDecider>[
      criticalWeakGpSurvivalPeaceTargets,
      stalledZeroRegimentAllFactionPeaceTargets,
      mutualZeroRegimentGpStalematePeaceTargets,
      stalledZeroRegimentGpPeaceTargets,
      mutualExhaustedBelowQuotaGpStalematePeaceTargets,
    ];

/// Ordered EXPAND-regime ratchet peace deciders consumed by
/// [expandRatchetGreatPowerPeaceTargets] (Refs #3749 step 5).
const List<ExpandPeaceDecider> kExpandRatchetGreatPowerPeaceDeciders =
    <ExpandPeaceDecider>[
      stalledFutileGpPeaceTargets,
      stalledGpBlockerFocusPeaceTargets,
      stalledExpansionDistractionPeaceTargets,
      multiFrontNonBlockerGpPeaceTargets,
      criticalMultiFrontGpPeaceTargets,
      weakHoldingsInvadableBlockerPeaceTargets,
      stalledStrongerGpBlockerPeaceDecider,
      criticalOwHoldPeaceTargets,
      stalledBelowQuotaGpLeadPeaceTargets,
      belowQuotaPeerGpPeaceTargets,
      defaultStartGpPeaceTargets,
      defaultStartFutileMinorPeaceTargets,
      nearQuotaHoldPeaceTargets,
      quotaMetBelowQuotaAtWarPeaceTargets,
      quotaMetFutileBelowQuotaGpPeaceTargets,
      unwinnableSoleGpFrontierPeaceDecider,
      consolidateGainsSoleGpPeaceDecider,
    ];

/// Critical-collapse / zero-regiment peace aggregator for all observer phases.
Iterable<String> survivalGreatPowerPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) sync* {
  for (final decider in kSurvivalGreatPowerPeaceDeciders) {
    yield* decider(game: game, snapshot: snapshot);
  }
}

/// Legacy OW-expansion scoring ratchet peace aggregator (EXPAND / COLONIAL-lite only).
Iterable<String> expandRatchetGreatPowerPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) sync* {
  for (final decider in kExpandRatchetGreatPowerPeaceDeciders) {
    yield* decider(game: game, snapshot: snapshot);
  }
}
