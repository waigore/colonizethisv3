// Map extraction disc maps for disconnected improved tiles (Refs #4151).

import 'package:colonizethis_data/colonizethis_data.dart'
    show kTechIdMoldboardPlow;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show ConnectivityResult;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/providers/map_view_provider_extraction.dart';

import 'map_view_provider_extraction_support.dart';

void main() {
  suppressLogsForTests();

  group('mapViewBuildResourceExtractionMaps (Refs #4151)', () {
    test('disconnected improved tile gets E=0 and B=production', () {
      final game = mapViewExtractionGameWithImprovedTile(
        improvedTileKey: mapViewExtractionDisconnectedTile,
        improvementLevel: 2,
      );
      final maps = mapViewExtractionBuildMaps(game);

      expect(maps.unitsByTile[mapViewExtractionDisconnectedTile], 2);
      expect(maps.effectiveUnitsByTile[mapViewExtractionDisconnectedTile], 0);
      expect(maps.blockedUnitsByTile[mapViewExtractionDisconnectedTile], 2);
      expect(
        maps.capitalLinkDisconnectedTileKeys,
        contains(mapViewExtractionDisconnectedTile),
      );
    });

    test(
      'disconnected tile switches to E=F when connectivity includes tile',
      () {
        final game = mapViewExtractionGameWithImprovedTile(
          improvedTileKey: mapViewExtractionDisconnectedTile,
          improvementLevel: 2,
        );
        final player = game.players.first;
        final tileMapByRegion = mapViewExtractionTileMapByRegion();
        final disconnected = mapViewBuildResourceExtractionMaps(
          game: game,
          mapPlayer: player,
          tileMapByRegion: tileMapByRegion,
          connectivityForHuman: const ConnectivityResult(connected: {}),
        );
        expect(
          disconnected.effectiveUnitsByTile[mapViewExtractionDisconnectedTile],
          0,
        );
        expect(
          disconnected.blockedUnitsByTile[mapViewExtractionDisconnectedTile],
          2,
        );

        final connected = mapViewBuildResourceExtractionMaps(
          game: game,
          mapPlayer: player,
          tileMapByRegion: tileMapByRegion,
          connectivityForHuman: ConnectivityResult(
            connected: {mapViewExtractionDisconnectedTile},
            pathTransportCap: {mapViewExtractionDisconnectedTile: 4},
            connectedByRoadRule: {mapViewExtractionDisconnectedTile},
          ),
        );
        expect(
          connected.effectiveUnitsByTile[mapViewExtractionDisconnectedTile],
          2,
        );
        expect(
          connected.blockedUnitsByTile[mapViewExtractionDisconnectedTile],
          0,
        );
      },
    );

    test('capital-connected improved tile keeps effective discs', () {
      const tileKey = 'oldWorld|p1|1|0';
      final game = Game(
        id: 'g_map_discs_connected',
        capitalTileGrainBonusPerTurn: 0,
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: mapViewExtractionProvinceId,
                regionId: 'oldWorld',
                ownerId: mapViewExtractionOwnerId,
                townDevelopmentLevel: 4,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileState: TileMapState()
              .setImprovement(tileKey, 2)
              .setRoadLevel(tileKey, 4),
          resourceByTileKey: const {tileKey: 'grain'},
          tileKeysByRegionAndProvince: const {
            'oldWorld': {
              mapViewExtractionProvinceId: [tileKey],
            },
          },
        ),
        players: [
          Player(
            id: mapViewExtractionOwnerId,
            displayName: 'GP',
            isHuman: true,
            capitalProvinceId: mapViewExtractionProvinceId,
            capitalTile: const CapitalTile(
              regionId: 'oldWorld',
              provinceId: mapViewExtractionProvinceId,
              x: 1,
              y: 0,
            ),
            techUnlocked: const {kTechIdMoldboardPlow: true},
          ),
        ],
      );
      final maps = mapViewExtractionBuildMaps(game);

      expect(maps.effectiveUnitsByTile[tileKey], 2);
      expect(maps.blockedUnitsByTile[tileKey], 0);
      expect(maps.capitalLinkDisconnectedTileKeys.contains(tileKey), isFalse);
    });

    test('unimproved disconnected tile omits discs', () {
      final game = mapViewExtractionGameWithImprovedTile(
        improvedTileKey: mapViewExtractionDisconnectedTile,
        improvementLevel: 0,
      );
      final maps = mapViewExtractionBuildMaps(game);

      expect(
        maps.unitsByTile.containsKey(mapViewExtractionDisconnectedTile),
        isFalse,
      );
      expect(
        maps.effectiveUnitsByTile.containsKey(mapViewExtractionDisconnectedTile),
        isFalse,
      );
      expect(
        maps.blockedUnitsByTile.containsKey(mapViewExtractionDisconnectedTile),
        isFalse,
      );
      expect(
        maps.capitalLinkDisconnectedTileKeys,
        contains(mapViewExtractionDisconnectedTile),
      );
    });
  });

  group('mapViewExtractionMapsForShell (Refs #4370)', () {
    test('omits hatch keys in global observe and keeps discs', () {
      const built = MapResourceExtractionMaps(
        unitsByTile: {mapViewExtractionDisconnectedTile: 2},
        effectiveUnitsByTile: {mapViewExtractionDisconnectedTile: 0},
        blockedUnitsByTile: {mapViewExtractionDisconnectedTile: 2},
        capitalLinkDisconnectedTileKeys: {mapViewExtractionDisconnectedTile},
      );
      final observe = mapViewExtractionMapsForShell(
        built: built,
        panelPlayerId: null,
      );
      expect(observe.capitalLinkDisconnectedTileKeys, isEmpty);
      expect(observe.unitsByTile[mapViewExtractionDisconnectedTile], 2);
      expect(observe.blockedUnitsByTile[mapViewExtractionDisconnectedTile], 2);
    });

    test('keeps hatch keys when a viewing GP is present', () {
      const built = MapResourceExtractionMaps(
        unitsByTile: {mapViewExtractionDisconnectedTile: 2},
        effectiveUnitsByTile: {mapViewExtractionDisconnectedTile: 0},
        blockedUnitsByTile: {mapViewExtractionDisconnectedTile: 2},
        capitalLinkDisconnectedTileKeys: {mapViewExtractionDisconnectedTile},
      );
      final play = mapViewExtractionMapsForShell(
        built: built,
        panelPlayerId: mapViewExtractionOwnerId,
      );
      expect(
        play.capitalLinkDisconnectedTileKeys,
        contains(mapViewExtractionDisconnectedTile),
      );
      expect(identical(play, built), isTrue);
    });
  });
}
