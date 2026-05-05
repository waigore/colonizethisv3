// Fleet tile marker helpers for [init_game_map_view_builder.dart].

part of 'init_game_map_view_builder.dart';

String _homeFleetIdForMapMarker(String playerId) => 'fleet_$playerId';

bool _fleetAtHumanCapital(Game game, String playerId, Fleet fleet) {
  if (!fleet.isInPort || fleet.inPortAtProvinceId == null) {
    return false;
  }
  final player = game.players.firstWhere(
    (p) => p.id == playerId,
    orElse: () => game.players.first,
  );
  if (!player.isHuman) {
    return false;
  }
  final cap = player.capitalTile;
  if (cap == null) {
    return false;
  }
  final parsed = tryParseMapTileKey(cap.toTileKey());
  if (parsed == null) {
    return false;
  }
  final capReg = parsed.regionId;
  final capProvLocal = parsed.localId;
  if (fleet.regionId != capReg) {
    return false;
  }
  final port = fleet.inPortAtProvinceId!;
  return port == capProvLocal || port == '$capReg|$capProvLocal';
}

bool _includeFleetForTileMarker(
  Game game,
  Fleet f,
  String regionId,
  Set<String> humanIds,
) {
  if (!humanIds.contains(f.ownerId) || f.regionId != regionId) {
    return false;
  }
  if (f.shipTypeIds.isNotEmpty) {
    return true;
  }
  return f.id == _homeFleetIdForMapMarker(f.ownerId) &&
      _fleetAtHumanCapital(game, f.ownerId, f);
}

String? _inPortFleetMarkerTileKey({
  required Game game,
  required String regionId,
  required Province province,
  required TileMapResult tileMap,
  required Set<String> seaZoneIds,
}) {
  final localProvinceId = ProvinceId.localIdFrom(province.id);
  final tileKey = harborDrawableSeaTileKeyForPortProvince(
    game: game,
    regionId: regionId,
    localProvinceId: localProvinceId,
    tileMap: tileMap,
    seaZoneIds: seaZoneIds,
    contextLabel: 'fleet marker region=$regionId province=$localProvinceId',
  );
  if (tileKey == null) {
    _log.w(
      'map: in-port fleet marker skipped: no portsByProvinceSeaboard entry '
      'for region=$regionId province=$localProvinceId',
    );
  }
  return tileKey;
}

(int?, int?) _xyFromMapTileKey(String tileKey) {
  final parsed = tryParseMapTileKeySuffixXY(tileKey);
  if (parsed == null) {
    return (null, null);
  }
  return (parsed.x, parsed.y);
}

String? _fleetMarkerTileKeyForLocationScope({
  required String scopeKey,
  required String regionId,
  required Game game,
  required TileMapResult tileMap,
  required Set<String> seaZoneIds,
  required Map<String, Province> provinceMap,
}) {
  if (scopeKey.startsWith('sea:')) {
    final zoneKey = scopeKey.substring(4);
    final local = mapPipeLastSegmentOrWhole(zoneKey);
    return seaZoneCentroidTileKey(
      tileMap: tileMap,
      regionId: regionId,
      localSeaZoneId: local,
      seaZoneNodeIds: seaZoneIds,
    );
  }
  if (!scopeKey.startsWith('port:')) return null;
  final fullProv = scopeKey.substring(5);
  final province = provinceMap[fullProv];
  if (province == null) return null;
  return _inPortFleetMarkerTileKey(
    game: game,
    regionId: regionId,
    province: province,
    tileMap: tileMap,
    seaZoneIds: seaZoneIds,
  );
}

void _addFleetToLocationBuckets({
  required Fleet f,
  required String regionId,
  required Map<String, Province> provinceMap,
  required Map<String, List<Fleet>> byLocation,
}) {
  if (f.isAtSea && f.seaZoneId != null) {
    final z = f.seaZoneId!;
    final zoneKey = z.contains('|') ? z : '$regionId|$z';
    byLocation.putIfAbsent('sea:$zoneKey', () => []).add(f);
    return;
  }
  if (f.inPortAtProvinceId == null) return;
  final province =
      provinceMap['$regionId|${f.inPortAtProvinceId}'] ??
      provinceMap[f.inPortAtProvinceId!];
  if (province == null) return;
  byLocation
      .putIfAbsent('port:${province.regionId}|${province.id}', () => [])
      .add(f);
}

List<FleetTileMarkerView> _buildFleetTileMarkersForRegion({
  required Game game,
  required String regionId,
  required List<Province> provinces,
  required TileMapResult tileMap,
  required Set<String> seaZoneIds,
}) {
  final humanIds = game.players
      .where((p) => p.isHuman)
      .map((p) => p.id)
      .toSet();
  if (humanIds.isEmpty) {
    return const [];
  }

  final provinceMap = <String, Province>{
    for (final p in provinces) ...{'${p.regionId}|${p.id}': p, p.id: p},
  };

  final byLocation = <String, List<Fleet>>{};

  for (final f in game.worldState.fleets) {
    if (!_includeFleetForTileMarker(game, f, regionId, humanIds)) {
      continue;
    }
    _addFleetToLocationBuckets(
      f: f,
      regionId: regionId,
      provinceMap: provinceMap,
      byLocation: byLocation,
    );
  }

  final markers = <FleetTileMarkerView>[];
  for (final entry in byLocation.entries) {
    final scopeKey = entry.key;
    final fleets = entry.value.toList()..sort((a, b) => a.id.compareTo(b.id));
    final fleetIds = fleets.map((fl) => fl.id).toList();

    final tileKey = _fleetMarkerTileKeyForLocationScope(
      scopeKey: scopeKey,
      regionId: regionId,
      game: game,
      tileMap: tileMap,
      seaZoneIds: seaZoneIds,
      provinceMap: provinceMap,
    );
    if (tileKey == null) {
      continue;
    }
    final xy = _xyFromMapTileKey(tileKey);
    final x = xy.$1;
    final y = xy.$2;
    if (x == null || y == null) {
      continue;
    }
    markers.add(
      FleetTileMarkerView(
        tileKey: tileKey,
        x: x,
        y: y,
        locationScopeKey: scopeKey,
        fleetIds: fleetIds,
        stackCount: fleetIds.length,
      ),
    );
  }
  markers.sort((a, b) {
    final yc = a.y.compareTo(b.y);
    if (yc != 0) {
      return yc;
    }
    final xc = a.x.compareTo(b.x);
    if (xc != 0) {
      return xc;
    }
    return a.tileKey.compareTo(b.tileKey);
  });
  return markers;
}
