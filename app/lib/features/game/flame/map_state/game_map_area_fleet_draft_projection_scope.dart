part of 'game_map_area_fleet_draft_projection.dart';

/// Sea-zone and port location scope keys for fleet draft projection.
abstract final class GameMapAreaFleetDraftProjectionScope {
  static String seaZoneLocalId(String seaZoneId) =>
      prefixedIdLocalSegment(seaZoneId);

  static String destinationRegionForSeaZone({
    required String seaZoneId,
    required String fallbackRegionId,
    required MapTopology combinedTopology,
    required Map<String, MapTopology> topologyByRegion,
  }) {
    final fromCombined = regionIdForSeaZone(combinedTopology, seaZoneId);
    if (fromCombined != null) {
      return fromCombined;
    }
    final localSeaZoneId = seaZoneLocalId(seaZoneId);
    for (final entry in topologyByRegion.entries) {
      final hasZone = entry.value.nodes.any(
        (n) => n.type == TopologyNodeType.seaZone && n.id == localSeaZoneId,
      );
      if (hasZone) {
        return entry.key;
      }
    }
    return fallbackRegionId;
  }

  static String normalizedSeaScope({
    required String seaZoneId,
    required String fallbackRegionId,
    required MapTopology combinedTopology,
    required Map<String, MapTopology> topologyByRegion,
  }) {
    final regionId = destinationRegionForSeaZone(
      seaZoneId: seaZoneId,
      fallbackRegionId: fallbackRegionId,
      combinedTopology: combinedTopology,
      topologyByRegion: topologyByRegion,
    );
    final local = seaZoneLocalId(seaZoneId);
    return 'sea:$regionId|$local';
  }

  static String locationScopeForMove({
    required ct_models.NavalMoveOrder move,
    required String fleetRegionId,
    required ct_models.Game game,
    required MapTopology combinedTopology,
    required Map<String, MapTopology> topologyByRegion,
  }) {
    if (move.isDock) {
      final pid = move.destinationPortProvinceId!;
      final p = game.worldState.tryGetProvince(pid);
      if (p != null) {
        final localProvinceId = ct_models.ProvinceId.localIdFrom(p.id);
        return 'port:${p.regionId}|$localProvinceId';
      }
      return 'port:$pid';
    }
    return normalizedSeaScope(
      seaZoneId: move.destinationSeaZoneId!,
      fallbackRegionId: fleetRegionId,
      combinedTopology: combinedTopology,
      topologyByRegion: topologyByRegion,
    );
  }

  static String? currentLocationScopeForFleet({
    required ct_models.Fleet fleet,
    required ct_models.Game game,
    required MapTopology combinedTopology,
    required Map<String, MapTopology> topologyByRegion,
  }) {
    if (fleet.isAtSea && fleet.seaZoneId != null) {
      return normalizedSeaScope(
        seaZoneId: fleet.seaZoneId!,
        fallbackRegionId: fleet.regionId,
        combinedTopology: combinedTopology,
        topologyByRegion: topologyByRegion,
      );
    }
    if (fleet.inPortAtProvinceId != null) {
      final p = game.worldState.tryGetProvince(fleet.inPortAtProvinceId!);
      if (p != null) {
        final localProvinceId = ct_models.ProvinceId.localIdFrom(p.id);
        return 'port:${p.regionId}|$localProvinceId';
      }
      return 'port:${fleet.inPortAtProvinceId!}';
    }
    return null;
  }
}
