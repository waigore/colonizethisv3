/// WorldState JSON encode/decode helpers extracted so [WorldState] stays under
/// the models 400 physical-line cap (Refs #4136). Public API remains
/// [WorldState.toJson] / [WorldState.fromJson] on the aggregate.
library;

import 'army.dart';
import 'fleet.dart';
import 'province_id.dart';
import 'region_data.dart';
import 'tile_map_state.dart';
import 'turn_state.dart';
import 'world_state.dart';
import 'world_state/equality_helpers.dart';

Map<String, dynamic> encodeWorldStateToJson(WorldState worldState) {
  return {
    'turnState': worldState.turnState.toJson(),
    'oldWorld': worldState.oldWorld.toJson(),
    'newWorld': worldState.newWorld.toJson(),
    'tileState': worldState.tileState.toJson(),
    'portsByProvinceSeaboard': worldState.portsByProvinceSeaboard,
    if (worldState.playerVisibilityByTile.isNotEmpty)
      'playerVisibilityByTile': worldState.playerVisibilityByTile,
    if (worldState.playerProspectedTiles.isNotEmpty)
      'playerProspectedTiles': worldState.playerProspectedTiles.map(
        (playerId, tiles) => MapEntry(playerId, tiles.toList()),
      ),
    if (worldState.fleets.isNotEmpty)
      'fleets': worldState.fleets.map((e) => e.toJson()).toList(),
    if (worldState.tileKeysByRegionAndProvince.isNotEmpty)
      'tileKeysByRegionAndProvince':
          worldState.tileKeysByRegionAndProvince.map(
        (regionId, byProvince) => MapEntry(
          regionId,
          byProvince.map((provinceId, keys) => MapEntry(provinceId, keys)),
        ),
      ),
    if (worldState.spyRevealTurnsByPlayer.isNotEmpty)
      'spyRevealTurnsByPlayer': worldState.spyRevealTurnsByPlayer,
    if (worldState.purchasedTilesByTileKey.isNotEmpty)
      'purchasedTilesByTileKey': worldState.purchasedTilesByTileKey,
    if (worldState.resourceByTileKey.isNotEmpty)
      'resourceByTileKey': worldState.resourceByTileKey,
    if (worldState.seaZoneDisplayNameById.isNotEmpty)
      'seaZoneDisplayNameById': worldState.seaZoneDisplayNameById,
    'nextShipInstanceSeq': worldState.nextShipInstanceSeq,
    if (worldState.armies.isNotEmpty)
      'armies': worldState.armies.map((e) => e.toJson()).toList(),
    if (worldState.nextArmySeq != 1) 'nextArmySeq': worldState.nextArmySeq,
    if (worldState.newsDigestProvinceRevealDoneIds.isNotEmpty)
      'newsDigestProvinceRevealDoneIds':
          worldState.newsDigestProvinceRevealDoneIds,
    if (worldState.newsDigestSeaZoneFleetDoneIds.isNotEmpty)
      'newsDigestSeaZoneFleetDoneIds':
          worldState.newsDigestSeaZoneFleetDoneIds,
  };
}

