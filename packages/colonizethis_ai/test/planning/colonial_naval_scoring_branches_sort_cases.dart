// Case bodies for `colonial_naval_scoring_branches_test.dart` (Refs #4079 Slice C).
// Sort stability pins for colonial naval move / mission ranking.

import 'package:colonizethis_ai/src/planning/colonial_naval_scoring.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'colonial_naval_scoring_branches_support.dart';

void registerColonialNavalScoringBranchesSortCases() {
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
          colonialNavalScoringBranchesTopology,
          colonialNavalScoringWithInvadable,
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
          colonialNavalScoringBranchesTopology,
          colonialNavalScoringNoInvadable,
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
          colonialNavalScoringBranchesTopology,
          colonialNavalScoringWithInvadable,
        );
        expect(ranked.first.destinationSeaZoneId, 'oldWorld|owSeaInterior');
        expect(ranked.last.destinationPortProvinceId, 'oldWorld|home');
      },
    );
  });

  group('sortNavalMissionsForColonialPressure', () {
    test(
      'score desc dominates fleetId ordering',
      () {
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
      },
    );

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
