// Pure data for Naval Units panel tree. SPEC/ui/naval-units-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show GamePlayerLookup, homeFleetIdFor, regionIdForSeaZone, tryGetProvince;
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../../l10n/l10n.dart';
import '../units/shared/units_panel_region_label.dart';
import '../../utils/map_location_resolver.dart';
import '../../utils/sea_zone_name_resolver.dart';
import 'fleet_mission_label.dart';

String? navalDraftMoveLineForFleet({
  required Game game,
  required MapTopology topology,
  required String humanPlayerId,
  required String fleetRegionId,
  required String fleetId,
  required Orders draftOrders,
}) {
  final moves =
      draftOrders.navalMoveOrdersByPlayerId[humanPlayerId] ?? const [];
  for (final o in moves) {
    if (o.fleetId != fleetId) continue;
    if (o.isDock) {
      final pid = o.destinationPortProvinceId!;
      final p = tryGetProvince(game.worldState, pid);
      final name = p?.displayName ?? p?.id ?? pid;
      return 'Moving to: $name (dock)';
    }
    final z = o.destinationSeaZoneId!;
    final zReg = regionIdForSeaZone(topology, z) ?? fleetRegionId;
    final zoneKey = prefixedIdHasDelimiter(z) ? z : '$zReg|$z';
    final label = seaZoneDisplayName(
      game: game,
      regionId: zReg,
      seaZoneId: zoneKey,
    );
    return 'Moving to: $label';
  }
  return null;
}

class FleetRow {
  FleetRow({
    required this.fleetId,
    required this.label,
    required this.locationLabel,
    required this.regionId,
    required this.missionLabel,
    required this.totalShips,
    required this.warshipCount,
    required this.merchantCount,
    required this.strength,
    required this.tileKey,
    required this.isHomeFleet,
    required this.shipCountsByType,
    required this.cargoCapacity,
    required this.isAtSea,
    required this.locationKey,
    this.inPortAtProvinceId,
    this.seaZoneId,
    this.draftNavalMoveLine,
  });

  final String fleetId;
  final String label;
  final String locationLabel;
  final String regionId;
  final String missionLabel;
  final int totalShips;
  final int warshipCount;
  final int merchantCount;
  final double strength;
  final String? tileKey;
  final bool isHomeFleet;
  final Map<String, int> shipCountsByType;
  final int cargoCapacity;
  final bool isAtSea;
  final String locationKey;
  final String? inPortAtProvinceId;
  final String? seaZoneId;
  final String? draftNavalMoveLine;
}

abstract class NavalTreeLocationNode {
  String get displayLabel;
  String get regionId;
  List<FleetRow> get fleets;
}

class NavalTreePortNode extends NavalTreeLocationNode {
  NavalTreePortNode({required this.province, required this.fleets});

  final Province province;

  @override
  final List<FleetRow> fleets;

  @override
  String get displayLabel => province.displayName ?? province.id;

  @override
  String get regionId => province.regionId;
}

class NavalTreeSeaZoneNode extends NavalTreeLocationNode {
  NavalTreeSeaZoneNode({
    required this.seaZoneLabel,
    required this.regionId,
    required this.fleets,
  });

  final String seaZoneLabel;

  @override
  final String regionId;

  @override
  final List<FleetRow> fleets;

  @override
  String get displayLabel => seaZoneLabel;
}

List<FleetRow> flattenNavalTree(
  List<
    ({
      String regionId,
      FleetRow? homeFleet,
      List<NavalTreeLocationNode> locations,
    })
  >
  tree,
) {
  final rows = <FleetRow>[];
  for (final group in tree) {
    if (group.homeFleet != null) {
      rows.add(group.homeFleet!);
    }
    for (final loc in group.locations) {
      rows.addAll(loc.fleets);
    }
  }
  return rows;
}

