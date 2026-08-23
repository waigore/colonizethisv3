// Case bodies for `colonial_naval_scoring_branches_test.dart` (Refs #4079 Slice C).
// Move / mission scoring and adjacency predicate pins.

import 'package:colonizethis_ai/src/planning/colonial_naval_scoring.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'colonial_naval_scoring_branches_support.dart';
import 'colonial_naval_scoring_branches_scoring_cases_tail_cases.dart';

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
  });

  registerColonialNavalScoringBranchesScoringCasesTail();
}
