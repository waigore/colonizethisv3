// Scenario tables and pump helpers for `province_overlay_tile_capital_link_test.dart`
// (Refs #4305 — keeps fixtures module ≤500 physical lines).

import 'package:colonizethis_app/core/services/game_service/game_service.dart'
    show GameMapData;
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show ConnectivityResult, buildPlayerView;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'province_overlay_test_harness.dart';
import 'province_overlay_tile_capital_link_test_fixtures.dart';

typedef TileCapitalLinkPreviewCase = ({
  String name,
  Game Function() buildGame,
  String provinceId,
  String selectedTileKey,
  bool isSeaZoneContext,
  bool tileIsSea,
  bool tileRevealed,
  ConnectivityResult? connectivityForHuman,
  bool expectNull,
  bool? capitalConnected,
  bool? showExtractionRow,
  int? extractionEffective,
  int? extractionFull,
  bool? effectiveLessThanFull,
});

List<TileCapitalLinkPreviewCase> tileCapitalLinkPreviewCases() => [
  (
    name: 'disconnected improved tile reports 0 of F',
    buildGame: () => tileCapitalLinkGame(
      remoteImprovementLevel: 3,
      remoteRoadLevel: 0,
    ),
    provinceId: kTileCapitalLinkRemoteProvinceId,
    selectedTileKey: kTileCapitalLinkRemoteTile,
    isSeaZoneContext: false,
    tileIsSea: false,
    tileRevealed: true,
    connectivityForHuman: const ConnectivityResult(
      connected: {kTileCapitalLinkCapitalTile},
    ),
    expectNull: false,
    capitalConnected: false,
    showExtractionRow: true,
    extractionEffective: 0,
    extractionFull: 3,
    effectiveLessThanFull: null,
  ),
  (
    name: 'connected capital tile reports E equals F',
    buildGame: () => tileCapitalLinkGame(
      remoteImprovementLevel: 2,
      remoteRoadLevel: 4,
    ),
    provinceId: kTileCapitalLinkProvinceId,
    selectedTileKey: kTileCapitalLinkCapitalTile,
    isSeaZoneContext: false,
    tileIsSea: false,
    tileRevealed: true,
    connectivityForHuman: const ConnectivityResult(
      connected: {kTileCapitalLinkCapitalTile},
      pathTransportCap: {kTileCapitalLinkCapitalTile: 4},
      connectedByRoadRule: {kTileCapitalLinkCapitalTile},
    ),
    expectNull: false,
    capitalConnected: true,
    showExtractionRow: true,
    extractionEffective: null,
    extractionFull: 1,
    effectiveLessThanFull: false,
  ),
  (
    name: 'path-capped connected tile reports E less than F',
    buildGame: tileCapitalLinkPathCappedGame,
    provinceId: kTileCapitalLinkProvinceId,
    selectedTileKey: kTileCapitalLinkCapitalTile,
    isSeaZoneContext: false,
    tileIsSea: false,
    tileRevealed: true,
    connectivityForHuman: const ConnectivityResult(
      connected: {kTileCapitalLinkCapitalTile},
      pathTransportCap: {kTileCapitalLinkCapitalTile: 1},
      connectedByRoadRule: {kTileCapitalLinkCapitalTile},
    ),
    expectNull: false,
    capitalConnected: true,
    showExtractionRow: true,
    extractionEffective: 1,
    extractionFull: 3,
    effectiveLessThanFull: true,
  ),
  (
    name: 'unimproved disconnected tile omits extraction row',
    buildGame: () => tileCapitalLinkGame(
      remoteImprovementLevel: 0,
      remoteRoadLevel: 0,
    ),
    provinceId: kTileCapitalLinkRemoteProvinceId,
    selectedTileKey: kTileCapitalLinkRemoteTile,
    isSeaZoneContext: false,
    tileIsSea: false,
    tileRevealed: true,
    connectivityForHuman: const ConnectivityResult(
      connected: {kTileCapitalLinkCapitalTile},
    ),
    expectNull: false,
    capitalConnected: false,
    showExtractionRow: false,
    extractionEffective: null,
    extractionFull: null,
    effectiveLessThanFull: null,
  ),
  (
    name: 'returns null for sea-zone context',
    buildGame: () => tileCapitalLinkGame(
      remoteImprovementLevel: 3,
      remoteRoadLevel: 0,
    ),
    provinceId: kTileCapitalLinkRemoteProvinceId,
    selectedTileKey: kTileCapitalLinkRemoteTile,
    isSeaZoneContext: true,
    tileIsSea: false,
    tileRevealed: true,
    connectivityForHuman: const ConnectivityResult(
      connected: {kTileCapitalLinkCapitalTile},
    ),
    expectNull: true,
    capitalConnected: null,
    showExtractionRow: null,
    extractionEffective: null,
    extractionFull: null,
    effectiveLessThanFull: null,
  ),
  (
    name: 'returns null for unrevealed tile',
    buildGame: () => tileCapitalLinkGame(
      remoteImprovementLevel: 3,
      remoteRoadLevel: 0,
    ),
    provinceId: kTileCapitalLinkRemoteProvinceId,
    selectedTileKey: kTileCapitalLinkRemoteTile,
    isSeaZoneContext: false,
    tileIsSea: false,
    tileRevealed: false,
    connectivityForHuman: const ConnectivityResult(
      connected: {kTileCapitalLinkCapitalTile},
    ),
    expectNull: true,
    capitalConnected: null,
    showExtractionRow: null,
    extractionEffective: null,
    extractionFull: null,
    effectiveLessThanFull: null,
  ),
  (
    name: 'returns null for sea tile',
    buildGame: () => tileCapitalLinkGame(
      remoteImprovementLevel: 3,
      remoteRoadLevel: 0,
    ),
    provinceId: kTileCapitalLinkRemoteProvinceId,
    selectedTileKey: kTileCapitalLinkRemoteTile,
    isSeaZoneContext: false,
    tileIsSea: true,
    tileRevealed: true,
    connectivityForHuman: const ConnectivityResult(
      connected: {kTileCapitalLinkCapitalTile},
    ),
    expectNull: true,
    capitalConnected: null,
    showExtractionRow: null,
    extractionEffective: null,
    extractionFull: null,
    effectiveLessThanFull: null,
  ),
  (
    name: 'returns null for foreign-owned province',
    buildGame: tileCapitalLinkForeignRemoteGame,
    provinceId: kTileCapitalLinkRemoteProvinceId,
    selectedTileKey: kTileCapitalLinkRemoteTile,
    isSeaZoneContext: false,
    tileIsSea: false,
    tileRevealed: true,
    connectivityForHuman: null,
    expectNull: true,
    capitalConnected: null,
    showExtractionRow: null,
    extractionEffective: null,
    extractionFull: null,
    effectiveLessThanFull: null,
  ),
];

