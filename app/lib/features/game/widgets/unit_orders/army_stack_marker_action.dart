/// Resolves MAP10001 army-stack marker tap routing. Refs #4384.
enum ArmyStackMarkerKind { observeBlocked, openMilitaryRoster, overlayMove }

({ArmyStackMarkerKind kind, List<String> moveArmyIds})
resolveArmyStackMarkerAction({
  required bool canMutateViaUi,
  required List<String> fieldArmyIds,
}) {
  if (!canMutateViaUi) {
    return (
      kind: ArmyStackMarkerKind.observeBlocked,
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