WorldState decodeWorldStateFromJson(Map<String, dynamic> json) {
  final tileStateRaw = json['tileState'];
  final tileState = tileStateRaw is Map<String, dynamic>
      ? TileMapState.fromJson(tileStateRaw)
      : TileMapState.fromJson(
          tileStateRaw is Map<Object?, Object?>
              ? Map<String, dynamic>.from(tileStateRaw)
              : null,
        );

  final portsRaw = json['portsByProvinceSeaboard'];
  final ports = portsRaw is Map<Object?, Object?>
      ? Map<String, String>.from(
          portsRaw.map((k, v) => MapEntry(k.toString(), v.toString())),
        )
      : <String, String>{};

  final visRaw = json['playerVisibilityByTile'];
  final visibility = <String, Map<String, String>>{};
  if (visRaw is Map<Object?, Object?>) {
    visRaw.forEach((playerId, value) {
      if (value is Map<Object?, Object?>) {
        visibility[playerId.toString()] = Map<String, String>.from(
          value.map((k, v) => MapEntry(k.toString(), v.toString())),
        );
      }
    });
  }

  final prospectedRaw = json['playerProspectedTiles'];
  final prospected = <String, Set<String>>{};
  if (prospectedRaw is Map<Object?, Object?>) {
    prospectedRaw.forEach((playerId, value) {
      if (value is List<Object?>) {
        prospected[playerId.toString()] = value
            .map((e) => e.toString())
            .toSet();
      }
    });
  }

  final fleetsRaw = json['fleets'] as List<dynamic>? ?? [];
  final fleets = fleetsRaw
      .map(
        (e) => Fleet.fromJson(
          Map<String, dynamic>.from(e as Map<Object?, Object?>),
        ),
      )
      .toList();

  final inferredSeq = inferNextShipInstanceSeqFromFleets(fleets);
  final storedSeq = json['nextShipInstanceSeq'];
  final nextShipInstanceSeq = storedSeq is int
      ? (storedSeq >= inferredSeq ? storedSeq : inferredSeq)
      : inferredSeq;

  final armiesRaw = json['armies'] as List<dynamic>? ?? [];
  final armies = armiesRaw
      .map(
        (e) => Army.fromJson(
          Map<String, dynamic>.from(e as Map<Object?, Object?>),
        ),
      )
      .toList();

  final storedArmySeq = json['nextArmySeq'];
  final nextArmySeq = storedArmySeq is int ? storedArmySeq : 1;

  final newsProvRaw = json['newsDigestProvinceRevealDoneIds'] as List<dynamic>?;
  final newsDigestProvinceRevealDoneIds = newsProvRaw == null
      ? const <String>[]
      : newsProvRaw.map((e) => e.toString()).toList();

  final newsSeaRaw = json['newsDigestSeaZoneFleetDoneIds'] as List<dynamic>?;
  final newsDigestSeaZoneFleetDoneIds = newsSeaRaw == null
      ? const <String>[]
      : newsSeaRaw.map((e) => e.toString()).toList();

  final oldWorld = RegionData.fromJson(
    Map<String, dynamic>.from(json['oldWorld'] as Map<Object?, Object?>),
  );
  final newWorld = RegionData.fromJson(
    Map<String, dynamic>.from(json['newWorld'] as Map<Object?, Object?>),
  );
  final localProvinceIdsByRegion = <String, Set<String>>{
    'oldWorld': {
      for (final province in oldWorld.provinces)
        ProvinceId.isPrefixed(province.id)
            ? ProvinceId.localIdFrom(province.id)
            : province.id,
    },
    'newWorld': {
      for (final province in newWorld.provinces)
        ProvinceId.isPrefixed(province.id)
            ? ProvinceId.localIdFrom(province.id)
            : province.id,
    },
  };
  final tileKeysRaw = json['tileKeysByRegionAndProvince'];
  final tileKeysByRegionAndProvince = <String, Map<String, List<String>>>{};
  if (tileKeysRaw is Map<Object?, Object?>) {
    tileKeysRaw.forEach((regionIdRaw, byProvince) {
      if (byProvince is! Map<Object?, Object?>) return;
      final regionId = regionIdRaw.toString();
      final localProvinceIds = localProvinceIdsByRegion[regionId] ?? const {};
      final inner = <String, List<String>>{};
      byProvince.forEach((bucketId, keys) {
        if (keys is! List<Object?>) return;
        final key = bucketId.toString();
        final tileKeys = keys.map((e) => e.toString()).toList();
        final canonicalKey = worldStateCanonicalTileBucketKeyForLoad(
          regionId: regionId,
          bucketKey: key,
          tileKeys: tileKeys,
          localProvinceIds: localProvinceIds,
        );
        inner[canonicalKey] = tileKeys;
      });
      tileKeysByRegionAndProvince[regionId] = inner;
    });
  }

  final spyRevealRaw = json['spyRevealTurnsByPlayer'];
  final spyRevealTurnsByPlayer = <String, Map<String, int>>{};
  if (spyRevealRaw is Map<Object?, Object?>) {
    spyRevealRaw.forEach((playerId, inner) {
      if (inner is Map<Object?, Object?>) {
        spyRevealTurnsByPlayer[playerId.toString()] = inner.map(
          (k, v) =>
              MapEntry(k.toString(), (v is int) ? v : (v as num).toInt()),
        );
      }
    });
  }

  final purchasedRaw = json['purchasedTilesByTileKey'];
  final purchasedTilesByTileKey = purchasedRaw is Map<Object?, Object?>
      ? Map<String, String>.from(
          purchasedRaw.map((k, v) => MapEntry(k.toString(), v.toString())),
        )
      : <String, String>{};

  final resourceRaw = json['resourceByTileKey'];
  final resourceByTileKey = resourceRaw is Map<Object?, Object?>
      ? Map<String, String>.from(
          resourceRaw.map((k, v) => MapEntry(k.toString(), v.toString())),
        )
      : <String, String>{};

  final seaNamesRaw = json['seaZoneDisplayNameById'];
  final seaZoneDisplayNameById = seaNamesRaw is Map<Object?, Object?>
      ? Map<String, String>.from(
          seaNamesRaw.map((k, v) => MapEntry(k.toString(), v.toString())),
        )
      : <String, String>{};

  // Legacy key lastTurnProvinceExtractionByProvinceId ignored (Refs #4064).

  return WorldState(
    turnState: TurnState.fromJson(
      Map<String, dynamic>.from(json['turnState'] as Map<Object?, Object?>),
    ),
    oldWorld: oldWorld,
    newWorld: newWorld,
    tileState: tileState,
    portsByProvinceSeaboard: ports,
    playerVisibilityByTile: visibility,
    playerProspectedTiles: prospected,
    fleets: fleets,
    nextShipInstanceSeq: nextShipInstanceSeq,
    tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
    spyRevealTurnsByPlayer: spyRevealTurnsByPlayer,
    purchasedTilesByTileKey: purchasedTilesByTileKey,
    resourceByTileKey: resourceByTileKey,
    seaZoneDisplayNameById: seaZoneDisplayNameById,
    armies: armies,
    nextArmySeq: nextArmySeq,
    newsDigestProvinceRevealDoneIds: newsDigestProvinceRevealDoneIds,
    newsDigestSeaZoneFleetDoneIds: newsDigestSeaZoneFleetDoneIds,
  );
}
