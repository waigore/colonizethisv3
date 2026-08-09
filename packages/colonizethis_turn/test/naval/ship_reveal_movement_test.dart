import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/colonizethis_turn_testing.dart';

import '../support/ship_reveal_test_support.dart';
import 'ship_reveal_movement_cases.dart';

void main() {
  group('Naval ship reveal (movement)', () {
    test(
      'ship reveal reveals only coastal tiles and keeps inland tiles unchanged',
      () {
        const nw = shipRevealMovementNw;
        const provinceP1 = '$nw|p1';
        const provinceP2 = '$nw|p2';
        const p1CoastalTile = '$provinceP1|0|0';
        const p1InlandTile = '$provinceP1|0|1';
        const p2CoastalTile = '$provinceP2|2|0';
        const sea2 = '$nw|sea2';
        const sea2WaterA = '$sea2|1|0';
        const sea2WaterB = '$sea2|3|0';

        final revealTopology = shipRevealCoastalInlandTopology(regionId: nw);
        final game = shipRevealCoastalInlandGame(
          id: 'g1',
          regionId: nw,
          provinceP1: provinceP1,
          provinceP2: provinceP2,
          p1CoastalTile: p1CoastalTile,
          p1InlandTile: p1InlandTile,
          p2CoastalTile: p2CoastalTile,
          sea2Bucket: sea2,
          sea2WaterA: sea2WaterA,
          sea2WaterB: sea2WaterB,
          fleetId: 'f1',
        );
        final orders = {
          'gp1': [
            const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea2'),
          ],
        };

        final next = applyNavalMovesAndShipReveal(game, revealTopology, orders);
        final visibility = next.worldState.playerVisibilityByTile['gp1'];

        expect(visibility?[p1CoastalTile], VisibilityLevel.fullyVisible.name);
        expect(visibility?[p2CoastalTile], VisibilityLevel.fullyVisible.name);
        expect(visibility?[p1InlandTile], isNull);
        expect(visibility?[sea2WaterA], VisibilityLevel.fullyVisible.name);
        expect(visibility?[sea2WaterB], VisibilityLevel.fullyVisible.name);
      },
    );

    test('ship reveal stays region-scoped when ids overlap across regions', () {
      const nw = shipRevealMovementNw;
      const ow = shipRevealMovementOw;
      const nwProvince = '$nw|p1';
      const owProvince = '$ow|p1';
      const nwCoastalTile = '$nwProvince|0|0';
      const owTile = '$owProvince|0|0';
      const nwSea2 = '$nw|sea2';
      const nwSea2Tile = '$nwSea2|1|0';

      final revealTopology = shipRevealRegionScopedTopology();
      final game = shipRevealRegionScopedGame(
        nwProvince: nwProvince,
        owProvince: owProvince,
        nwCoastalTile: nwCoastalTile,
        owTile: owTile,
        nwSea2: nwSea2,
        nwSea2Tile: nwSea2Tile,
      );
      final orders = {
        'gp1': [
          const NavalMoveOrder(fleetId: 'f2', destinationSeaZoneId: 'sea2'),
        ],
      };

      final next = applyNavalMovesAndShipReveal(game, revealTopology, orders);
      final visibility = next.worldState.playerVisibilityByTile['gp1'];
      expect(visibility?[nwCoastalTile], VisibilityLevel.fullyVisible.name);
      expect(visibility?[nwSea2Tile], VisibilityLevel.fullyVisible.name);
      expect(visibility?[owTile], isNull);
    });

    test(
      'combined-topology ship reveal uses canonical sea bucket and coastal ring only',
      () {
        final combinedTopology = nwShipRevealCoastalTopology(
          includeSeaFar: true,
        );
        final game = nwShipRevealCoastalGame(
          id: 'gCombined',
          landProvinceBucketKey: NwShipRevealCoastalIds.fullProvinceId,
          landTiles: const [
            NwShipRevealCoastalIds.coastalLand,
            NwShipRevealCoastalIds.inlandLand,
            NwShipRevealCoastalIds.extraLandA,
            NwShipRevealCoastalIds.extraLandB,
          ],
        );

        final ordersOk = {
          'gp1': [
            const NavalMoveOrder(
              fleetId: 'fNw',
              destinationSeaZoneId: NwShipRevealCoastalIds.prefixedDest,
            ),
          ],
        };
        final afterOk = applyNavalMovesAndShipReveal(
          game,
          combinedTopology,
          ordersOk,
        );
        final visOk = afterOk.worldState.playerVisibilityByTile['gp1']!;
        expect(
          visOk[NwShipRevealCoastalIds.coastalLand],
          VisibilityLevel.fullyVisible.name,
        );
        expect(
          visOk[NwShipRevealCoastalIds.inlandLand],
          VisibilityLevel.unknown.name,
        );
        expect(
          visOk[NwShipRevealCoastalIds.seaDestWater],
          VisibilityLevel.fullyVisible.name,
        );
        expect(
          visOk[NwShipRevealCoastalIds.seaDestWaterB],
          VisibilityLevel.fullyVisible.name,
        );

        final ordersBad = {
          'gp1': [
            const NavalMoveOrder(
              fleetId: 'fNw',
              destinationSeaZoneId: NwShipRevealCoastalIds.seaFar,
            ),
          ],
        };
        final afterBad = applyNavalMovesAndShipReveal(
          game,
          combinedTopology,
          ordersBad,
        );
        final visBad = afterBad.worldState.playerVisibilityByTile['gp1']!;
        expect(
          visBad[NwShipRevealCoastalIds.coastalLand],
          VisibilityLevel.unknown.name,
        );
        expect(
          visBad[NwShipRevealCoastalIds.seaDestWater],
          VisibilityLevel.unknown.name,
        );
      },
    );

    test(
      'sequential fleet updates keep later fleet moves valid in same order batch',
      () {
        const ow = shipRevealMovementOw;
        const homePort = '$ow|pHome';
        const seaA = '$ow|seaA';
        const seaB = '$ow|seaB';

        final topology = shipRevealSequentialFleetTopology(
          homePort: homePort,
          seaA: seaA,
          seaB: seaB,
        );
        final game = shipRevealSequentialFleetGame(
          homePort: homePort,
          seaA: seaA,
          seaB: seaB,
        );

        final next = applyNavalMovesAndShipReveal(game, topology, {
          'gp1': [
            const NavalMoveOrder(fleetId: 'fDock', destinationSeaZoneId: seaB),
            const NavalMoveOrder(fleetId: 'fMove', destinationSeaZoneId: seaB),
          ],
        });

        final fleetsById = {
          for (final fleet in next.worldState.fleets) fleet.id: fleet,
        };
        final dockFleet = fleetsById['fDock'];
        final movedFleet = fleetsById['fMove'];

        expect(dockFleet?.seaZoneId, seaB);
        expect(movedFleet?.seaZoneId, seaB);
      },
    );
  });
}
