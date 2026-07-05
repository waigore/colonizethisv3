part of 'naval_tree_builder.dart';

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
  })
  agg,
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
  final locationLabel =
      '${regionDisplayLabel(rowRegionId)} — $zoneLabel ${l10n.naval_units_locAtSea}';
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
  })
  agg,
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
      '${regionDisplayLabel(rowRegionId)} — ${province.displayName ?? province.id} ${l10n.naval_units_locInPort}';
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
