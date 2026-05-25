import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/colonial_naval_scoring.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// SPEC: see SPEC/ai/ai-architecture.md § Colonial pressure naval scoring
// and `packages/colonizethis_ai/lib/src/planning/colonial_naval_scoring.dart`.
//
// The existing `colonial_naval_scoring_test.dart` exercises only the happiest
// branches:
//   - NW sea zone outranks Old World sea zone (priority + gateway path).
//   - Gateway OW sea outscores unrelated seas.
//   - NW port `NavalMissionOrder` outranks OW port.
//
// That leaves these regression vectors unpinned today and addressed here
// (Refs #2509 / colonial-support naval prioritization):
//
//   1. `colonialNavalMoveScore` dock branches: NW port dock returns
//      `kColonialNavalMoveDockNewWorldPortScore`; an Old World port dock
//      returns 0 (no colonial bonus despite `isDock`).
//   2. `colonialNavalMoveScore` non-dock null/empty seaId returns 0 (does
//      not crash on uninitialized destinations the way naval planner draft
//      shapes can produce while iterating candidates).
//   3. `colonialNavalMoveScore` non-dock NW sea zone that is **not** priority
//      (either no invadable NW provinces in summary, or NW sea zone is not
//      adjacent to one) returns the lower
//      `kColonialNavalMoveNwSeaZoneScore` rather than the priority score.
//   4. `colonialNavalMoveScore` non-dock Old World sea zone that is **not**
//      gateway (no adjacency to any NW sea zone) returns 0 — a regression
//      that broadened the gateway predicate would lift unrelated OW lanes
//      into the colonial-pressure ranking.
//   5. `colonialNavalMissionScore` falls through Old World port and Old
//      World province to the beachhead fallback. Pin order:
//      NW port > NW province > beachhead > 0.
//   6. `newWorldSeaZonesAdjacentToInvadableProvinces` filters out non-sea
//      adjacents and non-NW seas, dedupes shared neighbors, and returns the
//      empty set when the invadable list is empty.
//   7. `sortNavalMovesForColonialPressure` is stable: score desc, then
//      fleetId asc, then dock-vs-sea key asc.
//   8. `sortNavalMissionsForColonialPressure` is stable: score desc, then
//      fleetId asc, then mission asc, then targetPortId asc, then
//      targetProvinceId asc.
//
// Each test isolates a single branch so a regression that flips one of
// these score/predicate edges fails this file with a focused diagnostic.

