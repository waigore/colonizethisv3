// Case bodies for `colonial_naval_scoring_branches_test.dart` (Refs #4079 Slice C).
// Move / mission scoring and adjacency predicate pins.

import 'package:colonizethis_ai/src/planning/colonial_naval_scoring.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'colonial_naval_scoring_branches_support.dart';

void registerColonialNavalScoringBranchesScoringCases() {
  group('colonialNavalMoveScore (dock branches)', () {
    test(
      'dock at New World port returns kColonialNavalMoveDockNewWorldPortScore',
      () {
        const move = NavalMoveOrder(
          fleetId: 'f1',
          destinationPortProvinceId: 'newWorld|colonyA',
        );
        expect(move.isDock, isTrue);
        expect(
          colonialNavalMoveScore(move, colonialNavalScoringBranchesTopology, colonialNavalScoringWithInvadable),
          kColonialNavalMoveDockNewWorldPortScore,
        );
      },
    );

    test(
      'dock at Old World port returns 0 (no colonial bonus)',
      () {
        const move = NavalMoveOrder(
          fleetId: 'f1',
          destinationPortProvinceId: 'oldWorld|home',
        );
        expect(move.isDock, isTrue);
        expect(
          colonialNavalMoveScore(move, colonialNavalScoringBranchesTopology, colonialNavalScoringWithInvadable),
          0,
        );
      },
    );
  });

  group('colonialNavalMoveScore (sea-zone branches)', () {
    test(
      'NW sea adjacent to invadable province returns priority score',
      () {
        expect(
          colonialNavalMoveScore(
            const NavalMoveOrder(
              fleetId: 'f1',
              destinationSeaZoneId: 'newWorld|nwSeaShared',
            ),
            colonialNavalScoringBranchesTopology,
            colonialNavalScoringWithInvadable,
          ),
          kColonialNavalMovePriorityNwSeaZoneScore,
        );
      },
    );

    test(
      'NW sea without invadable summary falls back to NW-sea-zone score',
      () {
        // With no invadable NW provinces, no sea zone is "priority". Any NW
        // sea zone still earns kColonialNavalMoveNwSeaZoneScore. A regression
        // that promoted any NW sea zone to the priority score (or demoted
        // generic NW seas to 0) would fail here.
        expect(
          colonialNavalMoveScore(
            const NavalMoveOrder(
              fleetId: 'f1',
              destinationSeaZoneId: 'newWorld|nwSeaShared',
            ),
            colonialNavalScoringBranchesTopology,
            colonialNavalScoringNoInvadable,
          ),
          kColonialNavalMoveNwSeaZoneScore,
        );
      },
    );

    test(
      'NW sea NOT adjacent to any invadable province returns NW-sea-zone score',
      () {
        // `newWorld|nwSeaIsolated` borders only land, so even with invadable
        // colonies in the summary it is not in the priority set.
        expect(
          colonialNavalMoveScore(
            const NavalMoveOrder(
              fleetId: 'f1',
              destinationSeaZoneId: 'newWorld|nwSeaIsolated',
            ),
            colonialNavalScoringBranchesTopology,
            colonialNavalScoringWithInvadable,
          ),
          kColonialNavalMoveNwSeaZoneScore,
        );
      },
    );

    test(
      'OW sea adjacent to a NW sea zone returns gateway score',
      () {
        expect(
          colonialNavalMoveScore(
            const NavalMoveOrder(
              fleetId: 'f1',
              destinationSeaZoneId: 'oldWorld|owSeaGateway',
            ),
            colonialNavalScoringBranchesTopology,
            colonialNavalScoringWithInvadable,
          ),
          kColonialNavalMoveGatewaySeaZoneScore,
        );
      },
    );

    test(
      'OW sea without any NW sea adjacency returns 0',
      () {
        expect(
          colonialNavalMoveScore(
            const NavalMoveOrder(
              fleetId: 'f1',
              destinationSeaZoneId: 'oldWorld|owSeaInterior',
            ),
            colonialNavalScoringBranchesTopology,
            colonialNavalScoringWithInvadable,
          ),
          0,
        );
      },
    );

    test(
      'null seaZoneId and empty seaZoneId both return 0 (no colonial bonus)',
      () {
        // Naval planner can iterate over draft shapes where neither dock nor
        // sea destination is set; the scorer must short-circuit instead of
        // assigning any positive bonus.
        const moveNull = NavalMoveOrder(fleetId: 'f1');
        expect(moveNull.isDock, isFalse);
        expect(
          colonialNavalMoveScore(moveNull, colonialNavalScoringBranchesTopology, colonialNavalScoringWithInvadable),
          0,
        );
        const moveEmpty = NavalMoveOrder(
          fleetId: 'f1',
          destinationSeaZoneId: '',
        );
        expect(moveEmpty.isDock, isFalse);
        expect(
          colonialNavalMoveScore(moveEmpty, colonialNavalScoringBranchesTopology, colonialNavalScoringWithInvadable),
          0,
        );
      },
    );
  });

  group('colonialNavalMissionScore (target/mission branches)', () {
    test(
      'New World targetPortId returns NW-port mission score',
      () {
        expect(
          colonialNavalMissionScore(
            const NavalMissionOrder(
              fleetId: 'f1',
              mission: 'patrol',
              targetPortId: 'newWorld|colonyA',
            ),
          ),
          kColonialNavalMissionNwPortScore,
        );
      },
    );

    test(
      'Old World targetPortId falls through to mission/province branches',
      () {
        // An OW port mission with no NW province target and a non-beachhead
        // mission must return 0 (no colonial-pressure bonus).
        expect(
          colonialNavalMissionScore(
            const NavalMissionOrder(
              fleetId: 'f1',
              mission: 'patrol',
              targetPortId: 'oldWorld|home',
            ),
          ),
          0,
        );
      },
    );

    test(
      'null/empty targetPortId + NW province returns NW-province score',
      () {
        expect(
          colonialNavalMissionScore(
            const NavalMissionOrder(
              fleetId: 'f1',
              mission: 'patrol',
              targetProvinceId: 'newWorld|colonyA',
            ),
          ),
          kColonialNavalMissionNwProvinceScore,
        );
        // Empty port id must fall through identically to null (the
        // `portId.isNotEmpty` guard in `colonial_naval_scoring.dart`).
        expect(
          colonialNavalMissionScore(
            const NavalMissionOrder(
              fleetId: 'f1',
              mission: 'patrol',
              targetPortId: '',
              targetProvinceId: 'newWorld|colonyA',
            ),
          ),
          kColonialNavalMissionNwProvinceScore,
        );
      },
    );

    test(
      'OW province target without beachhead mission returns 0',
      () {
        expect(
          colonialNavalMissionScore(
            const NavalMissionOrder(
              fleetId: 'f1',
              mission: 'patrol',
              targetProvinceId: 'oldWorld|home',
            ),
          ),
          0,
        );
      },
    );

    test(
      'beachhead mission returns beachhead score regardless of OW target',
      () {
        // A beachhead mission with an OW province target still gets the
        // beachhead score (NW-targeting tests above pin the higher branches).
        expect(
          colonialNavalMissionScore(
            NavalMissionOrder(
              fleetId: 'f1',
              mission: FleetMission.beachhead.name,
              targetProvinceId: 'oldWorld|home',
            ),
          ),
          kColonialNavalMissionBeachheadScore,
        );
        // Beachhead mission with no targets at all also scores at the
        // beachhead floor (no NW match available).
        expect(
          colonialNavalMissionScore(
            NavalMissionOrder(
              fleetId: 'f1',
              mission: FleetMission.beachhead.name,
            ),
          ),
          kColonialNavalMissionBeachheadScore,
        );
      },
    );

    test(
      'non-beachhead mission with no targets returns 0',
      () {
        expect(
          colonialNavalMissionScore(
            const NavalMissionOrder(fleetId: 'f1', mission: 'patrol'),
          ),
          0,
        );
      },
    );
  });

  group('newWorldSeaZonesAdjacentToInvadableProvinces', () {
    test('empty invadable list returns const empty set', () {
      final out = newWorldSeaZonesAdjacentToInvadableProvinces(
        colonialNavalScoringBranchesTopology,
        const <String>[],
      );
      expect(out, isEmpty);
    });

    test(
      'includes shared NW sea once when two invadable provinces border it',
      () {
        // Both `colonyA` and `colonyB` border `newWorld|nwSeaShared`; the
        // result is a Set so the sea zone must appear exactly once. The
        // inland NW land neighbor (non-sea adjacency) and the OW gateway
        // sea (regionId != newWorld) must both be excluded.
        final out = newWorldSeaZonesAdjacentToInvadableProvinces(
          colonialNavalScoringBranchesTopology,
          const <String>['newWorld|colonyA', 'newWorld|colonyB'],
        );
        expect(out, <String>{'newWorld|nwSeaShared'});
      },
    );

    test(
      'filters out OW sea adjacents (only NW seas remain)',
      () {
        // Pin that `regionIdFrom(nb) != kNewWorldRegionId` is correctly
        // applied. We add an invadable NW province that borders an OW sea
        // zone — no NW sea should be returned.
        const topo = MapTopology(
          nodes: [
            TopologyNode(
              id: 'newWorld|cross',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'oldWorld|crossSea',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [
            TopologyEdge(id1: 'newWorld|cross', id2: 'oldWorld|crossSea'),
          ],
        );
        final out = newWorldSeaZonesAdjacentToInvadableProvinces(
          topo,
          const <String>['newWorld|cross'],
        );
        expect(out, isEmpty);
      },
    );

    test(
      'invadable id absent from colonialNavalScoringBranchesTopology contributes nothing',
      () {
        final out = newWorldSeaZonesAdjacentToInvadableProvinces(
          colonialNavalScoringBranchesTopology,
          const <String>['newWorld|ghostProvinceNotInTopology'],
        );
        expect(out, isEmpty);
      },
    );
  });
}
