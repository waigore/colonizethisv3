// Case bodies for `colonial_naval_scoring_branches_test.dart` (Refs #4079 Slice C).
// Move / mission scoring and adjacency predicate pins.

import 'package:colonizethis_ai/src/planning/colonial_naval_scoring.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'colonial_naval_scoring_branches_support.dart';

void registerColonialNavalScoringBranchesScoringCasesTail() {
  group('colonialNavalMoveScore (dock branches)', () {
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
