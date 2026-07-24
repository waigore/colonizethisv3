import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show regionIdForSeaZone, WorldStateProvinceLookup;
import 'package:colonizethis_models/colonizethis_models.dart';

({
  Map<String, int> shipCounts,
  int totalShips,
  int warships,
  int merchants,
  int cargoCapacity,
  double strength,
})
navalTreeFleetShipAggregates(Fleet fleet) {
  final shipCounts = <String, int>{};
  var totalShips = 0;
  var warships = 0;
  var merchants = 0;
  var cargoCapacity = 0;
  var strength = 0.0;
  for (final typeId in fleet.shipTypeIds) {
    shipCounts[typeId] = (shipCounts[typeId] ?? 0) + 1;
    totalShips += 1;
    final stats = NavalStatsCatalog.get(typeId);
    cargoCapacity += stats.cargoHold;
    strength += NavalStatsCatalog.shipStrength(typeId);
    if (stats.cargoHold > 0) {
      merchants += 1;
    } else {
      warships += 1;
    }
  }
  return (
    shipCounts: shipCounts,
    totalShips: totalShips,
    warships: warships,
    merchants: merchants,
    cargoCapacity: cargoCapacity,
    strength: strength,
  );
}

({String? regionId, String? localId}) navalTreeCapitalTileRegionParts(
  CapitalTile? tile,
) {
  if (tile == null) return (regionId: null, localId: null);
  final tileKey = tile.toTileKey();
  final parsed = tryParseTileKey(tileKey);
  if (parsed != null) {
    return (regionId: parsed.regionId, localId: parsed.provinceLocalId);
  }
  final regionPart = prefixedIdRegionSegment(tileKey);
  if (regionPart == null) return (regionId: null, localId: null);
  final localTail = prefixedIdLocalSegment(tileKey);
  final i = localTail.indexOf('|');
  final localProv = i < 0 ? localTail : localTail.substring(0, i);
  return (regionId: regionPart, localId: localProv);
}

String navalTreeNormalizedPortScopeForProvince(Province province) {
  final localProvinceId = ProvinceId.isPrefixed(province.id)
      ? ProvinceId.localIdFrom(province.id)
      : province.id;
  return 'port:${province.regionId}|$localProvinceId';
}

String navalTreeResolveSeaZoneRegionId(
  MapTopology topology,
  String seaZoneId,
  String fallbackRegionId,
) {
  final byTopology = regionIdForSeaZone(topology, seaZoneId);
  if (byTopology != null) return byTopology;
  final localSeaZoneId = prefixedIdLocalSegment(seaZoneId);
  for (final node in topology.nodes) {
    if (node.type != TopologyNodeType.seaZone) continue;
    final nodeLocal = prefixedIdLocalSegment(node.id);
    if (nodeLocal == localSeaZoneId) {
      return node.regionId;
    }
  }
  return fallbackRegionId;
}

String navalTreeNormalizedSeaScope(
  MapTopology topology,
  String seaZoneId,
  String fallbackRegionId,
) {
  final regionId = navalTreeResolveSeaZoneRegionId(
    topology,
    seaZoneId,
    fallbackRegionId,
  );
  final local = prefixedIdLocalSegment(seaZoneId);
  return 'sea:$regionId|$local';
}

String? navalTreeRegionIdFromScopeKey(String? scopeKey) {
  if (scopeKey == null || scopeKey.isEmpty) return null;
  final colon = scopeKey.indexOf(':');
  if (colon == -1 || colon >= scopeKey.length - 1) return null;
  final payload = scopeKey.substring(colon + 1);
  return prefixedIdRegionSegment(payload);
}

String? navalTreeProjectedLocationScopeForFleet({
  required Game game,
  required MapTopology topology,
  required Fleet fleet,
  required Map<String, NavalMoveOrder> draftMoveByFleetId,
}) {
  final move = draftMoveByFleetId[fleet.id];
  if (move != null) {
    if (move.isDock) {
      final pid = move.destinationPortProvinceId!;
      final province = game.worldState.tryGetProvince(pid);
      if (province != null) {
        return navalTreeNormalizedPortScopeForProvince(province);
      }
      return 'port:$pid';
    }
    return navalTreeNormalizedSeaScope(
      topology,
      move.destinationSeaZoneId!,
      fleet.regionId,
    );
  }
  if (fleet.isAtSea && fleet.seaZoneId != null) {
    return navalTreeNormalizedSeaScope(topology, fleet.seaZoneId!, fleet.regionId);
  }
  if (fleet.inPortAtProvinceId != null) {
    final province = game.worldState.tryGetProvince(fleet.inPortAtProvinceId!);
    if (province != null) {
      return navalTreeNormalizedPortScopeForProvince(province);
    }
    return 'port:${fleet.inPortAtProvinceId!}';
  }
  return null;
}
