// Tile capital-link and per-tile extraction rows on MAP20001 (Refs #4149).

import 'package:colonizethis_app/core/services/game_service/game_service.dart'
    show GameMapData;
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show ProvinceTileConnectivityDisplay;
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_tile_section_labels.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show
        MapTopology,
        Resource,
        TileMapResult,
        TopologyNode,
        TopologyNodeType,
        kTechIdMoldboardPlow;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show ConnectivityResult, buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'golden_capture_harness.dart';
import 'province_overlay_test_harness.dart';

void main() {
  suppressLogsForTests();

  const provinceId = 'oldWorld|p1';
  const remoteProvinceId = 'oldWorld|p2';
  const capitalTile = 'oldWorld|p1|0|0';
  const remoteTile = 'oldWorld|p2|1|0';
  const humanId = 'gp1';

  GameMapData mapDataForTwoTileProvince() {
    final tileMap = TileMapResult(
      width: 2,
      height: 1,
      grid: const [
        ['p1', 'p2'],
      ],
      resourceGrid: const [
        [Resource.grain, Resource.grain],
      ],
    );
    return (
      combinedTopology: const MapTopology(
        nodes: [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'p2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [],
      ),
      tileMapByRegion: {'oldWorld': tileMap},
      topologyByRegion: const <String, MapTopology>{},
      warpLinks: null,
    );
  }

  Game gameWithRemoteImprovedTile({
    required int remoteImprovementLevel,
    required int remoteRoadLevel,
  }) {
    return Game(
      id: 'g_tile_capital_link',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [
            Province(
              id: provinceId,
              regionId: 'oldWorld',
              ownerId: humanId,
              townDevelopmentLevel: 4,
              townTileKey: capitalTile,
            ),
            Province(
              id: remoteProvinceId,
              regionId: 'oldWorld',
              ownerId: humanId,
              townDevelopmentLevel: 4,
              townTileKey: remoteTile,
            ),
          ],
        ),
        newWorld: const RegionData(),
        tileState: TileMapState()
            .setImprovement(capitalTile, 1)
            .setRoadLevel(capitalTile, 4)
            .setImprovement(remoteTile, remoteImprovementLevel)
            .setRoadLevel(remoteTile, remoteRoadLevel),
        resourceByTileKey: const {
          capitalTile: 'grain',
          remoteTile: 'grain',
        },
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            provinceId: [capitalTile],
            remoteProvinceId: [remoteTile],
          },
        },
      ),
      players: [
        Player(
          id: humanId,
          displayName: 'Human',
          isHuman: true,
          capitalProvinceId: provinceId,
          capitalTile: const CapitalTile(
            regionId: 'oldWorld',
            provinceId: provinceId,
            x: 0,
            y: 0,
          ),
          techUnlocked: const {kTechIdMoldboardPlow: true},
        ),
      ],
    );
  }

  RegionMapViewData regionForGame(Game game) {
    final cells = <CellViewData>[
      CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        terrainTypeId: 'plains',
        resourceId: 'grain',
        visibility: TileVisibility.visible,
      ),
      CellViewData(
        x: 1,
        y: 0,
        regionCellId: 'p2',
        isSea: false,
        terrainTypeId: 'plains',
        resourceId: 'grain',
        visibility: TileVisibility.visible,
      ),
    ];
    return RegionMapViewData(
      regionId: 'oldWorld',
      width: 2,
      height: 1,
      cellSize: 16,
      cells: cells,
      capitalMarkers: const [],
      portMarkers: const [],
      factionColors: const {},
      greatPowerFactionIds: const {},
      terrainColors: const {},
      provincePoliticalOwnerByPrefixedProvinceId: const {
        provinceId: humanId,
        remoteProvinceId: humanId,
      },
    );
  }

  group('provinceTileConnectivityDisplayPreview (Refs #4149)', () {
    test('disconnected improved tile reports 0 of F', () {
      final game = gameWithRemoteImprovedTile(
        remoteImprovementLevel: 3,
        remoteRoadLevel: 0,
      );
      final preview = provinceTileConnectivityDisplayPreview(
        game: game,
        humanPlayerId: humanId,
        provinceId: remoteProvinceId,
        selectedTileKey: remoteTile,
        mapData: mapDataForTwoTileProvince(),
        isSeaZoneContext: false,
        tileIsSea: false,
        tileRevealed: true,
        connectivityForHuman: const ConnectivityResult(
          connected: {capitalTile},
        ),
      );
      expect(preview, isNotNull);
      expect(preview!.capitalConnected, isFalse);
      expect(preview.showExtractionRow, isTrue);
      expect(preview.extractionEffective, 0);
      expect(preview.extractionFull, 3);
    });

    test('connected capital tile reports E equals F', () {
      final game = gameWithRemoteImprovedTile(
        remoteImprovementLevel: 2,
        remoteRoadLevel: 4,
      );
      final preview = provinceTileConnectivityDisplayPreview(
        game: game,
        humanPlayerId: humanId,
        provinceId: provinceId,
        selectedTileKey: capitalTile,
        mapData: mapDataForTwoTileProvince(),
        isSeaZoneContext: false,
        tileIsSea: false,
        tileRevealed: true,
        connectivityForHuman: const ConnectivityResult(
          connected: {capitalTile},
          pathTransportCap: {capitalTile: 4},
          connectedByRoadRule: {capitalTile},
        ),
      );
      expect(preview, isNotNull);
      expect(preview!.capitalConnected, isTrue);
      expect(preview.showExtractionRow, isTrue);
      expect(preview.extractionEffective, preview.extractionFull);
      expect(preview.extractionFull, 1);
    });

    test('path-capped connected tile reports E less than F', () {
      final base = gameWithRemoteImprovedTile(
        remoteImprovementLevel: 3,
        remoteRoadLevel: 4,
      );
      final game = base.copyWith(
        worldState: base.worldState.copyWith(
          tileState: TileMapState()
              .setImprovement(capitalTile, 3)
              .setRoadLevel(capitalTile, 4)
              .setImprovement(remoteTile, 3)
              .setRoadLevel(remoteTile, 4),
        ),
      );
      final preview = provinceTileConnectivityDisplayPreview(
        game: game,
        humanPlayerId: humanId,
        provinceId: provinceId,
        selectedTileKey: capitalTile,
        mapData: mapDataForTwoTileProvince(),
        isSeaZoneContext: false,
        tileIsSea: false,
        tileRevealed: true,
        connectivityForHuman: const ConnectivityResult(
          connected: {capitalTile},
          pathTransportCap: {capitalTile: 1},
          connectedByRoadRule: {capitalTile},
        ),
      );
      expect(preview, isNotNull);
      expect(preview!.capitalConnected, isTrue);
      expect(preview.showExtractionRow, isTrue);
      expect(preview.extractionFull, 3);
      expect(preview.extractionEffective, 1);
      expect(preview.extractionEffective! < preview.extractionFull!, isTrue);
    });

    test('unimproved disconnected tile omits extraction row', () {
      final game = gameWithRemoteImprovedTile(
        remoteImprovementLevel: 0,
        remoteRoadLevel: 0,
      );
      final preview = provinceTileConnectivityDisplayPreview(
        game: game,
        humanPlayerId: humanId,
        provinceId: remoteProvinceId,
        selectedTileKey: remoteTile,
        mapData: mapDataForTwoTileProvince(),
        isSeaZoneContext: false,
        tileIsSea: false,
        tileRevealed: true,
        connectivityForHuman: const ConnectivityResult(
          connected: {capitalTile},
        ),
      );
      expect(preview, isNotNull);
      expect(preview!.capitalConnected, isFalse);
      expect(preview.showExtractionRow, isFalse);
      expect(preview.extractionEffective, isNull);
      expect(preview.extractionFull, isNull);
    });

    test('returns null for sea-zone context', () {
      final game = gameWithRemoteImprovedTile(
        remoteImprovementLevel: 3,
        remoteRoadLevel: 0,
      );
      final preview = provinceTileConnectivityDisplayPreview(
        game: game,
        humanPlayerId: humanId,
        provinceId: remoteProvinceId,
        selectedTileKey: remoteTile,
        mapData: mapDataForTwoTileProvince(),
        isSeaZoneContext: true,
        tileIsSea: false,
        tileRevealed: true,
        connectivityForHuman: const ConnectivityResult(
          connected: {capitalTile},
        ),
      );
      expect(preview, isNull);
    });

    test('returns null for unrevealed tile', () {
      final game = gameWithRemoteImprovedTile(
        remoteImprovementLevel: 3,
        remoteRoadLevel: 0,
      );
      final preview = provinceTileConnectivityDisplayPreview(
        game: game,
        humanPlayerId: humanId,
        provinceId: remoteProvinceId,
        selectedTileKey: remoteTile,
        mapData: mapDataForTwoTileProvince(),
        isSeaZoneContext: false,
        tileIsSea: false,
        tileRevealed: false,
        connectivityForHuman: const ConnectivityResult(
          connected: {capitalTile},
        ),
      );
      expect(preview, isNull);
    });

    test('returns null for sea tile', () {
      final game = gameWithRemoteImprovedTile(
        remoteImprovementLevel: 3,
        remoteRoadLevel: 0,
      );
      final preview = provinceTileConnectivityDisplayPreview(
        game: game,
        humanPlayerId: humanId,
        provinceId: remoteProvinceId,
        selectedTileKey: remoteTile,
        mapData: mapDataForTwoTileProvince(),
        isSeaZoneContext: false,
        tileIsSea: true,
        tileRevealed: true,
        connectivityForHuman: const ConnectivityResult(
          connected: {capitalTile},
        ),
      );
      expect(preview, isNull);
    });

    test('returns null for foreign-owned province', () {
      final game = gameWithRemoteImprovedTile(
        remoteImprovementLevel: 2,
        remoteRoadLevel: 0,
      ).copyWith(
        worldState: gameWithRemoteImprovedTile(
          remoteImprovementLevel: 2,
          remoteRoadLevel: 0,
        ).worldState.copyWith(
          oldWorld: RegionData(
            provinces: [
              Province(
                id: provinceId,
                regionId: 'oldWorld',
                ownerId: humanId,
                townDevelopmentLevel: 4,
              ),
              Province(
                id: remoteProvinceId,
                regionId: 'oldWorld',
                ownerId: 'gp2',
                townDevelopmentLevel: 4,
              ),
            ],
          ),
        ),
      );
      final preview = provinceTileConnectivityDisplayPreview(
        game: game,
        humanPlayerId: humanId,
        provinceId: remoteProvinceId,
        selectedTileKey: remoteTile,
        mapData: mapDataForTwoTileProvince(),
        isSeaZoneContext: false,
        tileIsSea: false,
        tileRevealed: true,
      );
      expect(preview, isNull);
    });
  });

  group('ProvinceSeaZoneDetailOverlay tile capital-link UI (Refs #4149)', () {
    testWidgets('shows not-connected and 0 of F for disconnected tile', (
      WidgetTester tester,
    ) async {
      final game = gameWithRemoteImprovedTile(
        remoteImprovementLevel: 3,
        remoteRoadLevel: 0,
      );
      const preview = ProvinceTileConnectivityDisplay(
        capitalConnected: false,
        extractionEffective: 0,
        extractionFull: 3,
      );
      await pumpProvinceOverlayAtDarkTheme(
        tester,
        game: game,
        displayId: remoteProvinceId,
        region: regionForGame(game),
        selectedTileKey: remoteTile,
        humanPlayerId: humanId,
        playerView: demoOverlayPlayerView(game),
        tileConnectivity: preview,
      );
      expect(
        find.textContaining('Capital link: Not connected'),
        findsOneWidget,
      );
      expect(find.textContaining('Extraction from this tile: 0 of 3'),
          findsOneWidget);
    });

    testWidgets('shows path-capped E of F for connected tile', (
      WidgetTester tester,
    ) async {
      final game = gameWithRemoteImprovedTile(
        remoteImprovementLevel: 3,
        remoteRoadLevel: 4,
      );
      const preview = ProvinceTileConnectivityDisplay(
        capitalConnected: true,
        pathTransportLevel: 1,
        extractionEffective: 1,
        extractionFull: 3,
      );
      await pumpProvinceOverlayAtDarkTheme(
        tester,
        game: game,
        displayId: provinceId,
        region: regionForGame(game),
        selectedTileKey: capitalTile,
        humanPlayerId: humanId,
        playerView: demoOverlayPlayerView(game),
        tileConnectivity: preview,
      );
      expect(find.textContaining('Capital link: Connected'), findsOneWidget);
      expect(find.textContaining('Extraction from this tile: 1 of 3'),
          findsOneWidget);
    });

    testWidgets('omits extraction row when F is zero', (
      WidgetTester tester,
    ) async {
      final game = gameWithRemoteImprovedTile(
        remoteImprovementLevel: 0,
        remoteRoadLevel: 0,
      );
      const preview = ProvinceTileConnectivityDisplay(
        capitalConnected: false,
      );
      await pumpProvinceOverlayAtDarkTheme(
        tester,
        game: game,
        displayId: remoteProvinceId,
        region: regionForGame(game),
        selectedTileKey: remoteTile,
        humanPlayerId: humanId,
        playerView: demoOverlayPlayerView(game),
        tileConnectivity: preview,
      );
      expect(
        find.textContaining('Capital link: Not connected'),
        findsOneWidget,
      );
      expect(find.textContaining('Extraction from this tile:'), findsNothing);
    });

    testWidgets('omits rows when tileConnectivity is null', (
      WidgetTester tester,
    ) async {
      final game = gameWithRemoteImprovedTile(
        remoteImprovementLevel: 3,
        remoteRoadLevel: 0,
      );
      await pumpProvinceOverlayAtDarkTheme(
        tester,
        game: game,
        displayId: remoteProvinceId,
        region: regionForGame(game),
        selectedTileKey: remoteTile,
        humanPlayerId: humanId,
        playerView: demoOverlayPlayerView(game),
      );
      expect(find.textContaining('Capital link:'), findsNothing);
      expect(find.textContaining('Extraction from this tile:'), findsNothing);
    });
  });

  group('ProvinceSeaZoneDetailOverlay tile capital-link goldens (Refs #4149)', () {
    Future<void> pumpTileConnectivityGolden(
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
        humanId,
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
              region: regionForGame(game),
              displayId: displayId,
              selectedTileKey: selectedTileKey,
              humanPlayerId: humanId,
              playerView: playerView,
              draftOrders: const Orders(),
              tileConnectivity: tileConnectivity,
            ),
          ),
        ),
      );
      await pumpForGolden(tester);
    }

    testWidgets('golden: disconnected tile shows capital link and 0 of F', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>(
        'province_overlay_tile_capital_link_disconnected_golden',
      );
      final game = gameWithRemoteImprovedTile(
        remoteImprovementLevel: 3,
        remoteRoadLevel: 0,
      );
      await pumpTileConnectivityGolden(
        tester,
        boundaryKey: boundaryKey,
        game: game,
        displayId: remoteProvinceId,
        selectedTileKey: remoteTile,
        tileConnectivity: const ProvinceTileConnectivityDisplay(
          capitalConnected: false,
          extractionEffective: 0,
          extractionFull: 3,
        ),
      );
      expect(
        find.textContaining('Capital link: Not connected'),
        findsOneWidget,
      );
      expect(find.textContaining('Extraction from this tile: 0 of 3'),
          findsOneWidget);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/province_overlay_tile_capital_link_disconnected.png',
        ),
      );
    });

    testWidgets('golden: connected tile shows capital link and E of F', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>(
        'province_overlay_tile_capital_link_connected_golden',
      );
      final game = gameWithRemoteImprovedTile(
        remoteImprovementLevel: 3,
        remoteRoadLevel: 4,
      );
      await pumpTileConnectivityGolden(
        tester,
        boundaryKey: boundaryKey,
        game: game,
        displayId: provinceId,
        selectedTileKey: capitalTile,
        tileConnectivity: const ProvinceTileConnectivityDisplay(
          capitalConnected: true,
          pathTransportLevel: 2,
          extractionEffective: 2,
          extractionFull: 3,
        ),
      );
      expect(find.textContaining('Capital link: Connected'), findsOneWidget);
      expect(find.textContaining('Extraction from this tile: 2 of 3'),
          findsOneWidget);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/province_overlay_tile_capital_link_connected.png',
        ),
      );
    });
  });

  group('tileConnectivityDetailLinesForTests', () {
    test('formats connected and extraction lines', () {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final lines = tileConnectivityDetailLinesForTests(
        l10n: l10n,
        tileConnectivity: const ProvinceTileConnectivityDisplay(
          capitalConnected: true,
          pathTransportLevel: 2,
          extractionEffective: 1,
          extractionFull: 4,
        ),
      );
      expect(lines, [
        'Capital link: Connected (path transport level 2)',
        'Extraction from this tile: 1 of 4',
      ]);
    });
  });
}