({
  Map<String, int> shipCounts,
  int totalShips,
  int warships,
  int merchants,
  int cargoCapacity,
  double strength,
}) _navalFleetShipAggregates(Fleet fleet) {
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

({String? regionId, String? localId}) _capitalTileRegionParts(CapitalTile? tile) {
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

String _navalNormalizedPortScopeForProvince(Province province) {
  final localProvinceId = ProvinceId.isPrefixed(province.id)
      ? ProvinceId.localIdFrom(province.id)
      : province.id;
  return 'port:${province.regionId}|$localProvinceId';
}

String _navalResolveSeaZoneRegionId(
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

String _navalNormalizedSeaScope(
  MapTopology topology,
  String seaZoneId,
  String fallbackRegionId,
) {
  final regionId = _navalResolveSeaZoneRegionId(
    topology,
    seaZoneId,
    fallbackRegionId,
  );
  final local = prefixedIdLocalSegment(seaZoneId);
  return 'sea:$regionId|$local';
}

String? _navalRegionIdFromScopeKey(String? scopeKey) {
  if (scopeKey == null || scopeKey.isEmpty) return null;
  final colon = scopeKey.indexOf(':');
  if (colon == -1 || colon >= scopeKey.length - 1) return null;
  final payload = scopeKey.substring(colon + 1);
  return prefixedIdRegionSegment(payload);
}

String? _navalProjectedLocationScopeForFleet({
  required Game game,
  required MapTopology topology,
  required Fleet fleet,
  required Map<String, NavalMoveOrder> draftMoveByFleetId,
}) {
  final move = draftMoveByFleetId[fleet.id];
  if (move != null) {
    if (move.isDock) {
      final pid = move.destinationPortProvinceId!;
      final province = tryGetProvince(game.worldState, pid);
      if (province != null) {
        return _navalNormalizedPortScopeForProvince(province);
      }
      return 'port:$pid';
    }
    return _navalNormalizedSeaScope(
      topology,
      move.destinationSeaZoneId!,
      fleet.regionId,
    );
  }
  if (fleet.isAtSea && fleet.seaZoneId != null) {
    return _navalNormalizedSeaScope(
      topology,
      fleet.seaZoneId!,
      fleet.regionId,
    );
  }
  if (fleet.inPortAtProvinceId != null) {
    final province = tryGetProvince(
      game.worldState,
      fleet.inPortAtProvinceId!,
    );
    if (province != null) {
      return _navalNormalizedPortScopeForProvince(province);
    }
    return 'port:${fleet.inPortAtProvinceId!}';
  }
  return null;
}

void _appendNavalAtSeaFleetRow({
  required Game game,
  required MapTopology topology,
  required AppLocalizations l10n,
  required String humanPlayerId,
  required Orders draftOrders,
  required Fleet fleet,
  required String rowRegionId,
  required String? projectedScope,
  required String? locationScopeKeyFilter,
  required TileMapResult? rowTileMap,
  required MapTopology? rowTopology,
  required bool isHomeFleet,
  required ({
    int totalShips,
    int warships,
    int merchants,
    double strength,
    Map<String, int> shipCounts,
    int cargoCapacity,
  }) agg,
  required Map<String, List<FleetRow>> seas,
}) {
  final seaZoneId =
      locationScopeKeyFilter != null &&
          projectedScope != null &&
          projectedScope.startsWith('sea:')
      ? projectedScope.substring(4)
      : fleet.seaZoneId!;
  final zoneKey = prefixedIdHasDelimiter(seaZoneId)
      ? seaZoneId
      : '$rowRegionId|$seaZoneId';
  final locationKey = 'sea:$zoneKey';
  final zoneLabel = seaZoneDisplayName(
    game: game,
    regionId: rowRegionId,
    seaZoneId: zoneKey,
  );
  final locationLabel = '${unitsPanelRegionLabel(rowRegionId)} — $zoneLabel';
  final tileKey = tileKeyForNavalFleetAtSea(
    game: game,
    regionId: rowRegionId,
    seaZoneId: zoneKey,
    tileMap: rowTileMap,
    regionTopology: rowTopology,
  );
  final row = FleetRow(
    fleetId: fleet.id,
    label: l10n.naval_fleetLabel(fleet.id),
    locationLabel: locationLabel,
    regionId: rowRegionId,
    missionLabel: fleetMissionDisplayLabel(fleet.mission),
    totalShips: agg.totalShips,
    warshipCount: agg.warships,
    merchantCount: agg.merchants,
    strength: agg.strength,
    tileKey: tileKey,
    isHomeFleet: isHomeFleet,
    shipCountsByType: agg.shipCounts,
    cargoCapacity: agg.cargoCapacity,
    isAtSea: true,
    locationKey: locationKey,
    seaZoneId: zoneKey,
    draftNavalMoveLine: navalDraftMoveLineForFleet(
      game: game,
      topology: topology,
      humanPlayerId: humanPlayerId,
      fleetRegionId: rowRegionId,
      fleetId: fleet.id,
      draftOrders: draftOrders,
    ),
  );
  seas.putIfAbsent(zoneKey, () => []).add(row);
}

void _appendNavalInPortFleetRow({
  required Game game,
  required MapTopology topology,
  required AppLocalizations l10n,
  required String humanPlayerId,
  required Orders draftOrders,
  required Fleet fleet,
  required String inPortId,
  required String rowRegionId,
  required String? projectedScope,
  required String? locationScopeKeyFilter,
  required Map<String, Province> provinceMap,
  required bool isHomeFleet,
  required ({
    int totalShips,
    int warships,
    int merchants,
    double strength,
    Map<String, int> shipCounts,
    int cargoCapacity,
  }) agg,
  required Map<String, List<FleetRow>> ports,
  required List<FleetRow?> homeFleetSlot,
}) {
  final scopePortId =
      locationScopeKeyFilter != null &&
          projectedScope != null &&
          projectedScope.startsWith('port:')
      ? projectedScope.substring(5)
      : null;
  final effectivePortId = scopePortId ?? inPortId;
  final province =
      provinceMap['$rowRegionId|$effectivePortId'] ??
      provinceMap[effectivePortId];
  if (province == null) return;

  final locationKey = _navalNormalizedPortScopeForProvince(province);
  final tileKey = tileKeyForProvinceLocation(game, province);
  final locationLabel =
      '${unitsPanelRegionLabel(rowRegionId)} — ${province.displayName ?? province.id}';
  final row = FleetRow(
    fleetId: fleet.id,
    label: isHomeFleet
        ? l10n.naval_homeFleetLabel
        : l10n.naval_fleetLabel(fleet.id),
    locationLabel: locationLabel,
    regionId: rowRegionId,
    missionLabel: fleetMissionDisplayLabel(fleet.mission),
    totalShips: agg.totalShips,
    warshipCount: agg.warships,
    merchantCount: agg.merchants,
    strength: agg.strength,
    tileKey: tileKey,
    isHomeFleet: isHomeFleet,
    shipCountsByType: agg.shipCounts,
    cargoCapacity: agg.cargoCapacity,
    isAtSea: false,
    locationKey: locationKey,
    inPortAtProvinceId: effectivePortId,
    draftNavalMoveLine: isHomeFleet
        ? null
        : navalDraftMoveLineForFleet(
            game: game,
            topology: topology,
            humanPlayerId: humanPlayerId,
            fleetRegionId: rowRegionId,
            fleetId: fleet.id,
            draftOrders: draftOrders,
          ),
  );
  if (isHomeFleet) {
    homeFleetSlot[0] = row;
    return;
  }
  final fullProvinceId = '${province.regionId}|${province.id}';
  ports.putIfAbsent(fullProvinceId, () => []).add(row);
}

({
  String regionId,
  FleetRow? homeFleet,
  List<NavalTreeLocationNode> locations,
})? _navalTreeGroupForRegion({
  required Game game,
  required String humanPlayerId,
  required MapTopology topology,
  required Orders draftOrders,
  required AppLocalizations l10n,
  required Map<String, TileMapResult>? tileMapByRegion,
  required Map<String, MapTopology>? topologyByRegion,
  required String? locationScopeKeyFilter,
  required String regionId,
  required String? capitalRegionId,
  required String? capitalProvinceLocalId,
  required Map<String, Map<String, Province>> provinceByRegionAndId,
  required Map<String, NavalMoveOrder> draftMoveByFleetId,
}) {
  final fleetsInRegion = game.worldState.fleets
      .where(
        (f) =>
            f.ownerId == humanPlayerId &&
            (f.shipTypeIds.isNotEmpty || f.id == homeFleetIdFor(humanPlayerId)),
      )
      .where((fleet) {
        if (locationScopeKeyFilter == null) {
          return fleet.regionId == regionId;
        }
        final projectedScope = _navalProjectedLocationScopeForFleet(
          game: game,
          topology: topology,
          fleet: fleet,
          draftMoveByFleetId: draftMoveByFleetId,
        );
        if (projectedScope != locationScopeKeyFilter) {
          return false;
        }
        final scopeRegionId = _navalRegionIdFromScopeKey(projectedScope);
        return scopeRegionId == regionId;
      })
      .toList();
  if (fleetsInRegion.isEmpty && capitalRegionId != regionId) {
    return null;
  }

  final homeFleetSlot = <FleetRow?>[null];
  final ports = <String, List<FleetRow>>{};
  final seas = <String, List<FleetRow>>{};

  for (final fleet in fleetsInRegion) {
    final isAtSea = fleet.isAtSea && fleet.seaZoneId != null;
    final inPortId = fleet.inPortAtProvinceId;
    final projectedScope = _navalProjectedLocationScopeForFleet(
      game: game,
      topology: topology,
      fleet: fleet,
      draftMoveByFleetId: draftMoveByFleetId,
    );
    if (locationScopeKeyFilter != null &&
        projectedScope != locationScopeKeyFilter) {
      continue;
    }
    final projectedScopeRegionId = _navalRegionIdFromScopeKey(projectedScope);
    final rowRegionId = locationScopeKeyFilter != null
        ? (projectedScopeRegionId ?? regionId)
        : regionId;
    final rowTileMap = tileMapByRegion?[rowRegionId];
    final rowTopology = topologyByRegion?[rowRegionId];

    final agg = _navalFleetShipAggregates(fleet);

    final atPlayerCapitalPort =
        capitalRegionId != null &&
        capitalProvinceLocalId != null &&
        !isAtSea &&
        rowRegionId == capitalRegionId &&
        inPortId != null &&
        (inPortId == capitalProvinceLocalId ||
            inPortId == '$capitalRegionId|$capitalProvinceLocalId');
    final isHomeFleet =
        fleet.id == homeFleetIdFor(humanPlayerId) && atPlayerCapitalPort;

    if (isAtSea) {
      _appendNavalAtSeaFleetRow(
        game: game,
        topology: topology,
        l10n: l10n,
        humanPlayerId: humanPlayerId,
        draftOrders: draftOrders,
        fleet: fleet,
        rowRegionId: rowRegionId,
        projectedScope: projectedScope,
        locationScopeKeyFilter: locationScopeKeyFilter,
        rowTileMap: rowTileMap,
        rowTopology: rowTopology,
        isHomeFleet: isHomeFleet,
        agg: agg,
        seas: seas,
      );
    } else if (inPortId != null) {
      final provinceMap = provinceByRegionAndId[rowRegionId] ?? const {};
      _appendNavalInPortFleetRow(
        game: game,
        topology: topology,
        l10n: l10n,
        humanPlayerId: humanPlayerId,
        draftOrders: draftOrders,
        fleet: fleet,
        inPortId: inPortId,
        rowRegionId: rowRegionId,
        projectedScope: projectedScope,
        locationScopeKeyFilter: locationScopeKeyFilter,
        provinceMap: provinceMap,
        isHomeFleet: isHomeFleet,
        agg: agg,
        ports: ports,
        homeFleetSlot: homeFleetSlot,
      );
    }
  }

  final locations = <NavalTreeLocationNode>[];

  final provinceIds = ports.keys.toList()..sort();
  for (final fullProvinceId in provinceIds) {
    final provinceMap = provinceByRegionAndId[regionId] ?? const {};
    final province = provinceMap[fullProvinceId];
    if (province == null) continue;
    final fleets = ports[fullProvinceId]!
      ..sort((a, b) => a.label.compareTo(b.label));
    locations.add(NavalTreePortNode(province: province, fleets: fleets));
  }

  final seaZoneKeys = seas.keys.toList()..sort();
  for (final zoneKey in seaZoneKeys) {
    final zoneLabel = seaZoneDisplayName(
      game: game,
      regionId: regionId,
      seaZoneId: zoneKey,
    );
    final fleets = seas[zoneKey]!..sort((a, b) => a.label.compareTo(b.label));
    locations.add(
      NavalTreeSeaZoneNode(
        seaZoneLabel: zoneLabel,
        regionId: regionId,
        fleets: fleets,
      ),
    );
  }

  final homeFleetRow = homeFleetSlot[0];
  if (homeFleetRow == null && locations.isEmpty) {
    return null;
  }
  return (
    regionId: regionId,
    homeFleet: homeFleetRow,
    locations: locations,
  );
}

List<
  ({
    String regionId,
    FleetRow? homeFleet,
    List<NavalTreeLocationNode> locations,
  })
>
buildNavalTree(
  Game game,
  String humanPlayerId,
  MapTopology topology,
  Orders draftOrders,
  AppLocalizations l10n, {
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, MapTopology>? topologyByRegion,
  String? locationScopeKeyFilter,
}) {
  final player = game.playerById(humanPlayerId) ?? game.players.first;
  final capParts = _capitalTileRegionParts(player.capitalTile);
  final capitalRegionId = capParts.regionId;
  final capitalProvinceLocalId = capParts.localId;

  final result =
      <
        ({
          String regionId,
          FleetRow? homeFleet,
          List<NavalTreeLocationNode> locations,
        })
      >[];

  final provinceByRegionAndId = <String, Map<String, Province>>{
    'oldWorld': {
      for (final p in game.worldState.oldWorld.provinces)
        '${p.regionId}|${p.id}': p,
      for (final p in game.worldState.oldWorld.provinces) p.id: p,
    },
    'newWorld': {
      for (final p in game.worldState.newWorld.provinces)
        '${p.regionId}|${p.id}': p,
      for (final p in game.worldState.newWorld.provinces) p.id: p,
    },
  };

  final draftMoveByFleetId = <String, NavalMoveOrder>{
    for (final order
        in draftOrders.navalMoveOrdersByPlayerId[humanPlayerId] ?? const [])
      order.fleetId: order,
  };

  for (final regionEntry in {
    'oldWorld': game.worldState.oldWorld,
    'newWorld': game.worldState.newWorld,
  }.entries) {
    final regionId = regionEntry.key;
    final group = _navalTreeGroupForRegion(
      game: game,
      humanPlayerId: humanPlayerId,
      topology: topology,
      draftOrders: draftOrders,
      l10n: l10n,
      tileMapByRegion: tileMapByRegion,
      topologyByRegion: topologyByRegion,
      locationScopeKeyFilter: locationScopeKeyFilter,
      regionId: regionId,
      capitalRegionId: capitalRegionId,
      capitalProvinceLocalId: capitalProvinceLocalId,
      provinceByRegionAndId: provinceByRegionAndId,
      draftMoveByFleetId: draftMoveByFleetId,
    );
    if (group != null) {
      result.add(group);
    }
  }

  return result;
}
