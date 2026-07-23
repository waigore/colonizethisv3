// Shared OW-capital / topology helpers for units-panel widget test families.
//
// Military and naval supports previously each owned adjacent-province and
// capital-adjacent-sea [MapTopology] builders with the same node/edge shape.
// Civilian mini-games factories also need a common human player + OW capital
// province motif. Keep those here so part files and family supports share one
// source (Refs #4021).
//
// SPEC: SPEC/program/repo-lint.md (approved app/test/support harness list).

import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology, TopologyEdge, TopologyNode, TopologyNodeType;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Human player with an optional OW capital province + capital tile.
Player buildUnitsPanelHumanPlayer({
  required String id,
  String displayName = 'Human',
  String? capitalProvinceId,
  int capitalX = 0,
  int capitalY = 0,
}) {
  if (capitalProvinceId == null) {
    return Player(id: id, displayName: displayName, isHuman: true);
  }
  return Player(
    id: id,
    displayName: displayName,
    isHuman: true,
    capitalProvinceId: capitalProvinceId,
    capitalTile: CapitalTile(
      regionId: 'oldWorld',
      provinceId: capitalProvinceId,
      x: capitalX,
      y: capitalY,
    ),
  );
}

/// Adjacent OW province pair (army move / locate / invasion adjacency).
MapTopology buildUnitsPanelAdjacentOwProvincesTopology({
  String fromProvinceId = 'oldWorld|p2',
  String toProvinceId = 'oldWorld|p3',
  String regionId = 'oldWorld',
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: fromProvinceId,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: toProvinceId,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
    ],
    edges: [TopologyEdge(id1: fromProvinceId, id2: toProvinceId)],
  );
}

/// Human player with capital province id only (military scenario builders).
Player unitsPanelHumanPlayerWithCapital(
  String id,
  String name,
  String capital,
) =>
    Player(
      id: id,
      displayName: name,
      isHuman: true,
      capitalProvinceId: capital,
    );

/// Old-world province owned by [ownerId].
Province unitsPanelOwProvince(
  String id,
  String ownerId, {
  String? displayName,
  String? townTileKey,
}) =>
    Province(
      id: id,
      regionId: 'oldWorld',
      ownerId: ownerId,
      displayName: displayName,
      townTileKey: townTileKey,
    );

/// Regiment [Unit]s stationed in [provinceId].
List<Unit> unitsPanelRegimentsAt(
  List<String> ids,
  String ownerId,
  String provinceId, {
  required String type,
}) =>
    [
      for (final id in ids)
        Unit(
          id: id,
          type: type,
          ownerId: ownerId,
          locationProvinceId: provinceId,
        ),
    ];

/// Land [Army] stationed in the old world.
Army unitsPanelArmy({
  required String id,
  required String ownerId,
  required String stationedProvinceId,
  required List<String> regimentUnitIds,
  bool isHomeArmy = false,
}) =>
    Army(
      id: id,
      ownerId: ownerId,
      regionId: 'oldWorld',
      stationedProvinceId: stationedProvinceId,
      regimentUnitIds: regimentUnitIds,
      isHomeArmy: isHomeArmy,
    );

/// Tile-key lookup map for old-world provinces.
Map<String, Map<String, List<String>>> unitsPanelOwTileKeys(
  Map<String, List<String>> byProvince,
) =>
    {'oldWorld': byProvince};

/// Fully-visible tile keys for [playerId].
Map<String, Map<String, String>> unitsPanelPlayerVisibility(
  String playerId,
  List<String> tiles,
) =>
    {
      playerId: {for (final tile in tiles) tile: 'fullyVisible'},
    };

/// Taps the first [ExpansionTile] in the tree (if any) and settles.
Future<void> expandFirstArmyExpansion(WidgetTester tester) async {
  final tiles = find.byType(ExpansionTile);
  if (tiles.evaluate().isEmpty) {
    return;
  }
  await tester.tap(tiles.first);
  await tester.pumpAndSettle();
}

/// Taps every [ExpansionTile] currently in the tree (settling after each).
Future<void> expandAllArmyExpansions(WidgetTester tester) async {
  final finder = find.byType(ExpansionTile);
  final n = finder.evaluate().length;
  for (var i = 0; i < n; i++) {
    await tester.tap(finder.at(i));
    await tester.pumpAndSettle();
  }
}

/// Capital province adjacent to a named sea zone (naval Combine adjacency).
MapTopology buildUnitsPanelCapitalAdjacentSeaTopology({
  String capitalNodeId = 'oldWorld|cap1',
  String seaZoneId = 'zone_alpha',
  String regionId = 'oldWorld',
  bool includeEdge = true,
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: capitalNodeId,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: seaZoneId,
        regionId: regionId,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [
      if (includeEdge) TopologyEdge(id1: capitalNodeId, id2: seaZoneId),
    ],
  );
}
