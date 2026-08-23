/// Scratch sets/maps shared between the GP loop and merged-order reconciliation.
class Seed42S7dBeforeResolveTurnScratch {
  final Set<String> fabricStarvedThisTurn = <String>{};
  final Set<String> fabricMarketPathActiveThisTurn = <String>{};
  final Set<String> feedstockGateActiveThisTurn = <String>{};
  final Map<String, bool> turnRebuildReady = <String, bool>{};
  final Map<String, bool> turnInputsPresent = <String, bool>{};
}
