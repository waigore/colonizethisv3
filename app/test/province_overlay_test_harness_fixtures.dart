// Region/game helpers for province overlay test harness (Refs #4734 Slice D).

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Empty 1×1 region used by MAP20001 shortcut callback tests.
RegionMapViewData emptyProvinceOverlayRegion({String regionId = 'oldWorld'}) {
  return RegionMapViewData(
    regionId: regionId,
    width: 1,
    height: 1,
    cellSize: 16,
    cells: const [],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {},
    terrainColors: const {},
    provincePoliticalOwnerByPrefixedProvinceId: const {},
  );
}

/// Returns a province id (`regionId|localId`) owned by [ownerId] in the demo
/// Old World. Province ids in the debug-init game are already prefixed.
String ownedProvinceIdInOldWorld({
  required Game game,
  required String ownerId,
}) {
  for (final province in game.worldState.oldWorld.provinces) {
    if (province.ownerId == ownerId) {
      return province.id;
    }
  }
  fail(
    'Test setup: no province in oldWorld is owned by "$ownerId"; '
    'cannot construct a human-owned province for overlay pins.',
  );
}

/// Extracts `regionId|localProvinceId` from a full tile key.
String provinceIdFromTileKey(String tileKey) {
  final parts = tileKey.split('|');
  return '${parts[0]}|${parts[1]}';
}

/// Lightweight [PlayerView] for demo-overlay pins (Refs #3656).
PlayerView demoOverlayPlayerView(Game game) {
  return buildPlayerView(game, const MapTopology(), game.players.first.id);
}

/// Returns [base] with [roadLevel] applied to [tileKey] in tile state.
Game gameWithRoadLevelOnTile({
  required Game base,
  required String tileKey,
  required int roadLevel,
}) {
  final ws = base.worldState;
  final tileState = ws.tileState.setRoadLevel(tileKey, roadLevel);
  return base.copyWith(worldState: ws.copyWith(tileState: tileState));
}
