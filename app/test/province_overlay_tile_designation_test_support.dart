// Shared helpers for province overlay tile designation tests (Refs #4305).

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart' show buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show demoGameForOverlay, demoRegionForOverlay;

import 'app_shell_harness.dart';
import 'province_overlay_test_harness.dart';

final CapitalTile provinceOverlayDesignationSentinelCapital = CapitalTile(
  regionId: 'oldWorld',
  provinceId: 'oldWorld|__sentinel_capital__',
  x: 9991,
  y: 9992,
);

CapitalTile provinceOverlayCapitalTileFromKey(String tileKey) {
  final parts = tileKey.split('|');
  return CapitalTile(
    regionId: parts[0],
    provinceId: '${parts[0]}|${parts[1]}',
    x: int.parse(parts[parts.length - 2]),
    y: int.parse(parts.last),
  );
}

Game provinceOverlayWithoutMatchingCapitals(Game g) => g.copyWith(
  players: g.players
      .map((p) => p.copyWith(capitalTile: provinceOverlayDesignationSentinelCapital))
      .toList(),
  minorNations: g.minorNations
      .map((m) => m.copyWith(capitalTile: provinceOverlayDesignationSentinelCapital))
      .toList(),
  tribes: g.tribes
      .map((t) => t.copyWith(capitalTile: provinceOverlayDesignationSentinelCapital))
      .toList(),
);

Game provinceOverlayWithProvinceTownTile(
  Game g,
  String provinceId,
  String townTileKey,
) {
  final ws = g.worldState;
  final provinces = ws.oldWorld.provinces
      .map((p) => p.id == provinceId ? p.copyWith(townTileKey: townTileKey) : p)
      .toList();
  return g.copyWith(
    worldState: ws.copyWith(
      oldWorld: RegionData(provinces: provinces, units: ws.oldWorld.units),
    ),
  );
}

Game provinceOverlayWithFirstPlayerCapitalTile(Game g, String tileKey) {
  final cap = provinceOverlayCapitalTileFromKey(tileKey);
  return g.copyWith(
    players: <Player>[
      g.players.first.copyWith(
        capitalTile: cap,
        capitalProvinceId: cap.provinceId,
      ),
      ...g.players.skip(1),
    ],
  );
}

String provinceOverlayProvinceDisplayName(Game g, String provinceId) {
  for (final p in g.worldState.oldWorld.provinces) {
    if (p.id == provinceId) return p.displayName ?? provinceId;
  }
  return provinceId;
}

Widget provinceOverlayDesignationGoldenHost({
  required Game game,
  required RegionMapViewData region,
  required String displayId,
  required Key boundaryKey,
  String? selectedTileKey,
}) {
  final humanPlayerId = game.players.first.id;
  final playerView = buildPlayerView(game, const MapTopology(), humanPlayerId);
  return buildAppShell(
    child: Scaffold(
      body: Center(
        child: RepaintBoundary(
          key: boundaryKey,
          child: SizedBox(
            width: 460,
            height: 900,
            child: ProvinceSeaZoneDetailOverlay(
              game: game,
              region: region,
              displayId: displayId,
              selectedTileKey: selectedTileKey,
              humanPlayerId: humanPlayerId,
              playerView: playerView,
              draftOrders: const Orders(),
            ),
          ),
        ),
      ),
    ),
  );
}

RegionMapViewData provinceOverlayRegionWith({
  required TileVisibility Function(CellViewData) visibilityForCell,
}) {
  final base = demoRegionForOverlay;
  final cells = base.cells
      .map(
        (c) => CellViewData(
          x: c.x,
          y: c.y,
          regionCellId: c.regionCellId,
          isSea: c.isSea,
          terrainTypeId: c.terrainTypeId,
          terrainType: c.terrainType,
          resourceId: c.resourceId,
          ownerFactionId: c.ownerFactionId,
          provinceDisplayName: c.provinceDisplayName,
          improvementLevel: c.improvementLevel,
          roadLevel: c.roadLevel,
          visibility: visibilityForCell(c),
        ),
      )
      .toList();
  return RegionMapViewData(
    regionId: base.regionId,
    width: base.width,
    height: base.height,
    cellSize: base.cellSize,
    cells: cells,
    capitalMarkers: base.capitalMarkers,
    portMarkers: base.portMarkers,
    factionColors: base.factionColors,
    greatPowerFactionIds: base.greatPowerFactionIds,
    terrainColors: base.terrainColors,
    unitMarkers: base.unitMarkers,
  );
}

List<String> provinceOverlayTileTextDataInOrder(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .toList(growable: false);
}

Future<void> pumpProvinceOverlayDesignation(
  WidgetTester tester, {
  required Game game,
  required String provinceId,
  required String tileKey,
  RegionMapViewData? region,
}) async {
  await tester.pumpWidget(
    buildProvinceOverlayDarkThemeShell(
      game: game,
      region: region ?? demoRegionForOverlay,
      displayId: provinceId,
      selectedTileKey: tileKey,
      playerView: demoOverlayPlayerView(game),
      draftOrders: const Orders(),
    ),
  );
  await tester.pumpAndSettle();
}

Game get provinceOverlayDesignationDemoGame => demoGameForOverlay;

RegionMapViewData get provinceOverlayDesignationDemoRegion => demoRegionForOverlay;
