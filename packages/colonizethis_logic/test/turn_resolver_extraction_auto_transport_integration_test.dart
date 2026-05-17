import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'extraction_auto_transport_test_fixtures.dart';

void main() {
  group('Extraction auto-transport (TurnResolver integration)', () {
    test(
      'overseas cargo cap: land grain fully added; overseas sugar capped by home fleet holds',
      () {
        const globalSeed = 7;
        final nwGrid = [
          [Resource.sugarCane, Resource.sugarCane],
          [Resource.sugarCane, Resource.sugarCane],
        ];
        final (:game, :tileMapByRegion) = extractionAutoTransportFixture(
          nwResourceGrid: nwGrid,
          nwImprovementLevel: 1,
          globalGameSeed: globalSeed,
        );
        final topology = crossRegionSeaTopologyForExtractionTests();

        final connectivity = resolveConnectivity(
          game: game,
          tileMapByRegion: tileMapByRegion,
          topology: topology,
        );
        final extraction = computeExtraction(
          game: game,
          tileMapByRegion: tileMapByRegion,
          connectivityResult: connectivity,
          techCapForPlayerAndResource: (playerId, resourceId) {
            final player = game.playerById(playerId);
            return extractionCapForResourceForUnlocked(
              player?.techUnlocked,
              resourceId,
            );
          },
        );
        final overseas = extraction['pl1']!.overseas;
        expect(overseas['sugarCane'], 4);

        final holds = cargoHoldsForHomeFleet(game, 'pl1');
        expect(holds, NavalStatsCatalog.carrack.cargoHold);
        final allocated = allocateOverseasToStockpile(
          overseas,
          cargoHolds: holds,
        );
        expect(allocated['sugarCane'], 3);

        final next = requireTurnResolutionComplete(
          resolveTurnForGame(
            game: game,
            topology: topology,
            orders: const Orders(),
            tileMapByRegion: tileMapByRegion,
            defaultAssignments: const [],
          ),
        );

        expect(next.players.first.stockpile.quantityOf('sugarCane'), 3);
        const shipFood = 2;
        expect(
          next.players.first.stockpile.quantityOf('grain'),
          1000 - shipFood + 1,
        );
      },
    );

    test(
      'overseas priority: cargo cap fills earlier catalog raw materials before later ones',
      () {
        // Two New World raw materials; cotton appears before sugarCane in
        // [CommodityCatalog.all], so cargo fill prefers cotton first.
        const globalSeed = 11;
        final nwGrid = [
          [Resource.cotton, Resource.sugarCane],
          [null, null],
        ];
        final (:game, :tileMapByRegion) = extractionAutoTransportFixture(
          nwResourceGrid: nwGrid,
          nwImprovementLevel: 2,
          globalGameSeed: globalSeed,
          techUnlocked: const {kTechIdCottonPlanting: true, kTechIdSugarPlanting: true},
        );
        final topology = crossRegionSeaTopologyForExtractionTests();

        final connectivity = resolveConnectivity(
          game: game,
          tileMapByRegion: tileMapByRegion,
          topology: topology,
        );
        final extraction = computeExtraction(
          game: game,
          tileMapByRegion: tileMapByRegion,
          connectivityResult: connectivity,
          techCapForPlayerAndResource: (playerId, resourceId) {
            final player = game.playerById(playerId);
            return extractionCapForResourceForUnlocked(
              player?.techUnlocked,
              resourceId,
            );
          },
        );
        final overseas = extraction['pl1']!.overseas;
        expect(overseas['cotton'], 2);
        expect(overseas['sugarCane'], 2);
        final holds = cargoHoldsForHomeFleet(game, 'pl1');
        final allocated = allocateOverseasToStockpile(
          overseas,
          cargoHolds: holds,
        );
        expect(allocated['cotton'], 2);
        expect(allocated['sugarCane'], 1);

        final next = requireTurnResolutionComplete(
          resolveTurnForGame(
            game: game,
            topology: topology,
            orders: const Orders(),
            tileMapByRegion: tileMapByRegion,
            defaultAssignments: const [],
          ),
        );

        expect(next.players.first.stockpile.quantityOf('grain'), 1000 - 2 + 1);
        expect(next.players.first.stockpile.quantityOf('cotton'), 2);
        expect(next.players.first.stockpile.quantityOf('sugarCane'), 1);
      },
    );

    test(
      'naval trade interception reduces overseas additions after cargo cap',
      () {
        const globalSeed = 42;
        final enemyPatrol = Fleet(
          id: 'f_p2_patrol',
          ownerId: 'p2',
          seaZoneId: 'sea1',
          regionId: 'oldWorld',
          shipTypeIds: const ['sloop'],
          mission: FleetMission.patrol,
        );
        final nwGrid = [
          [Resource.sugarCane, Resource.sugarCane],
          [Resource.sugarCane, Resource.sugarCane],
        ];
        final (:game, :tileMapByRegion) = extractionAutoTransportFixture(
          nwResourceGrid: nwGrid,
          nwImprovementLevel: 1,
          extraFleets: [enemyPatrol],
          globalGameSeed: globalSeed,
          relationWithP2: RelationState.atWar,
        );
        final topology = crossRegionSeaTopologyForExtractionTests();

        final connectivity = resolveConnectivity(
          game: game,
          tileMapByRegion: tileMapByRegion,
          topology: topology,
        );
        final extraction = computeExtraction(
          game: game,
          tileMapByRegion: tileMapByRegion,
          connectivityResult: connectivity,
          techCapForPlayerAndResource: (playerId, resourceId) {
            final player = game.playerById(playerId);
            return extractionCapForResourceForUnlocked(
              player?.techUnlocked,
              resourceId,
            );
          },
        );
        final overseas = extraction['pl1']!.overseas;
        final holds = cargoHoldsForHomeFleet(game, 'pl1');
        final allocated = allocateOverseasToStockpile(
          overseas,
          cargoHolds: holds,
        );
        final seed = extractionAutoTransportInterceptionSeed(
          globalGameSeed: globalSeed,
          turnNumber: 0,
          playerId: 'pl1',
        );
        final intercepted = applyTradeInterception(
          game,
          'pl1',
          allocated,
          seed: seed,
        );
        expect(
          intercepted.reducedDelivered.values.fold<int>(0, (a, b) => a + b),
          lessThan(allocated.values.fold<int>(0, (a, b) => a + b)),
        );

        final next = requireTurnResolutionComplete(
          resolveTurnForGame(
            game: game,
            topology: topology,
            orders: const Orders(),
            tileMapByRegion: tileMapByRegion,
            defaultAssignments: const [],
          ),
        );

        final expectedSugar =
            intercepted.reducedDelivered[CommodityCatalog.sugarCane.id] ?? 0;
        expect(
          next.players.first.stockpile.quantityOf('sugarCane'),
          expectedSugar,
        );
      },
    );
  });
}