typedef TileCapitalLinkOverlayCase = ({
  String name,
  int remoteImprovementLevel,
  int remoteRoadLevel,
  String displayId,
  String selectedTileKey,
  ProvinceTileConnectivityDisplay? tileConnectivity,
  String? capitalLinkSnippet,
  String? extractionSnippet,
  bool expectNoCapitalLink,
  bool expectNoExtraction,
});

List<TileCapitalLinkOverlayCase> tileCapitalLinkOverlayCases() => [
  (
    name: 'shows not-connected and 0 of F for disconnected tile',
    remoteImprovementLevel: 3,
    remoteRoadLevel: 0,
    displayId: kTileCapitalLinkRemoteProvinceId,
    selectedTileKey: kTileCapitalLinkRemoteTile,
    tileConnectivity: const ProvinceTileConnectivityDisplay(
      capitalConnected: false,
      extractionEffective: 0,
      extractionFull: 3,
    ),
    capitalLinkSnippet: 'Capital link: Not connected',
    extractionSnippet: 'Extraction from this tile: 0 of 3',
    expectNoCapitalLink: false,
    expectNoExtraction: false,
  ),
  (
    name: 'shows Connected and E equals F for fully yielding tile',
    remoteImprovementLevel: 2,
    remoteRoadLevel: 4,
    displayId: kTileCapitalLinkProvinceId,
    selectedTileKey: kTileCapitalLinkCapitalTile,
    tileConnectivity: const ProvinceTileConnectivityDisplay(
      capitalConnected: true,
      pathTransportLevel: 4,
      extractionEffective: 1,
      extractionFull: 1,
    ),
    capitalLinkSnippet: 'Capital link: Connected',
    extractionSnippet: 'Extraction from this tile: 1 of 1',
    expectNoCapitalLink: false,
    expectNoExtraction: false,
  ),
  (
    name: 'shows path-capped E of F for connected tile',
    remoteImprovementLevel: 3,
    remoteRoadLevel: 4,
    displayId: kTileCapitalLinkProvinceId,
    selectedTileKey: kTileCapitalLinkCapitalTile,
    tileConnectivity: const ProvinceTileConnectivityDisplay(
      capitalConnected: true,
      pathTransportLevel: 1,
      extractionEffective: 1,
      extractionFull: 3,
    ),
    capitalLinkSnippet: 'Capital link: Connected',
    extractionSnippet: 'Extraction from this tile: 1 of 3',
    expectNoCapitalLink: false,
    expectNoExtraction: false,
  ),
  (
    name: 'omits extraction row when F is zero',
    remoteImprovementLevel: 0,
    remoteRoadLevel: 0,
    displayId: kTileCapitalLinkRemoteProvinceId,
    selectedTileKey: kTileCapitalLinkRemoteTile,
    tileConnectivity: const ProvinceTileConnectivityDisplay(
      capitalConnected: false,
    ),
    capitalLinkSnippet: 'Capital link: Not connected',
    extractionSnippet: null,
    expectNoCapitalLink: false,
    expectNoExtraction: true,
  ),
  (
    name: 'omits rows when tileConnectivity is null',
    remoteImprovementLevel: 3,
    remoteRoadLevel: 0,
    displayId: kTileCapitalLinkRemoteProvinceId,
    selectedTileKey: kTileCapitalLinkRemoteTile,
    tileConnectivity: null,
    capitalLinkSnippet: null,
    extractionSnippet: null,
    expectNoCapitalLink: true,
    expectNoExtraction: true,
  ),
];

