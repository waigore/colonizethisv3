// Below-quota peer exclusion pins for `colonial_phase_planner_test.dart` (Refs #4669).

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_phase_planner_test_support.dart';

void registerColonialPhasePlannerPeaceBelowQuotaCases() {
  group('planColonialPeace', () {
    test(
      'single below-quota peer at war -> empty (Refs #2509 S7 Must-have #5)',
      () {
        final game = buildColonialPeaceGame(
          perGpOwCounts: const {kColonialPhaseGp3: 7},
        );
        final snapshot = buildColonialPeaceSnapshot(
          atWarWith: const [kColonialPhaseGp3],
        );
        expect(
          planColonialPeace(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'gp3 is a below-quota peer (OW = 7 < quota = 10) and not the '
              'colonial blocker -- the below-quota exclusion arm must drop '
              'it so the COLONIAL planner emits no `offerPeace` while the '
              'peer is still in EXPAND (Refs #2509 § Must-have #5).',
        );
      },
    );

    test(
      'mixed at-quota + below-quota peers at war -> only at-quota peers peaced (Refs #2509 S7)',
      () {
        final game = buildColonialPeaceGame(
          perGpOwCounts: const {kColonialPhaseGp3: 8},
        );
        final snapshot = buildColonialPeaceSnapshot(
          atWarWith: const [
            kColonialPhaseGp4,
            kColonialPhaseGp3,
            kColonialPhaseGp2,
          ],
        );
        expect(
          planColonialPeace(game: game, snapshot: snapshot),
          const [kColonialPhaseGp2, kColonialPhaseGp4],
          reason:
              'Below-quota peer gp3 dropped (OW = 8 < quota = 10); at-quota '
              'peers gp2 + gp4 peaced in ascending sort (Refs #2509 § '
              'Must-have #5; trailing `..sort()` -> Must-have #7).',
        );
      },
    );

    test(
      'below-quota peer that IS the blocker -> dropped once, remaining at-quota peers peaced (Refs #2509 S7)',
      () {
        final game = buildColonialPeaceGame(
          perGpOwCounts: const {kColonialPhaseGp2: 6},
          newWorldProvinces: const [
            Province(
              id: 'newWorld|gp2_a',
              regionId: 'newWorld',
              ownerId: kColonialPhaseGp2,
            ),
          ],
        );
        final snapshot = buildColonialPeaceSnapshot(
          atWarWith: const [
            kColonialPhaseGp4,
            kColonialPhaseGp3,
            kColonialPhaseGp2,
          ],
          invadableNw: const ['newWorld|gp2_a'],
        );
        expect(
          planColonialPeace(game: game, snapshot: snapshot),
          const [kColonialPhaseGp3, kColonialPhaseGp4],
          reason:
              'gp2 is both the colonial NW blocker and a below-quota peer; '
              'either exclusion arm drops it. Remaining at-quota peers '
              'gp3 + gp4 are peaced in ascending sort.',
        );
      },
    );
  });
}
