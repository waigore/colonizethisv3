// Tail sort-case bodies for `colonial_phase_planner_colonial_lite_overtures_sort_cases.dart`.

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_phase_planner_test_support.dart';

void registerColonialLiteOverturesSortTailCases() {
  group('planColonialLiteOvertures', () {
    test('input order shuffled (adjacent reversed) -> ascending sort', () {
      final game = buildColonialLiteOvertureGame(
        tribes: const [
          Tribe(id: kColonialPhaseTribe1, displayName: 'T1'),
          Tribe(id: kColonialPhaseTribe2, displayName: 'T2'),
          Tribe(id: kColonialPhaseTribe3, displayName: 'T3'),
        ],
      );
      final snapshot = buildColonialLiteOvertureSnapshot(
        adjacentNw: const [
          kColonialPhaseTribe3,
          kColonialPhaseTribe2,
          kColonialPhaseTribe1,
        ],
      );
      expect(
        planColonialLiteOvertures(game: game, snapshot: snapshot),
        const [
          kColonialPhaseTribe1,
          kColonialPhaseTribe2,
          kColonialPhaseTribe3,
        ],
        reason:
            'Trailing `result.sort()` enforces ascending order regardless '
            'of input order (Refs #2509 Must-have #7 / lowest-factionId '
            'tiebreak from the spec).',
      );
    });

    test(
      'Refs #2509 Must-have #7 determinism: identical inputs -> identical list',
      () {
        final game = buildColonialLiteOvertureGame(
          players: const [
            Player(id: kColonialPhaseGp1, displayName: 'GP1', isHuman: false),
            Player(id: kColonialPhaseGp2, displayName: 'GP2', isHuman: false),
          ],
          tribes: const [
            Tribe(id: kColonialPhaseTribe1, displayName: 'T1'),
            Tribe(id: kColonialPhaseTribe2, displayName: 'T2'),
          ],
          minorNations: const [
            MinorNation(id: kColonialPhaseMinor1, displayName: 'M1'),
          ],
          overtureStates: const [
            OvertureState(
              gpId: kColonialPhaseGp1,
              targetId: kColonialPhaseTribe2,
              stage: OvertureStage.embassy,
            ),
          ],
        );
        final snapshot = buildColonialLiteOvertureSnapshot(
          adjacentNw: const [kColonialPhaseTribe2, kColonialPhaseGp2],
          preferredColonial: const [kColonialPhaseTribe1, kColonialPhaseMinor1],
        );
        final first = planColonialLiteOvertures(game: game, snapshot: snapshot);
        final second = planColonialLiteOvertures(
          game: game,
          snapshot: snapshot,
        );
        expect(second, first);
      },
    );

    test(
      'composite: GP + embassied tribe + fresh tribe + minor -> filtered sorted',
      () {
        final game = buildColonialLiteOvertureGame(
          tribes: const [
            Tribe(id: kColonialPhaseTribe1, displayName: 'T1'),
            Tribe(id: kColonialPhaseTribe2, displayName: 'T2'),
          ],
          minorNations: const [
            MinorNation(id: kColonialPhaseMinor1, displayName: 'M1'),
          ],
          overtureStates: const [
            OvertureState(
              gpId: kColonialPhaseGp1,
              targetId: kColonialPhaseTribe2,
              stage: OvertureStage.embassy,
            ),
          ],
        );
        final snapshot = buildColonialLiteOvertureSnapshot(
          adjacentNw: const [
            kColonialPhaseGp2,
            kColonialPhaseTribe2,
            kColonialPhaseTribe1,
          ],
          preferredColonial: const [kColonialPhaseMinor1, kColonialPhaseTribe2],
        );
        expect(
          planColonialLiteOvertures(game: game, snapshot: snapshot),
          const [kColonialPhaseMinor1, kColonialPhaseTribe1],
          reason:
              'Composite filter: gp2 dropped (GP filter), tribe2 dropped '
              '(embassy filter), tribe1 + minor1 sorted ascending.',
        );
      },
    );
  });
}
