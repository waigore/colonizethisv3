import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

// Fleet/sea-zone indexing and retreat-zone helpers for naval resolution
// (Refs #3290 Phase-0 file-split, #3416 part-of -> explicit library). This is a
// proper library imported by `naval_resolution.dart` and
// `naval_resolution_move.dart`; the shared symbols below are package-visible
// (no `_` prefix) so the sibling libraries can reference them. They remain
// unexported from the package barrel, so the public API is unchanged.

/// Outcome of a single naval-move order application. Returned by both the
/// dock and at-sea move handlers and consumed by [applyNavalMovesAndShipReveal]
/// to thread the mutating fleet/visibility state across each player's orders.
/// Refs #2560.
typedef NavalMoveOutcome = ({
  List<Fleet> fleets,
  Map<String, Fleet> fleetById,
  Map<String, int> fleetIndexById,
  Map<String, Map<String, String>> visibilityByTile,
});

/// Single-pass index: sea zone id → fleets whose [Fleet.seaZoneId] equals that
/// zone. Preserves world fleet list order within each bucket (Refs #2394).
Map<String, List<Fleet>> buildFleetsBySeaZoneId(List<Fleet> fleets) {
  final out = <String, List<Fleet>>{};
  for (final f in fleets) {
    final z = f.seaZoneId;
    if (z == null) continue;
    out.putIfAbsent(z, () => <Fleet>[]).add(f);
  }
  return out;
}

String? firstFriendlyOrNeutralRetreatZone(
  MapTopology topology,
  String fromSeaZoneId,
  String ownerId,
  Map<String, Set<String>> hostileByOwner,
  Map<String, List<Fleet>> fleetsBySeaZoneId,
) {
  for (final adj in nodesAdjacentTo(topology, fromSeaZoneId)) {
    var hostileOwnersPresent = false;
    for (final fleet in fleetsBySeaZoneId[adj] ?? const <Fleet>[]) {
      if (!fleet.isAtSea) continue;
      if (fleet.ownerId == ownerId) continue;
      if (hostileByOwner[ownerId]?.contains(fleet.ownerId) ?? false) {
        hostileOwnersPresent = true;
        break;
      }
    }
    if (!hostileOwnersPresent) return adj;
  }
  return null;
}

Map<String, int> buildFleetIndexById(List<Fleet> fleets) => {
  for (var i = 0; i < fleets.length; i++) fleets[i].id: i,
};
