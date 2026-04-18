/// One ship in a [Fleet]: stable unique [id] and catalog [typeId].
/// SPEC/game/ships-and-naval.md, SPEC/game/world-model.md.
class ShipInstance {
  const ShipInstance({required this.id, required this.typeId});

  /// Unique within the game save (and across fleets). Not a display name.
  final String id;

  /// Naval catalog id (e.g. `carrack`). SPEC/game/ships-and-naval.md.
  final String typeId;

  Map<String, dynamic> toJson() => {'id': id, 'typeId': typeId};

  static ShipInstance fromJson(Map<String, dynamic> json) {
    return ShipInstance(
      id: json['id'] as String,
      typeId: json['typeId'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShipInstance &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          typeId == other.typeId;

  @override
  int get hashCode => Object.hash(id, typeId);
}

/// Deterministic ids for legacy saves that only stored repeated type strings.
/// Format: `legacy|fleetId|index|typeId` (typeId must not contain `|`).
List<ShipInstance> legacyShipInstancesForFleet(
  String fleetId,
  List<String> typeIds,
) {
  return [
    for (var i = 0; i < typeIds.length; i++)
      ShipInstance(
        id: 'legacy|$fleetId|$i|${typeIds[i]}',
        typeId: typeIds[i],
      ),
  ];
}

/// Picks the first matching instances in [fromFleet] order for [countsByTypeToMove].
List<ShipInstance> shipInstancesForTransferCounts(
  List<ShipInstance> fromFleet,
  Map<String, int> countsByTypeToMove,
) {
  final need = Map<String, int>.from(countsByTypeToMove);
  final out = <ShipInstance>[];
  for (final s in fromFleet) {
    final left = need[s.typeId] ?? 0;
    if (left > 0) {
      out.add(s);
      need[s.typeId] = left - 1;
    }
  }
  return out;
}
