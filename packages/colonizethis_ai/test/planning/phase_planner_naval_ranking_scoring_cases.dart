// Case bodies for `phase_planner_naval_ranking_test.dart` (Refs #4079 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1 from the
// former inline suite.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_naval_scoring.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'phase_planner_naval_ranking_support.dart';

void registerPhasePlannerNavalRankingScoringCases() {
  group('colonialNavalMoveScore (phase-priority tier)', () {
    test(
      'phase-priority sea zone returns the new tier (240) above general (200)',
      () {
        const move = NavalMoveOrder(
          fleetId: 'f1',
          destinationSeaZoneId: 'newWorld|nwSeaPhase',
        );
        final score = colonialNavalMoveScore(
          move,
          topology,
          colonialWithBoth,
          phasePriorityNwProvinceIdsSorted: phasePriorityIds,
        );
        expect(score, kColonialNavalMovePhasePriorityNwSeaZoneScore);
        expect(
          score,
          greaterThan(kColonialNavalMovePriorityNwSeaZoneScore),
          reason:
              'Phase-priority tier must rank strictly above the general '
              'invadable-NW priority tier so the phase-active acquisition '
              'frontier is preferred when both arms exist on the same turn.',
        );
      },
    );

    test(
      'non-priority invadable sea zone still returns the general tier (200)',
      () {
        const move = NavalMoveOrder(
          fleetId: 'f1',
          destinationSeaZoneId: 'newWorld|nwSeaOther',
        );
        final score = colonialNavalMoveScore(
          move,
          topology,
          colonialWithBoth,
          phasePriorityNwProvinceIdsSorted: phasePriorityIds,
        );
        expect(
          score,
          kColonialNavalMovePriorityNwSeaZoneScore,
          reason:
              'Non-phase invadable NW sea zones must remain in the general '
              'priority tier; the new top tier only fires for phase-active '
              'frontiers.',
        );
      },
    );

    test(
      'null phasePriorityNwProvinceIdsSorted preserves legacy scoring exactly',
      () {
        // Without the phase parameter, both NW sea zones rank at the general
        // priority tier (each is adjacent to an invadable NW province in
        // `colonial.invadableNewWorldProvinceIdsSorted`).
        for (final seaId in const <String>[
          'newWorld|nwSeaPhase',
          'newWorld|nwSeaOther',
        ]) {
          expect(
            colonialNavalMoveScore(
              NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: seaId),
              topology,
              colonialWithBoth,
            ),
            kColonialNavalMovePriorityNwSeaZoneScore,
          );
        }
      },
    );

    test('empty phasePriorityNwProvinceIdsSorted preserves legacy scoring '
        'exactly', () {
      for (final seaId in const <String>[
        'newWorld|nwSeaPhase',
        'newWorld|nwSeaOther',
      ]) {
        expect(
          colonialNavalMoveScore(
            NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: seaId),
            topology,
            colonialWithBoth,
            phasePriorityNwProvinceIdsSorted: const <String>[],
          ),
          kColonialNavalMovePriorityNwSeaZoneScore,
        );
      }
    });

    test('phase-priority list does not promote non-NW sea zones', () {
      // The OW gateway sea zone borders a NW sea zone; the gateway score
      // (90) must stay unchanged regardless of the phase-priority list.
      const move = NavalMoveOrder(
        fleetId: 'f1',
        destinationSeaZoneId: 'oldWorld|owSeaGateway',
      );
      expect(
        colonialNavalMoveScore(
          move,
          topology,
          colonialWithBoth,
          phasePriorityNwProvinceIdsSorted: phasePriorityIds,
        ),
        kColonialNavalMoveGatewaySeaZoneScore,
      );
    });

    test(
      'phase-priority entry not in invadable list still surfaces the new tier '
      'via its own adjacency (defensive)',
      () {
        // Defensive contract: even when the phase priority list contains
        // an id absent from `colonial.invadableNewWorldProvinceIdsSorted`
        // (should not happen in practice — both adapters derive their
        // priority list from a subset of the same field, but the scorer
        // must not crash and must score by topology adjacency).
        const colonialOnlyOther = ColonialSummary(
          invadableNewWorldProvinceIdsSorted: <String>['newWorld|otherColony'],
        );
        const move = NavalMoveOrder(
          fleetId: 'f1',
          destinationSeaZoneId: 'newWorld|nwSeaPhase',
        );
        expect(
          colonialNavalMoveScore(
            move,
            topology,
            colonialOnlyOther,
            phasePriorityNwProvinceIdsSorted: phasePriorityIds,
          ),
          kColonialNavalMovePhasePriorityNwSeaZoneScore,
        );
      },
    );

    test('deterministic for identical inputs (Must-have #7)', () {
      const move = NavalMoveOrder(
        fleetId: 'f1',
        destinationSeaZoneId: 'newWorld|nwSeaPhase',
      );
      final a = colonialNavalMoveScore(
        move,
        topology,
        colonialWithBoth,
        phasePriorityNwProvinceIdsSorted: phasePriorityIds,
      );
      final b = colonialNavalMoveScore(
        move,
        topology,
        colonialWithBoth,
        phasePriorityNwProvinceIdsSorted: phasePriorityIds,
      );
      expect(a, b);
    });
  });

  group('sortNavalMovesForColonialPressure (phase-priority tier)', () {
    test('phase-priority sea zone ranks ahead of non-priority invadable sea '
        'zone even with smaller fleetId on the non-priority candidate', () {
      final ranked = sortNavalMovesForColonialPressure(
        [
          // fA (lexicographically smaller) -> general priority sea zone.
          // fB -> phase-priority sea zone (new top tier). The new tier
          // must dominate fleetId ordering so fB ranks first.
          const NavalMoveOrder(
            fleetId: 'fA',
            destinationSeaZoneId: 'newWorld|nwSeaOther',
          ),
          const NavalMoveOrder(
            fleetId: 'fB',
            destinationSeaZoneId: 'newWorld|nwSeaPhase',
          ),
        ],
        topology,
        colonialWithBoth,
        phasePriorityNwProvinceIdsSorted: phasePriorityIds,
      );
      expect(ranked.first.fleetId, 'fB');
      expect(ranked.first.destinationSeaZoneId, 'newWorld|nwSeaPhase');
      expect(ranked.last.fleetId, 'fA');
    });

    test('null phasePriorityNwProvinceIdsSorted falls back to legacy ordering '
        '(fleetId asc dominates ties when both candidates score 200)', () {
      final ranked = sortNavalMovesForColonialPressure(
        [
          const NavalMoveOrder(
            fleetId: 'fB',
            destinationSeaZoneId: 'newWorld|nwSeaPhase',
          ),
          const NavalMoveOrder(
            fleetId: 'fA',
            destinationSeaZoneId: 'newWorld|nwSeaOther',
          ),
        ],
        topology,
        colonialWithBoth,
      );
      // Both score 200 (legacy general priority); fleetId asc wins.
      expect(ranked.first.fleetId, 'fA');
      expect(ranked.last.fleetId, 'fB');
    });

    test('deterministic sort for identical inputs (Must-have #7)', () {
      List<String> fingerprint(List<NavalMoveOrder> moves) => <String>[
        for (final m in moves) '${m.fleetId}|${m.destinationSeaZoneId ?? ''}',
      ];
      final input = <NavalMoveOrder>[
        const NavalMoveOrder(
          fleetId: 'fA',
          destinationSeaZoneId: 'newWorld|nwSeaOther',
        ),
        const NavalMoveOrder(
          fleetId: 'fB',
          destinationSeaZoneId: 'newWorld|nwSeaPhase',
        ),
      ];
      final first = sortNavalMovesForColonialPressure(
        input,
        topology,
        colonialWithBoth,
        phasePriorityNwProvinceIdsSorted: phasePriorityIds,
      );
      final second = sortNavalMovesForColonialPressure(
        input,
        topology,
        colonialWithBoth,
        phasePriorityNwProvinceIdsSorted: phasePriorityIds,
      );
      expect(fingerprint(second), fingerprint(first));
    });
  });
}
