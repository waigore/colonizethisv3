import 'army.dart';
import 'fleet.dart';
import 'region_data.dart';
import 'tile_map_state.dart';
import 'turn_state.dart';

/// Snapshot at a point in time. Turn state + region data + tile state. SPEC/game/world-model.
class WorldState {
  const WorldState({
    required this.turnState,
    required this.oldWorld,
    required this.newWorld,
    this.tileState = const TileMapState(),
    this.portsByProvinceSeaboard = const {},
    this.playerVisibilityByTile = const {},
    this.playerProspectedTiles = const {},
    this.fleets = const [],
    this.tileKeysByRegionAndProvince = const {},
    this.spyRevealTurnsByPlayer = const {},
    this.purchasedTilesByTileKey = const {},
    this.resourceByTileKey = const {},
    this.nextShipInstanceSeq = 1,
    this.armies = const [],
    this.nextArmySeq = 1,
  });

  final TurnState turnState;
  final RegionData oldWorld;
  final RegionData newWorld;

  /// Mutable per-tile improvement and road level. Key: "regionId|provinceId|x|y".
  final TileMapState tileState;

  /// Port present per (province, seaboard). Key: "provinceId|seaZoneId", value: tile key.
  final Map<String, String> portsByProvinceSeaboard;

  /// Per-player tile visibility: playerId -> (tileKey -> visibility level name).
  /// Visibility level names correspond to the enum in SPEC/game/fog-and-exploration.md.
  final Map<String, Map<String, String>> playerVisibilityByTile;

  /// Per-player set of prospected tile keys: playerId -> set of tile keys.
  /// Stored as lists in JSON; converted to sets in logic as needed.
  final Map<String, Set<String>> playerProspectedTiles;

  /// Fleets (naval). SPEC/game/ships-and-naval.md.
  final List<Fleet> fleets;

  /// Tile keys per region and province. regionId -> provinceId -> list of tile keys.
  /// Used for explore resolution (full province reveal). Populated at game setup.
  /// SPEC/program/fog-and-exploration-resolution.md.
  final Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince;

  /// Spy reveal timers: playerId -> (provinceKey -> turns left until fog returns). SPEC/program/fog-and-exploration-resolution.md.
  final Map<String, Map<String, int>> spyRevealTurnsByPlayer;

  /// Purchased tiles (Merchant purchase_land): tileKey -> buyer playerId. Minor/Tribe tiles bought by GP. SPEC/game/civilian-units.md.
  final Map<String, String> purchasedTilesByTileKey;

  /// Resource (commodity id) per tile key. Populated at game setup from tile map. Used for purchase_land validation.
  final Map<String, String> resourceByTileKey;

  /// Next index for minting `ship_<n>` instance ids. At least [inferNextShipInstanceSeqFromFleets](fleets).
  /// SPEC/game/ships-and-naval.md.
  final int nextShipInstanceSeq;

  /// Land armies (regiment containers). SPEC/game/military-armies.md.
  final List<Army> armies;

  /// Monotonic counter for minting non-home army ids (e.g. split armies).
  final int nextArmySeq;

  Map<String, dynamic> toJson() => {
        'turnState': turnState.toJson(),
        'oldWorld': oldWorld.toJson(),
        'newWorld': newWorld.toJson(),
        'tileState': tileState.toJson(),
        'portsByProvinceSeaboard': portsByProvinceSeaboard,
        if (playerVisibilityByTile.isNotEmpty)
          'playerVisibilityByTile': playerVisibilityByTile,
        if (playerProspectedTiles.isNotEmpty)
          'playerProspectedTiles': playerProspectedTiles.map(
            (playerId, tiles) => MapEntry(playerId, tiles.toList()),
          ),
        if (fleets.isNotEmpty) 'fleets': fleets.map((e) => e.toJson()).toList(),
        if (tileKeysByRegionAndProvince.isNotEmpty)
          'tileKeysByRegionAndProvince': tileKeysByRegionAndProvince.map(
            (regionId, byProvince) => MapEntry(
              regionId,
              byProvince.map((provinceId, keys) => MapEntry(provinceId, keys)),
            ),
          ),
        if (spyRevealTurnsByPlayer.isNotEmpty) 'spyRevealTurnsByPlayer': spyRevealTurnsByPlayer,
        if (purchasedTilesByTileKey.isNotEmpty) 'purchasedTilesByTileKey': purchasedTilesByTileKey,
        if (resourceByTileKey.isNotEmpty) 'resourceByTileKey': resourceByTileKey,
        'nextShipInstanceSeq': nextShipInstanceSeq,
        if (armies.isNotEmpty) 'armies': armies.map((e) => e.toJson()).toList(),
        if (nextArmySeq != 1) 'nextArmySeq': nextArmySeq,
      };

