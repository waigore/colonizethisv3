/// Builder for InitGameMapViewData from game + tile maps + topology.
/// SPEC/program/map-visualization.md § Map view model for tools.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'combine_region_topologies.dart';
import 'init_game_map_view_data.dart';
import 'port_icon_placement.dart';
import 'tile_map_visualization_shared.dart';

String? _capitalTileKeyForProvince({
  required Game game,
  required String regionId,
  required String fullProvinceId,
}) {
  for (final p in game.players) {
    if (p.capitalProvinceId == fullProvinceId &&
        p.capitalTile != null &&
        p.capitalTile!.regionId == regionId) {
      return p.capitalTile!.toTileKey();
    }
  }
  for (final m in game.minorNations) {
    if (m.capitalProvinceId == fullProvinceId &&
        m.capitalTile != null &&
        m.capitalTile!.regionId == regionId) {
      return m.capitalTile!.toTileKey();
    }
  }
  for (final t in game.tribes) {
    if (t.capitalProvinceId == fullProvinceId &&
        t.capitalTile != null &&
        t.capitalTile!.regionId == regionId) {
      return t.capitalTile!.toTileKey();
    }
  }
  return null;
}

final _log = mapLogger();

const String _regionOldWorld = 'oldWorld';
const String _regionNewWorld = 'newWorld';

String _normalizeCivilianTypeForPriority(String type) {
  return type.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
}

int _civilianIconPriorityForType(String type) {
  final normalized = _normalizeCivilianTypeForPriority(type);
  // Lower number = higher icon priority.
  switch (normalized) {
    case 'builder':
      return 0;
    case 'engineer':
      return 1;
    case 'railbuilder':
      return 2;
    case 'explorer':
      return 3;
    case 'merchant':
      return 4;
    case 'spy':
      return 5;
    default:
      return 999;
  }
}

bool _isCivilianUnitType(String unitType) {
  final role = unitRoleForType(unitType);
  if (role == null) {
    return false;
  }
  return role != UnitRole.military && role != UnitRole.naval;
}

InitGameMapViewData buildInitGameMapViewData({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, MapTopology> topologyByRegion,
  required int cellSize,
  int? seed,
  String? configSummary,
  Map<String, (int r, int g, int b)>? greatPowerColorOverride,

  /// Optional per-tile visibility for the current player view, keyed by tile
  /// key `regionId|provinceId|x|y`. When omitted, all tiles are treated as
  /// [TileVisibility.visible] in the view data.
  Map<String, TileVisibility>? visibilityByTile,

  /// Optional warp links for rendering warp zone indicators.
  List<WarpLink>? warpLinks,
}) {
  _log.i('buildInitGameMapViewData start gameId=${game.id}');
  final owTileMap = tileMapByRegion[_regionOldWorld]!;
  final nwTileMap = tileMapByRegion[_regionNewWorld]!;
  final owTopology = topologyByRegion[_regionOldWorld]!;
  final nwTopology = topologyByRegion[_regionNewWorld]!;

  final owRegion = _buildRegionViewData(
    regionId: _regionOldWorld,
    tileMap: owTileMap,
    topology: owTopology,
    game: game,
    cellSize: cellSize,
    isOldWorld: true,
    greatPowerColorOverride: greatPowerColorOverride,
    visibilityByTile: visibilityByTile,
    warpLinks: warpLinks,
  );
  final nwRegion = _buildRegionViewData(
    regionId: _regionNewWorld,
    tileMap: nwTileMap,
    topology: nwTopology,
    game: game,
    cellSize: cellSize,
    isOldWorld: false,
    greatPowerColorOverride: greatPowerColorOverride,
    visibilityByTile: visibilityByTile,
    warpLinks: warpLinks,
  );

  _log.i('buildInitGameMapViewData end');
  final combinedTopology = combineRegionTopologies(
    topologyByRegion: topologyByRegion,
    warpLinks: warpLinks ?? const [],
  );
  return InitGameMapViewData(
    oldWorld: owRegion,
    newWorld: nwRegion,
    combinedTopology: combinedTopology,
    seed: seed,
    configSummary: configSummary,
  );
}