Future<void> pumpTileCapitalLinkOverlayCase(
  WidgetTester tester,
  TileCapitalLinkOverlayCase case_,
) async {
  final game = tileCapitalLinkGame(
    remoteImprovementLevel: case_.remoteImprovementLevel,
    remoteRoadLevel: case_.remoteRoadLevel,
  );
  await pumpProvinceOverlayAtDarkTheme(
    tester,
    game: game,
    displayId: case_.displayId,
    region: tileCapitalLinkRegionForGame(game),
    selectedTileKey: case_.selectedTileKey,
    humanPlayerId: kTileCapitalLinkHumanId,
    playerView: demoOverlayPlayerView(game),
    tileConnectivity: case_.tileConnectivity,
  );
}

Future<void> pumpTileCapitalLinkGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Game game,
  required String displayId,
  required String selectedTileKey,
  required ProvinceTileConnectivityDisplay tileConnectivity,
}) async {
  await configureGoldenSurface(tester, size: const Size(600, 1000));
  configureGoldenView(
    tester,
    physicalSize: const Size(600, 1000),
    devicePixelRatio: 1.0,
  );
  final playerView = buildPlayerView(
    game,
    const MapTopology(),
    kTileCapitalLinkHumanId,
  );
  await tester.pumpWidget(
    wrapGoldenBoundary(
      boundaryKey: boundaryKey,
      includeLocalizations: true,
      child: SizedBox(
        width: 460,
        height: 900,
        child: ProvinceSeaZoneDetailOverlay(
          game: game,
          region: tileCapitalLinkRegionForGame(game),
          displayId: displayId,
          selectedTileKey: selectedTileKey,
          humanPlayerId: kTileCapitalLinkHumanId,
          playerView: playerView,
          draftOrders: const Orders(),
          tileConnectivity: tileConnectivity,
        ),
      ),
    ),
  );
  await pumpForGolden(tester);
}
