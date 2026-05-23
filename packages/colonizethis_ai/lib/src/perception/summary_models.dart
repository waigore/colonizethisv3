import 'package:colonizethis_data/colonizethis_data.dart';

/// Summary of threats (e.g. hostile neighbors, weak borders).
class ThreatSummary {
  const ThreatSummary({
    this.atWarWith = const [],
    this.neighborProvincesHostile = 0,
    this.capitalThreatened = false,
  });

  final List<String> atWarWith;
  final int neighborProvincesHostile;
  final bool capitalThreatened;
}

/// Summary of opportunities (e.g. weak targets, rich provinces).
class OpportunitySummary {
  const OpportunitySummary({
    this.weakNeighbors = const [],
    this.richUnexploitedProvinces = 0,
    this.unclaimedProvinces = 0,
  });

  final List<String> weakNeighbors;
  final int richUnexploitedProvinces;
  final int unclaimedProvinces;
}

/// Victory-pace and invasion targets from PlayerView. SPEC/ai/ai-architecture.md.
class ConquestSummary {
  const ConquestSummary({
    this.oldWorldProvincesOwned = 0,
    this.provincesToVictory = kMilitaryVictoryOldWorldProvinceThreshold,
    this.invadableProvinceIdsSorted = const [],
    this.preferredConquestTargetFactionIdsSorted = const [],
    this.adjacentOwnerFactionIdsSorted = const [],
  });

  final int oldWorldProvincesOwned;
  final int provincesToVictory;
  final List<String> invadableProvinceIdsSorted;
  final List<String> preferredConquestTargetFactionIdsSorted;

  /// Faction ids owning Old World provinces adjacent to owned territory (topology).
  final List<String> adjacentOwnerFactionIdsSorted;
}

/// New World colonial pace from PlayerView. SPEC/ai/ai-architecture.md § Colonial expansion.
class ColonialSummary {
  const ColonialSummary({
    this.newWorldProvincesOwned = 0,
    this.invadableNewWorldProvinceIdsSorted = const [],
    this.invadableNewWorldProvinceIdsByDistance = const [],
    this.adjacentNewWorldOwnerFactionIdsSorted = const [],
    this.preferredColonialTargetFactionIdsSorted = const [],
  });

  final int newWorldProvincesOwned;

  /// NW invadable province ids, sorted **ascending by province id** (lex).
  /// Used by the bulk-NW planners ([planColonialMilitary],
  /// [planColonialNaval], [planColonialLiteNaval], COLONIAL-lite) where
  /// the ordering only affects deterministic iteration and not target
  /// selection. Always populated when a [MapTopology] is available.
  final List<String> invadableNewWorldProvinceIdsSorted;

  /// NW invadable province ids, sorted by **ascending BFS topology
  /// distance** to the nearest owned anchor, then ascending province
  /// id as a deterministic tiebreaker for equal-distance candidates.
  ///
  /// Refs #2509 § COLONIAL phase planner § planColonialAcquisition --
  /// "For each unowned-visible newWorld| province (sorted by adjacency
  /// distance to owned territory)". Distance is measured as edges in
  /// the topology graph: an NW province sharing a direct
  /// province-province border with an owned anchor has distance 1,
  /// and an NW province reached via the canonical
  /// owned-anchor -> OW sea -> NW sea -> NW colony path has distance 3.
  ///
  /// Empty when the snapshot is built without a [MapTopology] (the
  /// adjacency-distance key cannot be derived without topology
  /// edges). Consumers must fall back to
  /// [invadableNewWorldProvinceIdsSorted] when this list is empty
  /// (`planColonialAcquisition` does so today; sibling COLONIAL
  /// planners stay on the lex-sorted field because tie-break order
  /// does not affect their plan outputs).
  final List<String> invadableNewWorldProvinceIdsByDistance;

  final List<String> adjacentNewWorldOwnerFactionIdsSorted;
  final List<String> preferredColonialTargetFactionIdsSorted;
}

/// Economy summary from view (stockpile, workers, treasury).
class EconomySummary {
  const EconomySummary({
    this.workerCount = 0,
    this.treasury = 0,
    this.ownProvinceCount = 0,
  });

  final int workerCount;
  final int treasury;
  final int ownProvinceCount;
}
