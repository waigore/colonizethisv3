import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import '../turn_resolver_test_harness.dart';

void registerDiplomacyVictoryCoreTests() {
  group('diplomacy victory', () {
    group('diplomacy victory', () {
      test(
        'join_home_fleet mission moves ships into home fleet and removes fleet',
        () {
          final topology = turnTestOwSeaProvinceTopology();
          final capitalId = turnTestOwProvinceId('P1');
          final homeFleet = turnTestCarrackFleet(
            id: 'fleet_p1',
            seaZoneId: null,
            inPortAtProvinceId: capitalId,
          );
          final otherFleet = turnTestCarrackFleet(
            id: 'f2',
            seaZoneId: null,
            inPortAtProvinceId: capitalId,
            shipTypeIds: const ['fluyte'],
          );
          final game = turnTestOwGame(
            provinces: [
              Province(
                id: capitalId,
                regionId: kRegionOldWorld,
                ownerId: 'p1',
              ),
            ],
            fleets: [homeFleet, otherFleet],
            players: [
              Player(
                id: 'p1',
                displayName: 'A',
                isHuman: true,
                capitalProvinceId: capitalId,
              ),
            ],
          );
          final orders = Orders(
            navalMissionOrdersByPlayerId: {
              'p1': [
                const NavalMissionOrder(
                  fleetId: 'f2',
                  mission: 'join_home_fleet',
                ),
              ],
            },
          );

          final next = resolveTurnComplete(
            game: game,
            topology: topology,
            orders: orders,
            extractedByPlayerId: const {},
            defaultAssignments: const [],
          );

          expect(next.worldState.turnState.turnNumber, 1);
          expect(next.worldState.fleets.length, 1);
          final resultingFleet = next.worldState.fleets.single;
          expect(resultingFleet.id, 'fleet_p1');
          expect(
            resultingFleet.shipTypeIds,
            containsAll(['carrack', 'fluyte']),
          );
        },
      );

      test(
        'blockade order not applied when not at war with province owner',
        () {
          final topology = turnTestOwSeaZoneTopology();
          final game = turnTestOwGame(
            provinces: turnTestOwP1P2Provinces(),
            fleets: [turnTestCarrackFleet()],
            diplomacyRelations: [
              DiplomacyRelation(
                factionId1: 'p1',
                factionId2: 'p2',
                state: RelationState.atPeace,
              ),
            ],
          );
          final orders = Orders(
            navalMissionOrdersByPlayerId: {
              'p1': [
                NavalMissionOrder(
                  fleetId: 'f1',
                  mission: FleetMission.blockade.name,
                  targetProvinceId: turnTestOwProvinceId('P2'),
                ),
              ],
            },
          );
          final next = resolveTurnComplete(
            game: game,
            topology: topology,
            orders: orders,
            extractedByPlayerId: const {},
            defaultAssignments: const [],
          );
          final fleet = next.worldState.fleets.singleWhere((f) => f.id == 'f1');
          expect(fleet.mission, FleetMission.none);
        },
      );

      test('existing blockade cleared when not at war with target owner', () {
        final topology = turnTestOwSeaZoneTopology();
        final game = turnTestOwGame(
          provinces: turnTestOwP1P2Provinces(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: kRegionOldWorld,
              mission: FleetMission.blockade,
              targetProvinceId: turnTestOwProvinceId('P2'),
              shipTypeIds: const ['carrack'],
            ),
          ],
          diplomacyRelations: [
            DiplomacyRelation(
              factionId1: 'p1',
              factionId2: 'p2',
              state: RelationState.atPeace,
            ),
          ],
        );
        final next = resolveTurnComplete(
          game: game,
          topology: topology,
          orders: const Orders(),
          extractedByPlayerId: const {},
          defaultAssignments: const [],
        );
        final fleet = next.worldState.fleets.singleWhere((f) => f.id == 'f1');
        expect(fleet.mission, FleetMission.none);
      });

      test(
        'naval interception phase runs when two at-war fleets in same zone',
        () {
          final topology = turnTestOwSeaZoneTopology();
          final game = turnTestOwGame(
            provinces: const [],
            fleets: [
              Fleet(
                id: 'fleet_p1',
                ownerId: 'p1',
                seaZoneId: 'sea1',
                regionId: kRegionOldWorld,
                shipTypeIds: ['carrack'],
              ),
              Fleet(
                id: 'fleet_p2',
                ownerId: 'p2',
                seaZoneId: 'sea1',
                regionId: kRegionOldWorld,
                shipTypeIds: ['fluyte'],
              ),
            ],
            diplomacyRelations: [
              DiplomacyRelation(
                factionId1: 'p1',
                factionId2: 'p2',
                state: RelationState.atWar,
              ),
            ],
          );
          final next = resolveTurnComplete(
            game: game,
            topology: topology,
            orders: const Orders(),
            extractedByPlayerId: const {},
            defaultAssignments: const [],
          );
          expect(next.worldState.turnState.turnNumber, 1);
          expect(next.worldState.fleets, isNotEmpty);
        },
      );

      test('full turn with buildWork applies work order', () {
        final topology = turnTestOwSingleProvinceTopology();
        final provinceId = turnTestOwProvinceId('P1');
        final tileKey = '$provinceId|0|0';
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeExplorer,
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
        );
        final game = turnTestOwGame(
          provinces: [
            Province(id: provinceId, regionId: kRegionOldWorld, ownerId: 'p1'),
          ],
          units: [unit],
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            'p1': [
              WorkOrder(
                unitId: 'u1',
                target: kWorkTargetProspect,
                targetTileKey: tileKey,
              ),
            ],
          },
        );
        final next = resolveTurnComplete(
          game: game,
          topology: topology,
          orders: orders,
          tileMapByRegion: turnTestSingleTileOwMap('P1'),
          extractedByPlayerId: const {},
          defaultAssignments: const [],
        );
        expect(next.worldState.turnState.turnNumber, 1);
        expect(next.worldState.playerProspectedTiles['p1'], contains(tileKey));
      });
    });
  });
}