void main() {
  // Two NW provinces share a single NW sea zone (`newWorld|nwSeaShared`).
  // `newWorld|nwSeaIsolated` is a NW sea zone with no invadable adjacency.
  // `oldWorld|owSeaInterior` is an OW sea zone with no NW sea adjacency
  // (no gateway bonus). `oldWorld|owSeaGateway` borders `newWorld|nwSeaShared`.
  const topology = MapTopology(
    nodes: [
      TopologyNode(
        id: 'oldWorld|home',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'oldWorld|owSeaInterior',
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: 'oldWorld|owSeaGateway',
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: 'newWorld|nwSeaShared',
        regionId: 'newWorld',
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: 'newWorld|nwSeaIsolated',
        regionId: 'newWorld',
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: 'newWorld|colonyA',
        regionId: 'newWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'newWorld|colonyB',
        regionId: 'newWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'newWorld|inlandLand',
        regionId: 'newWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: [
      // OW interior sea: only land neighbor, no NW sea adjacency.
      TopologyEdge(id1: 'oldWorld|home', id2: 'oldWorld|owSeaInterior'),
      // Gateway OW sea borders the shared NW sea.
      TopologyEdge(id1: 'oldWorld|owSeaGateway', id2: 'newWorld|nwSeaShared'),
      // Two invadable NW provinces both border the same NW sea (dedupe path).
      TopologyEdge(id1: 'newWorld|nwSeaShared', id2: 'newWorld|colonyA'),
      TopologyEdge(id1: 'newWorld|nwSeaShared', id2: 'newWorld|colonyB'),
      // Invadable NW land also borders an inland NW land neighbor (non-sea
      // adjacency must be filtered).
      TopologyEdge(id1: 'newWorld|colonyA', id2: 'newWorld|inlandLand'),
      // Isolated NW sea borders only inland land — not adjacent to any
      // invadable province.
      TopologyEdge(id1: 'newWorld|nwSeaIsolated', id2: 'newWorld|inlandLand'),
    ],
  );

  const colonialWithInvadable = ColonialSummary(
    invadableNewWorldProvinceIdsSorted: <String>[
      'newWorld|colonyA',
      'newWorld|colonyB',
    ],
  );
  const colonialNoInvadable = ColonialSummary();

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
          colonialNavalMoveScore(move, topology, colonialWithInvadable),
          kColonialNavalMoveDockNewWorldPortScore,
        );
      },
    );

    test('dock at Old World port returns 0 (no colonial bonus)', () {
      const move = NavalMoveOrder(
        fleetId: 'f1',
        destinationPortProvinceId: 'oldWorld|home',
      );
      expect(move.isDock, isTrue);
      expect(colonialNavalMoveScore(move, topology, colonialWithInvadable), 0);
    });
  });

  group('colonialNavalMoveScore (sea-zone branches)', () {
    test('NW sea adjacent to invadable province returns priority score', () {
      expect(
        colonialNavalMoveScore(
          const NavalMoveOrder(
            fleetId: 'f1',
            destinationSeaZoneId: 'newWorld|nwSeaShared',
          ),
          topology,
          colonialWithInvadable,
        ),
        kColonialNavalMovePriorityNwSeaZoneScore,
      );
    });

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
            topology,
            colonialNoInvadable,
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
            topology,
            colonialWithInvadable,
          ),
          kColonialNavalMoveNwSeaZoneScore,
        );
      },
    );

    test('OW sea adjacent to a NW sea zone returns gateway score', () {
      expect(
        colonialNavalMoveScore(
          const NavalMoveOrder(
            fleetId: 'f1',
            destinationSeaZoneId: 'oldWorld|owSeaGateway',
          ),
          topology,
          colonialWithInvadable,
        ),
        kColonialNavalMoveGatewaySeaZoneScore,
      );
    });

    test('OW sea without any NW sea adjacency returns 0', () {
      expect(
        colonialNavalMoveScore(
          const NavalMoveOrder(
            fleetId: 'f1',
            destinationSeaZoneId: 'oldWorld|owSeaInterior',
          ),
          topology,
          colonialWithInvadable,
        ),
        0,
      );
    });

    test(
      'null seaZoneId and empty seaZoneId both return 0 (no colonial bonus)',
      () {
        // Naval planner can iterate over draft shapes where neither dock nor
        // sea destination is set; the scorer must short-circuit instead of
        // assigning any positive bonus.
        const moveNull = NavalMoveOrder(fleetId: 'f1');
        expect(moveNull.isDock, isFalse);
        expect(
          colonialNavalMoveScore(moveNull, topology, colonialWithInvadable),
          0,
        );
        const moveEmpty = NavalMoveOrder(
          fleetId: 'f1',
          destinationSeaZoneId: '',
        );
        expect(moveEmpty.isDock, isFalse);
        expect(
          colonialNavalMoveScore(moveEmpty, topology, colonialWithInvadable),
          0,
        );
      },
    );
  });

  group('colonialNavalMissionScore (target/mission branches)', () {
    test('New World targetPortId returns NW-port mission score', () {
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
    });

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

    test('null/empty targetPortId + NW province returns NW-province score', () {
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
    });

    test('OW province target without beachhead mission returns 0', () {
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
    });

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

    test('non-beachhead mission with no targets returns 0', () {
      expect(
        colonialNavalMissionScore(
          const NavalMissionOrder(fleetId: 'f1', mission: 'patrol'),
        ),
        0,
      );
    });
  });

  group('newWorldSeaZonesAdjacentToInvadableProvinces', () {
    test('empty invadable list returns const empty set', () {
      final out = newWorldSeaZonesAdjacentToInvadableProvinces(
        topology,
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
          topology,
          const <String>['newWorld|colonyA', 'newWorld|colonyB'],
        );
        expect(out, <String>{'newWorld|nwSeaShared'});
      },
    );

    test('filters out OW sea adjacents (only NW seas remain)', () {
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
        edges: [TopologyEdge(id1: 'newWorld|cross', id2: 'oldWorld|crossSea')],
      );
      final out = newWorldSeaZonesAdjacentToInvadableProvinces(
        topo,
        const <String>['newWorld|cross'],
      );
      expect(out, isEmpty);
    });

    test('invadable id absent from topology contributes nothing', () {
      final out = newWorldSeaZonesAdjacentToInvadableProvinces(
        topology,
        const <String>['newWorld|ghostProvinceNotInTopology'],
      );
      expect(out, isEmpty);
    });
  });

  group('sortNavalMovesForColonialPressure', () {
    test(
      'score descending dominates regardless of fleetId lexicographic order',
      () {
        // f2 → priority NW sea zone (score 200), f1 → gateway (score 90).
        // f1 sorts before f2 lexicographically, but f2 must rank first
        // because the score comparator dominates the tie-breaker chain.
        final ranked = sortNavalMovesForColonialPressure(
          [
            const NavalMoveOrder(
              fleetId: 'f1',
              destinationSeaZoneId: 'oldWorld|owSeaGateway',
            ),
            const NavalMoveOrder(
              fleetId: 'f2',
              destinationSeaZoneId: 'newWorld|nwSeaShared',
            ),
          ],
          topology,
          colonialWithInvadable,
        );
        expect(ranked.first.fleetId, 'f2');
        expect(ranked.last.fleetId, 'f1');
      },
    );

    test(
      'same score ties break on fleetId ascending then dest key ascending',
      () {
        // Two NW sea moves and one NW dock both score against the same
        // colonial summary; sort by score desc, then fleetId asc, then key
        // ('port:...' vs sea id string).
        final ranked = sortNavalMovesForColonialPressure(
          [
            const NavalMoveOrder(
              fleetId: 'fB',
              destinationSeaZoneId: 'newWorld|nwSeaIsolated',
            ),
            const NavalMoveOrder(
              fleetId: 'fA',
              destinationSeaZoneId: 'newWorld|nwSeaIsolated',
            ),
            const NavalMoveOrder(
              fleetId: 'fA',
              destinationPortProvinceId: 'oldWorld|home',
            ),
          ],
          topology,
          colonialNoInvadable,
        );
        // Scores: fA(sea)=NW(140), fB(sea)=NW(140), fA(dock OW port)=0.
        // Order: [fA sea, fB sea, fA dock].
        expect(ranked[0].fleetId, 'fA');
        expect(ranked[0].destinationSeaZoneId, 'newWorld|nwSeaIsolated');
        expect(ranked[1].fleetId, 'fB');
        expect(ranked[1].destinationSeaZoneId, 'newWorld|nwSeaIsolated');
        expect(ranked[2].fleetId, 'fA');
        expect(ranked[2].destinationPortProvinceId, 'oldWorld|home');
      },
    );

    test(
      'same fleet + same score ties break on key: dock("port:") vs sea id',
      () {
        // Both candidates score 0 (OW dock + OW interior sea, no colonial
        // bonus). With matching score and fleetId, the comparator falls to
        // the dest key ascending — dock candidates are keyed as
        // 'port:<provinceId>' and seas as their seaId.
        // 'oldWorld|owSeaInterior' < 'port:oldWorld|home' lexicographically.
        final ranked = sortNavalMovesForColonialPressure(
          [
            const NavalMoveOrder(
              fleetId: 'fX',
              destinationPortProvinceId: 'oldWorld|home',
            ),
            const NavalMoveOrder(
              fleetId: 'fX',
              destinationSeaZoneId: 'oldWorld|owSeaInterior',
            ),
          ],
          topology,
          colonialWithInvadable,
        );
        expect(ranked.first.destinationSeaZoneId, 'oldWorld|owSeaInterior');
        expect(ranked.last.destinationPortProvinceId, 'oldWorld|home');
      },
    );
  });

  group('sortNavalMissionsForColonialPressure', () {
    test('score desc dominates fleetId ordering', () {
      // fA → OW port (mission patrol) → 0. fB → NW port → 160. fB ranks
      // first despite later fleetId.
      final ranked = sortNavalMissionsForColonialPressure([
        const NavalMissionOrder(
          fleetId: 'fA',
          mission: 'patrol',
          targetPortId: 'oldWorld|home',
        ),
        const NavalMissionOrder(
          fleetId: 'fB',
          mission: 'patrol',
          targetPortId: 'newWorld|colonyA',
        ),
      ]);
      expect(ranked.first.fleetId, 'fB');
      expect(ranked.last.fleetId, 'fA');
    });

    test(
      'tie-break chain: fleetId, then mission, then portId, then provinceId',
      () {
        // All four orders score 0 (OW or null targets, no beachhead). Final
        // order must follow fleetId asc → mission asc → portId asc →
        // provinceId asc (treating null as the empty string).
        final ranked = sortNavalMissionsForColonialPressure([
          const NavalMissionOrder(
            fleetId: 'fB',
            mission: 'patrol',
            targetPortId: 'oldWorld|portB',
            targetProvinceId: 'oldWorld|provB',
          ),
          const NavalMissionOrder(
            fleetId: 'fA',
            mission: 'patrol',
            targetPortId: 'oldWorld|portA',
            targetProvinceId: 'oldWorld|provA',
          ),
          const NavalMissionOrder(
            fleetId: 'fA',
            mission: 'patrol',
            targetPortId: 'oldWorld|portA',
            targetProvinceId: 'oldWorld|provZ',
          ),
          const NavalMissionOrder(
            fleetId: 'fA',
            mission: 'defend',
            targetPortId: 'oldWorld|portA',
            targetProvinceId: 'oldWorld|provA',
          ),
        ]);
        expect(ranked[0].fleetId, 'fA');
        expect(ranked[0].mission, 'defend');
        expect(ranked[1].fleetId, 'fA');
        expect(ranked[1].mission, 'patrol');
        expect(ranked[1].targetProvinceId, 'oldWorld|provA');
        expect(ranked[2].fleetId, 'fA');
        expect(ranked[2].targetProvinceId, 'oldWorld|provZ');
        expect(ranked[3].fleetId, 'fB');
      },
    );

    test(
      'beachhead mission outranks non-beachhead misses with no NW target',
      () {
        // fA beachhead = 100, fB patrol = 0. Beachhead must lead.
        final ranked = sortNavalMissionsForColonialPressure([
          const NavalMissionOrder(fleetId: 'fB', mission: 'patrol'),
          NavalMissionOrder(
            fleetId: 'fA',
            mission: FleetMission.beachhead.name,
          ),
        ]);
        expect(ranked.first.fleetId, 'fA');
        expect(ranked.first.mission, FleetMission.beachhead.name);
        expect(ranked.last.fleetId, 'fB');
      },
    );
  });
}
