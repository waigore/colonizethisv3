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
    this.adjacentNewWorldOwnerFactionIdsSorted = const [],
    this.preferredColonialTargetFactionIdsSorted = const [],
  });

  final int newWorldProvincesOwned;
  final List<String> invadableNewWorldProvinceIdsSorted;
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