  static WorldState fromJson(Map<String, dynamic> json) {
    final tileStateRaw = json['tileState'];
    final tileState = tileStateRaw is Map<String, dynamic>
        ? TileMapState.fromJson(tileStateRaw)
        : TileMapState.fromJson(
            tileStateRaw is Map ? Map<String, dynamic>.from(tileStateRaw) : null);

    final portsRaw = json['portsByProvinceSeaboard'];
    final ports = portsRaw is Map
        ? Map<String, String>.from(
            portsRaw.map((k, v) => MapEntry(k.toString(), v.toString())))
        : <String, String>{};

    final visRaw = json['playerVisibilityByTile'];
    final visibility = <String, Map<String, String>>{};
    if (visRaw is Map) {
      visRaw.forEach((playerId, value) {
        if (value is Map) {
          visibility[playerId.toString()] = Map<String, String>.from(
            value.map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ),
          );
        }
      });
    }

    final prospectedRaw = json['playerProspectedTiles'];
    final prospected = <String, Set<String>>{};
    if (prospectedRaw is Map) {
      prospectedRaw.forEach((playerId, value) {
        if (value is List) {
          prospected[playerId.toString()] = value
              .map((e) => e.toString())
              .toSet();
        }
      });
    }

    final fleetsRaw = json['fleets'] as List<dynamic>? ?? [];
    final fleets = fleetsRaw
        .map((e) => Fleet.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final inferredSeq = inferNextShipInstanceSeqFromFleets(fleets);
    final storedSeq = json['nextShipInstanceSeq'];
    final nextShipInstanceSeq = storedSeq is int
        ? (storedSeq >= inferredSeq ? storedSeq : inferredSeq)
        : inferredSeq;

    final armiesRaw = json['armies'] as List<dynamic>? ?? [];
    final armies = armiesRaw
        .map((e) => Army.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final storedArmySeq = json['nextArmySeq'];
    final nextArmySeq = storedArmySeq is int ? storedArmySeq : 1;

    final tileKeysRaw = json['tileKeysByRegionAndProvince'];
    final tileKeysByRegionAndProvince = <String, Map<String, List<String>>>{};
    if (tileKeysRaw is Map) {
      tileKeysRaw.forEach((regionId, byProvince) {
        if (byProvince is Map) {
          final inner = <String, List<String>>{};
          byProvince.forEach((provinceId, keys) {
            if (keys is List) {
              inner[provinceId.toString()] =
                  keys.map((e) => e.toString()).toList();
            }
          });
          tileKeysByRegionAndProvince[regionId.toString()] = inner;
        }
      });
    }

    final spyRevealRaw = json['spyRevealTurnsByPlayer'];
    final spyRevealTurnsByPlayer = <String, Map<String, int>>{};
    if (spyRevealRaw is Map) {
      spyRevealRaw.forEach((playerId, inner) {
        if (inner is Map) {
          spyRevealTurnsByPlayer[playerId.toString()] = inner.map(
            (k, v) => MapEntry(k.toString(), (v is int) ? v : (v as num).toInt()),
          );
        }
      });
    }

    final purchasedRaw = json['purchasedTilesByTileKey'];
    final purchasedTilesByTileKey = purchasedRaw is Map
        ? Map<String, String>.from(
            purchasedRaw.map((k, v) => MapEntry(k.toString(), v.toString())))
        : <String, String>{};

    final resourceRaw = json['resourceByTileKey'];
    final resourceByTileKey = resourceRaw is Map
        ? Map<String, String>.from(
            resourceRaw.map((k, v) => MapEntry(k.toString(), v.toString())))
        : <String, String>{};

    return WorldState(
      turnState: TurnState.fromJson(Map<String, dynamic>.from(json['turnState'] as Map)),
      oldWorld: RegionData.fromJson(Map<String, dynamic>.from(json['oldWorld'] as Map)),
      newWorld: RegionData.fromJson(Map<String, dynamic>.from(json['newWorld'] as Map)),
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
      armies: armies,
      nextArmySeq: nextArmySeq,
    );
  }

  WorldState copyWith({
    TurnState? turnState,
    RegionData? oldWorld,
    RegionData? newWorld,
    TileMapState? tileState,
    Map<String, String>? portsByProvinceSeaboard,
    Map<String, Map<String, String>>? playerVisibilityByTile,
    Map<String, Set<String>>? playerProspectedTiles,
    List<Fleet>? fleets,
    Map<String, Map<String, List<String>>>? tileKeysByRegionAndProvince,
    Map<String, Map<String, int>>? spyRevealTurnsByPlayer,
    Map<String, String>? purchasedTilesByTileKey,
    Map<String, String>? resourceByTileKey,
    int? nextShipInstanceSeq,
    List<Army>? armies,
    int? nextArmySeq,
  }) {
    return WorldState(
      turnState: turnState ?? this.turnState,
      oldWorld: oldWorld ?? this.oldWorld,
      newWorld: newWorld ?? this.newWorld,
      tileState: tileState ?? this.tileState,
      portsByProvinceSeaboard: portsByProvinceSeaboard ?? this.portsByProvinceSeaboard,
      playerVisibilityByTile: playerVisibilityByTile ?? this.playerVisibilityByTile,
      playerProspectedTiles: playerProspectedTiles ?? this.playerProspectedTiles,
      fleets: fleets ?? this.fleets,
      tileKeysByRegionAndProvince:
          tileKeysByRegionAndProvince ?? this.tileKeysByRegionAndProvince,
      spyRevealTurnsByPlayer: spyRevealTurnsByPlayer ?? this.spyRevealTurnsByPlayer,
      purchasedTilesByTileKey: purchasedTilesByTileKey ?? this.purchasedTilesByTileKey,
      resourceByTileKey: resourceByTileKey ?? this.resourceByTileKey,
      nextShipInstanceSeq: nextShipInstanceSeq ?? this.nextShipInstanceSeq,
      armies: armies ?? this.armies,
      nextArmySeq: nextArmySeq ?? this.nextArmySeq,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldState &&
          runtimeType == other.runtimeType &&
          turnState == other.turnState &&
          oldWorld == other.oldWorld &&
          newWorld == other.newWorld &&
          tileState == other.tileState &&
          _mapEquals(portsByProvinceSeaboard, other.portsByProvinceSeaboard) &&
          _nestedStringMapEquals(playerVisibilityByTile, other.playerVisibilityByTile) &&
          _mapOfSetEquals(playerProspectedTiles, other.playerProspectedTiles) &&
          _listEqualsFleet(fleets, other.fleets) &&
          _tileKeysByRegionEquals(
              tileKeysByRegionAndProvince, other.tileKeysByRegionAndProvince) &&
          _spyRevealEquals(spyRevealTurnsByPlayer, other.spyRevealTurnsByPlayer) &&
          _mapEquals(purchasedTilesByTileKey, other.purchasedTilesByTileKey) &&
          _mapEquals(resourceByTileKey, other.resourceByTileKey) &&
          nextShipInstanceSeq == other.nextShipInstanceSeq &&
          _listEqualsArmy(armies, other.armies) &&
          nextArmySeq == other.nextArmySeq;

  @override
  int get hashCode => Object.hash(
        turnState,
        oldWorld,
        newWorld,
        tileState,
        Object.hashAll(portsByProvinceSeaboard.entries),
        Object.hashAll(
          playerVisibilityByTile.entries.map(
            (e) => Object.hash(e.key, Object.hashAll(e.value.entries)),
          ),
        ),
        Object.hashAll(
          playerProspectedTiles.entries.map(
            (e) => Object.hash(e.key, Object.hashAll(e.value)),
          ),
        ),
        Object.hashAll(fleets),
        Object.hashAll(
          tileKeysByRegionAndProvince.entries.map(
            (e) => Object.hash(e.key, Object.hashAll(e.value.entries.map(
                  (e2) => Object.hash(e2.key, Object.hashAll(e2.value)),
                ))),
          ),
        ),
        Object.hashAll(spyRevealTurnsByPlayer.entries.map(
          (e) => Object.hash(e.key, Object.hashAll(e.value.entries)),
        )),
        Object.hashAll(purchasedTilesByTileKey.entries),
        Object.hashAll(resourceByTileKey.entries),
        nextShipInstanceSeq,
        Object.hashAll(armies),
        nextArmySeq,
      );

  static bool _tileKeysByRegionEquals(
    Map<String, Map<String, List<String>>> a,
    Map<String, Map<String, List<String>>> b,
  ) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final otherInner = b[entry.key];
      if (otherInner == null) return false;
      if (otherInner.length != entry.value.length) return false;
      for (final innerEntry in entry.value.entries) {
        final otherList = otherInner[innerEntry.key];
        if (otherList == null ||
            otherList.length != innerEntry.value.length ||
            !_listEqualsString(innerEntry.value, otherList)) {
          return false;
        }
      }
    }
    return true;
  }

  static bool _listEqualsString(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _listEqualsArmy(List<Army> a, List<Army> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _listEqualsFleet(List<Fleet> a, List<Fleet> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

  static bool _nestedStringMapEquals(
    Map<String, Map<String, String>> a,
    Map<String, Map<String, String>> b,
  ) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final otherInner = b[entry.key];
      if (otherInner == null || !_mapEquals(entry.value, otherInner)) {
        return false;
      }
    }
    return true;
  }

  static bool _spyRevealEquals(
    Map<String, Map<String, int>> a,
    Map<String, Map<String, int>> b,
  ) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final otherInner = b[entry.key];
      if (otherInner == null || otherInner.length != entry.value.length) return false;
      for (final innerEntry in entry.value.entries) {
        if (otherInner[innerEntry.key] != innerEntry.value) return false;
      }
    }
    return true;
  }

  static bool _mapOfSetEquals(
    Map<String, Set<String>> a,
    Map<String, Set<String>> b,
  ) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final otherSet = b[entry.key];
      if (otherSet == null || entry.value.length != otherSet.length) {
        return false;
      }
      for (final v in entry.value) {
        if (!otherSet.contains(v)) return false;
      }
    }
    return true;
  }
}

