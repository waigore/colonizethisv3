part of 'naval_resolution.dart';

// Fleet/sea-zone indexing and retreat-zone helpers for naval resolution
// (Refs #3290 Phase-0 file-split). Behaviour-preserving move: same library
// scope as `naval_resolution.dart`, so imports, shared helpers, and visibility
// are unchanged.

/// Single-pass index: sea zone id → fleets whose [Fleet.seaZoneId] equals that
/// zone. Preserves world fleet list order within each bucket (Refs #2394).
Map<String, List<Fleet>> _fleetsBySeaZoneId(List<Fleet> fleets) {
  final out = <String, List<Fleet>>{};
  for (final f in fleets) {
    final z = f.seaZoneId;
    if (z == null) continue;
    out.putIfAbsent(z, () => <Fleet>[]).add(f);
  }
  return out;
}

String? _firstFriendlyOrNeutralRetreatZone(
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

Map<String, int> _fleetIndexById(List<Fleet> fleets) => {
  for (var i = 0; i < fleets.length; i++) fleets[i].id: i,
};
