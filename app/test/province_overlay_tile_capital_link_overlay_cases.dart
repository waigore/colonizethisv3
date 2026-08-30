// Overlay/golden pumps for MAP20001 tile capital-link pins (Refs #4305, #4642).

import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'province_overlay_test_harness.dart';
import 'province_overlay_tile_capital_link_test_fixtures.dart';

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
    name: 'default shows stranded capital link without 0 of F',
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
    extractionSnippet: null,
    expectNoCapitalLink: false,
    expectNoExtraction: true,
  ),
  (
    name: 'default omits Connected and E of F for yielding tile',
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
    capitalLinkSnippet: null,
    extractionSnippet: null,
    expectNoCapitalLink: true,
    expectNoExtraction: true,
  ),
  (
    name: 'default omits path-capped Connected and E of F',
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
    capitalLinkSnippet: null,
    extractionSnippet: null,
    expectNoCapitalLink: true,
    expectNoExtraction: true,
  ),
  (
    name: 'default omits stranded line when F is zero',
    remoteImprovementLevel: 0,
    remoteRoadLevel: 0,
    displayId: kTileCapitalLinkRemoteProvinceId,
    selectedTileKey: kTileCapitalLinkRemoteTile,
    tileConnectivity: const ProvinceTileConnectivityDisplay(
      capitalConnected: false,
    ),
    capitalLinkSnippet: null,
    extractionSnippet: null,
    expectNoCapitalLink: true,
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
