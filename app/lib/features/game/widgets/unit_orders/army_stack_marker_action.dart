/// Resolves MAP10001 army-stack marker tap routing. Refs #4384, #4407.
enum ArmyStackMarkerKind {
  observeBlocked,
  openMilitaryRoster,
  overlayMove,
  detachThenMove,
}

({ArmyStackMarkerKind kind, List<String> moveArmyIds})
resolveArmyStackMarkerAction({
  required bool canMutateViaUi,
  required List<String> fieldArmyIds,

  /// True only when this marker's `armyIds` include a non-empty Home Army.
  bool stackHasNonEmptyHomeArmy = false,
  List<String> fieldArmyIdsWithDestinations = const <String>[],
}) {
  if (!canMutateViaUi) {
    return (
      kind: ArmyStackMarkerKind.observeBlocked,
      moveArmyIds: const <String>[],
    );
  }
  if (fieldArmyIdsWithDestinations.isNotEmpty) {
    return (
      kind: ArmyStackMarkerKind.overlayMove,
      moveArmyIds: fieldArmyIdsWithDestinations,
    );
  }
  if (stackHasNonEmptyHomeArmy) {
    return (
      kind: ArmyStackMarkerKind.detachThenMove,
      moveArmyIds: const <String>[],
    );
  }
  if (fieldArmyIds.isEmpty) {
    return (
      kind: ArmyStackMarkerKind.openMilitaryRoster,
      moveArmyIds: const <String>[],
    );
  }
  return (kind: ArmyStackMarkerKind.overlayMove, moveArmyIds: fieldArmyIds);
}
