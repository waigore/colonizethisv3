import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart'
    show fleetsInPortAtProvince, homeFleetIdFor, kRegionOldWorld;

/// Visibility/enablement for MAP20001 Naval Combine (Refs #4659).
class ProvinceNavalCombineActionState {
  const ProvinceNavalCombineActionState({
    required this.show,
    required this.enabled,
    required this.hasPendingOrder,
    required this.fleetIds,
  });

  static const hidden = ProvinceNavalCombineActionState(
    show: false,
    enabled: false,
    hasPendingOrder: false,
    fleetIds: <String>[],
  );

  final bool show;
  final bool enabled;
  final bool hasPendingOrder;
  final List<String> fleetIds;
}

/// Prefer-order for overlay survivor / confirm list: Home first, then ascending id.
List<Fleet> overlayNavalCombinePreferOrder(List<Fleet> fleets, String humanPlayerId) {
  final homeId = homeFleetIdFor(humanPlayerId);
  final sorted = [...fleets]..sort((a, b) {
    if (a.id == homeId) return -1;
    if (b.id == homeId) return 1;
    return a.id.compareTo(b.id);
  });
  return sorted;
}

/// Human-owned fleets sharing the overlay locality (port province or sea zone).
List<Fleet> humanFleetsInOverlayNavalLocality({
  required Game game,
  required String humanPlayerId,
  required String displayId,
  required bool isSeaZoneContext,
}) {
  if (isSeaZoneContext) {
    final regionId = displayId.contains('|')
        ? displayId.split('|').first
        : kRegionOldWorld;
    final localSea = displayId.contains('|')
        ? displayId.split('|').last
        : displayId;
    final out = <Fleet>[
      for (final f in game.worldState.fleets)
        if (f.ownerId == humanPlayerId &&
            f.inPortAtProvinceId == null &&
            f.regionId == regionId &&
            f.seaZoneId == localSea)
          f,
    ];
    return overlayNavalCombinePreferOrder(out, humanPlayerId);
  }
  final inPort = fleetsInPortAtProvince(game.worldState, displayId);
  final out = <Fleet>[
    for (final f in inPort)
      if (f.ownerId == humanPlayerId) f,
  ];
  return overlayNavalCombinePreferOrder(out, humanPlayerId);
}

bool fleetSetHasPendingNavalOrder({
  required Orders draftOrders,
  required String humanPlayerId,
  required List<Fleet> fleets,
}) {
  if (fleets.isEmpty) return false;
  final ids = {for (final f in fleets) f.id};
  for (final o
      in draftOrders.navalMoveOrdersByPlayerId[humanPlayerId] ?? const []) {
    if (ids.contains(o.fleetId)) return true;
  }
  for (final o
      in draftOrders.navalMissionOrdersByPlayerId[humanPlayerId] ?? const []) {
    if (ids.contains(o.fleetId)) return true;
  }
  return false;
}

ProvinceNavalCombineActionState computeProvinceNavalCombineActionState({
  required Game game,
  required String humanPlayerId,
  required String displayId,
  required Orders draftOrders,
  required bool showsFullNavalIntel,
  required bool isSeaZoneContext,
  required bool canMutateViaUi,
}) {
  if (!canMutateViaUi || !showsFullNavalIntel) {
    return ProvinceNavalCombineActionState.hidden;
  }
  final fleets = humanFleetsInOverlayNavalLocality(
    game: game,
    humanPlayerId: humanPlayerId,
    displayId: displayId,
    isSeaZoneContext: isSeaZoneContext,
  );
  if (fleets.length < 2) {
    return ProvinceNavalCombineActionState.hidden;
  }
  final ids = [for (final f in fleets) f.id];
  final pending = fleetSetHasPendingNavalOrder(
    draftOrders: draftOrders,
    humanPlayerId: humanPlayerId,
    fleets: fleets,
  );
  return ProvinceNavalCombineActionState(
    show: true,
    enabled: !pending,
    hasPendingOrder: pending,
    fleetIds: ids,
  );
}
