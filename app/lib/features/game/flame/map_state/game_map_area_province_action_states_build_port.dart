import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_models/colonizethis_models.dart' show ProvinceId;
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/foundation.dart';

import 'game_map_area_province_action_states_assignable.dart'
    show GameMapAreaProvinceActionStatesAssignable, ProvinceInlineActionState;

/// Build-port inline-action visibility/enablement for province overlay.
/// Refs #4332 — MAP20001 Tile transport/port row shortcut.
abstract final class GameMapAreaProvinceActionStatesBuildPort {
  /// Whether [build_port] is still conceivable on this land tile.
  ///
  /// Conceivable when the tile is human-owned, cardinally adjacent to a sea
  /// zone that does not yet have a port for this province, and the tile is not
  /// already registered as a port tile.
  @visibleForTesting
  static bool tileCanConceivablyTakeBuildPortStep({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required MapTopology? topology,
    required Map<String, TileMapResult>? tileMapByRegion,
  }) {
    final parsed = tryParseTileKey(selectedTileKey);
    if (parsed == null) return false;
    final province = game.worldState.tryGetProvince(parsed.prefixedProvinceId);
    if (province == null || province.ownerId != humanPlayerId) return false;
    if (game.worldState.portsByProvinceSeaboard.values.contains(
      selectedTileKey,
    )) {
      return false;
    }
    if (topology == null || tileMapByRegion == null) return false;
    final map = tileMapByRegion[parsed.regionId];
    if (map == null) return false;
    final openSeaZones = openSeaboardSeaZoneIdsForTile(
      game: game,
      topology: topology,
      map: map,
      prefixedProvinceId: parsed.prefixedProvinceId,
      x: parsed.x,
      y: parsed.y,
    );
    return openSeaZones.isNotEmpty;
  }

  /// Sea-zone ids adjacent to [selectedTileKey] that still lack a province
  /// seaboard port entry.
  @visibleForTesting
  static Set<String> openSeaboardSeaZoneIdsForTile({
    required ct_models.Game game,
    required MapTopology topology,
    required TileMapResult map,
    required String prefixedProvinceId,
    required int x,
    required int y,
  }) {
    final provinceIds = provinceNodeIds(topology);
    final localProvinceId = ProvinceId.localIdFrom(prefixedProvinceId);
    final regionId = ProvinceId.regionIdFrom(prefixedProvinceId);
    final adjacentSeaZones = seaZoneIdsAdjacentToProvince(
      topology,
      topologyUsesPrefixedIds(topology) ? prefixedProvinceId : localProvinceId,
      regionId: regionId,
    );
    if (adjacentSeaZones.isEmpty) return const {};

    final touching = <String>{};
    for (final d in kGridNeighborsCardinal4) {
      final nx = x + d.$1;
      final ny = y + d.$2;
      if (nx < 0 || nx >= map.width || ny < 0 || ny >= map.height) continue;
      final cellId = map.cell(nx, ny);
      if (provinceIds.contains(cellId)) continue;
      for (final seaZoneId in adjacentSeaZones) {
        final localSea = seaZoneId.contains('|')
            ? seaZoneId.split('|').last
            : seaZoneId;
        if (cellId == seaZoneId || cellId == localSea) {
          touching.add(seaZoneId);
        }
      }
    }
    if (touching.isEmpty) return const {};

    final open = <String>{};
    final ports = game.worldState.portsByProvinceSeaboard;
    for (final seaZoneId in touching) {
      final localSea = seaZoneId.contains('|')
          ? seaZoneId.split('|').last
          : seaZoneId;
      final alreadyPorted =
          ports.containsKey('$prefixedProvinceId|$seaZoneId') ||
          ports.containsKey('$prefixedProvinceId|$localSea') ||
          ports.containsKey('$localProvinceId|$seaZoneId') ||
          ports.containsKey('$localProvinceId|$localSea');
      if (!alreadyPorted) open.add(seaZoneId);
    }
    return open;
  }

  /// True when [prefixedProvinceId] has any seaboard port registered.
  static bool provinceHasAnyPort({
    required ct_models.Game game,
    required String prefixedProvinceId,
  }) {
    final localProvinceId = ProvinceId.localIdFrom(prefixedProvinceId);
    final prefix = '$prefixedProvinceId|';
    final localPrefix = '$localProvinceId|';
    return game.worldState.portsByProvinceSeaboard.keys.any(
      (key) => key.startsWith(prefix) || key.startsWith(localPrefix),
    );
  }

  static ProvinceInlineActionState compute({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required PlayerView playerView,
    PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
    MapTopology? topology,
    ct_models.Orders currentOrders = const ct_models.Orders(),
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    final state = GameMapAreaProvinceActionStatesAssignable.compute(
      game: game,
      humanPlayerId: humanPlayerId,
      selectedTileKey: selectedTileKey,
      playerView: playerView,
      workTarget: kWorkTargetBuildPort,
      workTargetSelectionCache: workTargetSelectionCache,
      topology: topology,
      currentOrders: currentOrders,
      tileMapByRegion: tileMapByRegion,
      passesTileGate: () => tileCanConceivablyTakeBuildPortStep(
        game: game,
        humanPlayerId: humanPlayerId,
        selectedTileKey: selectedTileKey,
        topology: topology,
        tileMapByRegion: tileMapByRegion,
      ),
    );
    if (!state.showIcon && !state.enabled && !state.hasMatchingUnits) {
      return GameMapAreaProvinceActionStatesAssignable.kHidden;
    }
    return state;
  }
}