RegionMapViewData _buildRegionViewData({
  required String regionId,
  required TileMapResult tileMap,
  required MapTopology topology,
  required Game game,
  required int cellSize,
  required bool isOldWorld,
  Map<String, (int r, int g, int b)>? greatPowerColorOverride,
  Map<String, TileVisibility>? visibilityByTile,
  List<WarpLink>? warpLinks,
}) {
  final seaZoneIds = {
    for (final n in topology.nodes)
      if (n.type == TopologyNodeType.seaZone) n.id,
  };

  // Owner and province display name by province id.
  final ownerByProvinceId = <String, String>{};
  final provinceDisplayNameById = <String, String>{};
  final provinces = isOldWorld
      ? game.worldState.oldWorld.provinces
      : game.worldState.newWorld.provinces;
  final provincePoliticalOwnerByPrefixedProvinceId = <String, String?>{};
  for (final p in provinces) {
    provincePoliticalOwnerByPrefixedProvinceId[p.id] = p.ownerId;
    if (p.ownerId != null && p.ownerId!.isNotEmpty) {
      ownerByProvinceId[p.id] = p.ownerId!;
    }
    if (p.displayName != null && p.displayName!.isNotEmpty) {
      provinceDisplayNameById[p.id] = p.displayName!;
    }
  }

  // Collect faction ids by type for ownership colours.
  final greatPowerIds = <String>[];
  final minorNationIds = <String>[];
  final tribeIds = <String>[];
  for (final p in game.players) {
    greatPowerIds.add(p.id);
  }
  final greatPowerFactionIds = greatPowerIds.toSet();
  for (final m in game.minorNations) {
    minorNationIds.add(m.id);
  }
  for (final t in game.tribes) {
    tribeIds.add(t.id);
  }
  final factionColors = factionOwnershipColorMap(
    greatPowerIds: greatPowerIds,
    minorNationIds: minorNationIds,
    tribeIds: tribeIds,
    greatPowerColorOverride: greatPowerColorOverride,
  );

  // Terrain palette: same as base tile map PNG (shared terrainColorRgb).
  final terrainColors = <TerrainType, Rgb>{};
  if (tileMap.terrainGrid != null) {
    for (final row in tileMap.terrainGrid!) {
      for (final t in row) {
        if (t != null && !terrainColors.containsKey(t)) {
          terrainColors[t] = terrainColorRgb[t]!;
        }
      }
    }
  }

  final tileState = game.worldState.tileState;
  final cells = <CellViewData>[];
  for (var y = 0; y < tileMap.height; y++) {
    for (var x = 0; x < tileMap.width; x++) {
      final localId = tileMap.cell(x, y);
      final isSea = seaZoneIds.contains(localId);
      final terrain = tileMap.terrainAt(x, y);
      final resource = tileMap.resourceAt(x, y);
      // Tile key for improvement/road lookup: regionId|provinceId|x|y (provinceId = regionCellId for land).
      final tileKey = '$regionId|$localId|$x|$y';
      final improvement = isSea ? null : tileState.improvementLevel(tileKey);
      final road = isSea ? null : tileState.roadLevel(tileKey);
      final visibility = visibilityByTile != null
          ? (visibilityByTile[tileKey] ?? TileVisibility.visible)
          : TileVisibility.visible;
      final fullProvinceId = isSea ? null : ProvinceId.full(regionId, localId);
      cells.add(
        CellViewData(
          x: x,
          y: y,
          regionCellId: localId,
          isSea: isSea,
          terrainTypeId: terrain?.name,
          terrainType: terrain,
          resourceId: resource?.name,
          ownerFactionId: fullProvinceId != null
              ? ownerByProvinceId[fullProvinceId]
              : null,
          provinceDisplayName: isSea
              ? null
              : (fullProvinceId != null
                    ? provinceDisplayNameById[fullProvinceId]
                    : null),
          improvementLevel: isSea ? null : improvement,
          roadLevel: isSea ? null : road,
          visibility: visibility,
        ),
      );
    }
  }

  // Capital markers.
  final capitals = <CapitalMarkerView>[];
  for (final p in game.players) {
    final cap = p.capitalTile;
    if (cap != null && cap.regionId == regionId) {
      capitals.add(
        CapitalMarkerView(
          factionId: p.id,
          displayName: p.displayName,
          x: cap.x,
          y: cap.y,
        ),
      );
    }
  }
  for (final m in game.minorNations) {
    final cap = m.capitalTile;
    if (cap != null && cap.regionId == regionId) {
      capitals.add(
        CapitalMarkerView(
          factionId: m.id,
          displayName: m.displayName ?? m.id,
          x: cap.x,
          y: cap.y,
        ),
      );
    }
  }
  for (final t in game.tribes) {
    final cap = t.capitalTile;
    if (cap != null && cap.regionId == regionId) {
      capitals.add(
        CapitalMarkerView(
          factionId: t.id,
          displayName: t.displayName ?? t.id,
          x: cap.x,
          y: cap.y,
        ),
      );
    }
  }

  // Province id → representative tile (x,y) for units overlay.
  final provinceToTile = <String, (int x, int y)>{};
  for (var y = 0; y < tileMap.height; y++) {
    for (var x = 0; x < tileMap.width; x++) {
      final localId = tileMap.cell(x, y);
      if (seaZoneIds.contains(localId)) {
        continue;
      }
      final fullProvinceId = ProvinceId.full(regionId, localId);
      if (!provinceToTile.containsKey(fullProvinceId)) {
        provinceToTile[fullProvinceId] = (x, y);
      }
    }
  }

  // Unit markers: one per unit, placed at province representative tile.
  final unitMarkers = <UnitMarkerView>[];
  final civilianUnitsByTileKey = <String, List<Unit>>{};
  final playerOwnedCivilianTileMarkers = <CivilianTileMarkerView>[];
  final humanPlayerIds = game.players
      .where((player) => player.isHuman)
      .map((player) => player.id)
      .toSet();
  final provincePresenceById = <String, ProvinceUnitPresenceView>{};
  for (final p in provinces) {
    provincePresenceById[p.id] = const ProvinceUnitPresenceView(
      civilianCount: 0,
      regimentCount: 0,
      shipCount: 0,
      intelVisible: false,
    );
  }

  // Province intel visibility: true when any tile in that province is currently visible.
  for (final cell in cells) {
    if (cell.isSea || cell.visibility != TileVisibility.visible) {
      continue;
    }
    final fullProvinceId = ProvinceId.full(regionId, cell.regionCellId);
    final current = provincePresenceById[fullProvinceId];
    if (current == null) {
      continue;
    }
    provincePresenceById[fullProvinceId] = ProvinceUnitPresenceView(
      civilianCount: current.civilianCount,
      regimentCount: current.regimentCount,
      shipCount: current.shipCount,
      intelVisible: true,
    );
  }

  final regionUnits = isOldWorld
      ? game.worldState.oldWorld.units
      : game.worldState.newWorld.units;
  for (final u in regionUnits) {
    final isPlayerOwnedCivilian =
        humanPlayerIds.contains(u.ownerId) && _isCivilianUnitType(u.type);
    if (isPlayerOwnedCivilian) {
      final tileKey = u.tileKey;
      if (tileKey != null && tileKey.isNotEmpty) {
        final parts = tileKey.split('|');
        if (parts.length >= 4 && parts[0] == regionId) {
          civilianUnitsByTileKey.putIfAbsent(tileKey, () => []).add(u);
        }
      }
    }

    final tile = provinceToTile[u.locationProvinceId];
    if (tile != null) {
      unitMarkers.add(
        UnitMarkerView(x: tile.$1, y: tile.$2, ownerFactionId: u.ownerId),
      );
    }

    final current = provincePresenceById[u.locationProvinceId];
    if (current == null) {
      continue;
    }
    final isRegiment = isMilitaryUnit(u.type);
    provincePresenceById[u.locationProvinceId] = ProvinceUnitPresenceView(
      civilianCount: current.civilianCount + (isRegiment ? 0 : 1),
      regimentCount: current.regimentCount + (isRegiment ? 1 : 0),
      shipCount: current.shipCount,
      intelVisible: current.intelVisible,
    );
  }

  for (final entry in civilianUnitsByTileKey.entries) {
    final tileKey = entry.key;
    final units = entry.value.toList()
      ..sort((a, b) {
        final priorityCompare = _civilianIconPriorityForType(
          a.type,
        ).compareTo(_civilianIconPriorityForType(b.type));
        if (priorityCompare != 0) {
          return priorityCompare;
        }
        return a.id.compareTo(b.id);
      });
    final parts = tileKey.split('|');
    if (parts.length < 4) {
      continue;
    }
    final x = int.tryParse(parts[2]);
    final y = int.tryParse(parts[3]);
    if (x == null || y == null) {
      continue;
    }
    final representativeUnit = units.first;
    final representativeIsAssigned =
        representativeUnit.assignedTileKey == tileKey &&
        representativeUnit.status == UnitStatus.working;
    playerOwnedCivilianTileMarkers.add(
      CivilianTileMarkerView(
        tileKey: tileKey,
        x: x,
        y: y,
        localProvinceId: parts[1],
        unitIds: units.map((unit) => unit.id).toList(),
        unitTypes: {for (final unit in units) unit.id: unit.type},
        representativeUnitType: representativeUnit.type,
        stackCount: units.length,
        representativeIsAssigned: representativeIsAssigned,
      ),
    );
  }
  playerOwnedCivilianTileMarkers.sort((a, b) {
    final yCompare = a.y.compareTo(b.y);
    if (yCompare != 0) {
      return yCompare;
    }
    final xCompare = a.x.compareTo(b.x);
    if (xCompare != 0) {
      return xCompare;
    }
    return a.tileKey.compareTo(b.tileKey);
  });

  // Port markers from world state.
  final ports = <PortMarkerView>[];
  final portsByProvinceSeaboard = game.worldState.portsByProvinceSeaboard;
  portsByProvinceSeaboard.forEach((key, tileKey) {
    final parts = tileKey.split('|');
    if (parts.length < 4) {
      return;
    }
    final regId = parts[0];
    if (regId != regionId) {
      return;
    }
    final provinceId = parts[1];
    final x = int.tryParse(parts[2]);
    final y = int.tryParse(parts[3]);
    if (x == null || y == null) {
      return;
    }
    ports.add(
      PortMarkerView(
        x: x,
        y: y,
        provinceId: provinceId,
        seaZoneId: '',
        seaboardKey: key,
      ),
    );
  });

  // Determine coastal provinces from topology edges (P<->S connections).
  // A province is coastal if it has an edge to any sea zone node in [seaZoneIds].
  final coastalProvinceIds = <String>{};
  for (final edge in topology.edges) {
    final id1Sea = seaZoneIds.contains(edge.id1);
    final id2Sea = seaZoneIds.contains(edge.id2);
    if ((id1Sea && !id2Sea) || (!id1Sea && id2Sea)) {
      coastalProvinceIds.add(id1Sea ? edge.id2 : edge.id1);
    }
  }

  // Town markers: one per province with a town, at the town's tile position.
  final towns = <TownMarkerView>[];
  final portProvinceIds = ports.map((p) => p.provinceId).toSet();
  for (final p in provinces) {
    final townTileKey = p.townTileKey;
    if (townTileKey == null || townTileKey.isEmpty) {
      continue;
    }
    final parts = townTileKey.split('|');
    if (parts.length < 4) {
      continue;
    }
    final regId = parts[0];
    if (regId != regionId) {
      continue;
    }
    final x = int.tryParse(parts[2]);
    final y = int.tryParse(parts[3]);
    if (x == null || y == null) {
      continue;
    }
    final localProvinceId = ProvinceId.localIdFrom(p.id);
    final fullProvinceId = ProvinceId.full(regionId, localProvinceId);
    final hasPort = portProvinceIds.contains(localProvinceId);
    String? portTileKey;
    if (hasPort) {
      for (final pm in ports) {
        if (pm.provinceId == localProvinceId) {
          portTileKey = '$regionId|${pm.provinceId}|${pm.x}|${pm.y}';
          break;
        }
      }
    }
    final capitalTileKey = _capitalTileKeyForProvince(
      game: game,
      regionId: regionId,
      fullProvinceId: fullProvinceId,
    );
    int? portIconX;
    int? portIconY;
    if (hasPort && portTileKey != null) {
      final placed = computePortIconCellForMap(
        tileMap: tileMap,
        seaZoneIds: seaZoneIds,
        townX: x,
        townY: y,
        townTileKey: townTileKey,
        capitalTileKey: capitalTileKey,
        portTileKey: portTileKey,
      );
      portIconX = placed.x;
      portIconY = placed.y;
    }
    final touchesSea = coastalProvinceIds.contains(localProvinceId);
    towns.add(
      TownMarkerView(
        x: x,
        y: y,
        provinceId: localProvinceId,
        isCoastal: touchesSea && !hasPort,
        isPort: hasPort,
        touchesSea: touchesSea,
        portIconX: portIconX,
        portIconY: portIconY,
      ),
    );
  }

  // Sea zone id → representative tile (x,y) for warp zone markers.
  final seaZoneToTile = <String, (int x, int y)>{};
  for (var y = 0; y < tileMap.height; y++) {
    for (var x = 0; x < tileMap.width; x++) {
      final localId = tileMap.cell(x, y);
      if (!seaZoneIds.contains(localId)) {
        continue;
      }
      if (!seaZoneToTile.containsKey(localId)) {
        seaZoneToTile[localId] = (x, y);
      }
    }
  }

  // Warp zone markers: one per warp link for this region.
  final warpMarkers = <WarpMarkerView>[];
  if (warpLinks != null) {
    for (final link in warpLinks) {
      // Check if this link involves the current region (either as source or destination).
      if (link.regionId == regionId) {
        // This region is the source of the warp link.
        final tile = seaZoneToTile[link.seaZoneId];
        if (tile != null) {
          warpMarkers.add(
            WarpMarkerView(
              x: tile.$1,
              y: tile.$2,
              seaZoneId: link.seaZoneId,
              otherRegionId: link.otherRegionId,
              otherSeaZoneId: link.otherSeaZoneId,
            ),
          );
        }
      } else if (link.otherRegionId == regionId) {
        // This region is the destination of the warp link (reverse direction).
        final tile = seaZoneToTile[link.otherSeaZoneId];
        if (tile != null) {
          warpMarkers.add(
            WarpMarkerView(
              x: tile.$1,
              y: tile.$2,
              seaZoneId: link.otherSeaZoneId,
              otherRegionId: link.regionId,
              otherSeaZoneId: link.seaZoneId,
            ),
          );
        }
      }
    }
  }

  // Ship presence counts by in-port province.
  for (final fleet in game.worldState.fleets) {
    if (fleet.regionId != regionId || !fleet.isInPort) {
      continue;
    }
    final provinceId = fleet.inPortAtProvinceId;
    if (provinceId == null) {
      continue;
    }
    final current = provincePresenceById[provinceId];
    if (current == null) {
      continue;
    }
    provincePresenceById[provinceId] = ProvinceUnitPresenceView(
      civilianCount: current.civilianCount,
      regimentCount: current.regimentCount,
      shipCount: current.shipCount + fleet.ships.length,
      intelVisible: current.intelVisible,
    );
  }

  return RegionMapViewData(
    regionId: regionId,
    width: tileMap.width,
    height: tileMap.height,
    cellSize: cellSize,
    cells: cells,
    capitalMarkers: capitals,
    portMarkers: ports,
    factionColors: factionColors,
    greatPowerFactionIds: greatPowerFactionIds,
    terrainColors: terrainColors,
    unitMarkers: unitMarkers,
    civilianTileMarkers: playerOwnedCivilianTileMarkers,
    warpMarkers: warpMarkers,
    townMarkers: towns,
    provinceUnitPresenceByProvinceId: provincePresenceById,
    provincePoliticalOwnerByPrefixedProvinceId:
        provincePoliticalOwnerByPrefixedProvinceId,
  );
}
