// Composite-filter and determinism pins for `colonial_phase_planner_test.dart`.

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_phase_planner_test_support.dart';

void registerColonialPhasePlannerPeaceEdgeCases() {
  group('planColonialPeace', () {
    test(
      'mixed GP + non-GP atWarWith with blocker -> only non-blocker GPs',
      () {
        final game = buildColonialPeaceGame(
          newWorldProvinces: const [
            Province(
              id: 'newWorld|gp2_a',
              regionId: 'newWorld',
              ownerId: kColonialPhaseGp2,
            ),
          ],
          tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'T1')],
          minorNations: const [
            MinorNation(id: kColonialPhaseMinor1, displayName: 'M1'),
          ],
        );
        final snapshot = buildColonialPeaceSnapshot(
          atWarWith: const [
            kColonialPhaseGp4,
            kColonialPhaseTribe1,
            kColonialPhaseGp3,
            kColonialPhaseMinor1,
            kColonialPhaseGp2,
          ],
          invadableNw: const ['newWorld|gp2_a'],
        );
        expect(
          planColonialPeace(game: game, snapshot: snapshot),
          const [kColonialPhaseGp3, kColonialPhaseGp4],
          reason:
              'Non-GP factions filtered out via `game.playerById`; '
              'blocker (gp2) excluded; remaining GP fronts (gp3, gp4) '
              'returned sorted ascending.',
        );
      },
    );

    test('determinism: identical inputs produce identical lists', () {
      final game = buildColonialPeaceGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|gp2_a',
            regionId: 'newWorld',
            ownerId: kColonialPhaseGp2,
          ),
        ],
        tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'T1')],
        minorNations: const [
          MinorNation(id: kColonialPhaseMinor1, displayName: 'M1'),
        ],
      );
      final snapshot = buildColonialPeaceSnapshot(
        atWarWith: const [
          kColonialPhaseGp4,
          kColonialPhaseTribe1,
          kColonialPhaseGp3,
          kColonialPhaseMinor1,
          kColonialPhaseGp2,
        ],
        invadableNw: const ['newWorld|gp2_a'],
      );
      final first = planColonialPeace(game: game, snapshot: snapshot);
      final second = planColonialPeace(game: game, snapshot: snapshot);
      expect(second, first);
    });
  });
}
