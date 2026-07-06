part of 'naval_tree_builder.dart';

({String regionId, FleetRow? homeFleet, List<NavalTreeLocationNode> locations})?
_navalTreeGroupForRegion({
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
  return (regionId: regionId, homeFleet: homeFleetRow, locations: locations);
}
