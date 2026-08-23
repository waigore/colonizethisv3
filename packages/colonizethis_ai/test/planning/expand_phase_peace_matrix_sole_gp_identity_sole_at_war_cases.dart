// Sole-GP matrix pins (Refs #4602 Slice B).

// ignore_for_file: unused_element

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_peace_matrix_sole_gp_support.dart';

void registerExpandPeaceSoleGpIdentitySoleAtWarCases() {
  runExpandPeaceSoleGpDecider(
    'soleAtWarGreatPowerId (truth table)',
    soleAtWarGreatPowerId,
    <ExpandPeaceSoleGpCase>[
      ExpandPeaceSoleGpCase(
        name: 'empty atWarWith returns null (B1)',
        game: buildExpandPeaceGpsAndMinorsGame(),
        snapshot: expandPeaceMatrixSnapshot(
          playerId: expandPeaceMatrixGp1,
          atWarWith: const [],
        ),
        reason:
            'No active wars means no sole-GP foe; both '
            'unwinnableSoleGpFrontierPeaceTarget and '
            'consolidateGainsSoleGpPeaceTarget must short-circuit. A '
            'regression that treated an empty `atWarWith` as a sole-GP '
            'foe would conjure a peace candidate on a peaceful turn.',
      ),
      ExpandPeaceSoleGpCase(
        name: 'atWarWith contains only one minor returns null (B2)',
        game: buildExpandPeaceGpsAndMinorsGame(),
        snapshot: expandPeaceMatrixSnapshot(
          playerId: expandPeaceMatrixGp1,
          atWarWith: const [expandPeaceMatrixMinor1],
        ),
        reason:
            '`playerById` filters minor ids out of `gpWars`, so a '
            'minor-only at-war state collapses the resulting list '
            'length to 0. A regression that dropped the `playerById` '
            'filter would treat the minor as a sole GP foe.',
      ),
      ExpandPeaceSoleGpCase(
        name: 'atWarWith contains only an unknown tribe id returns null (B3)',
        // Tribes / removed players are not in `game.players`; `playerById`
        // returns null and the id is excluded from `gpWars`.
        game: buildExpandPeaceGpsAndMinorsGame(minorIds: const []),
        snapshot: expandPeaceMatrixSnapshot(
          playerId: expandPeaceMatrixGp1,
          atWarWith: const [expandPeaceMatrixTribe1],
        ),
        reason:
            'Unknown-faction at-war entries (e.g. NW tribes, removed '
            'players) must be filtered out so the predicate only ever '
            'returns a current Great Power id.',
      ),
      ExpandPeaceSoleGpCase(
        name: 'atWarWith with exactly one GP returns that GP (B4)',
        game: buildExpandPeaceGpsAndMinorsGame(),
        snapshot: expandPeaceMatrixSnapshot(
          playerId: expandPeaceMatrixGp1,
          atWarWith: const [expandPeaceMatrixGp2],
        ),
        expected: expandPeaceMatrixGp2,
        reason:
            'The canonical sole-GP-foe happy path: one entry in '
            '`atWarWith`, that entry resolves to a current Great Power, '
            'and the predicate returns that GP id.',
      ),
      ExpandPeaceSoleGpCase(
        name: 'atWarWith with one GP and one minor returns only the GP (B5)',
        // Minor wars are deliberately ignored when counting GP foes;
        // the resulting `gpWars` list is length 1 and the GP wins.
        game: buildExpandPeaceGpsAndMinorsGame(),
        snapshot: expandPeaceMatrixSnapshot(
          playerId: expandPeaceMatrixGp1,
          atWarWith: const [expandPeaceMatrixGp2, expandPeaceMatrixMinor1],
        ),
        expected: expandPeaceMatrixGp2,
        reason:
            'Minor wars are filtered out before the length check, so '
            'a GP + minor mix is treated as a sole-GP foe. A '
            'regression that included minors in `gpWars` would refuse '
            'to elect the GP whenever a concurrent minor war existed.',
      ),
      ExpandPeaceSoleGpCase(
        name: 'atWarWith with two GPs returns null (B6 length guard)',
        game: buildExpandPeaceGpsAndMinorsGame(),
        snapshot: expandPeaceMatrixSnapshot(
          playerId: expandPeaceMatrixGp1,
          atWarWith: const [expandPeaceMatrixGp2, expandPeaceMatrixGp3],
        ),
        reason:
            'The `length != 1` guard refuses to elect a sole-GP foe '
            'when more than one GP is at war. A regression that '
            'returned `gpWars.first` here would peace the wrong GP on '
            'a multi-front war turn (Refs #2509 turn-100 verify exit '
            'code 5).',
      ),
      ExpandPeaceSoleGpCase(
        name:
            'atWarWith with two GPs and a minor returns null '
            '(B6 with minor filter)',
        // The minor is filtered, but `gpWars.length` is 2; the null
        // exit stands. Pins that the minor filter does not collapse a
        // two-GP war into a "sole GP plus filtered minor" outcome.
        game: buildExpandPeaceGpsAndMinorsGame(),
        snapshot: expandPeaceMatrixSnapshot(
          playerId: expandPeaceMatrixGp1,
          atWarWith: const [
            expandPeaceMatrixGp2,
            expandPeaceMatrixGp3,
            expandPeaceMatrixMinor1,
          ],
        ),
        reason:
            'Filtering the minor must not turn a two-GP war into a '
            'sole-GP-foe outcome; the predicate must still see two '
            'GPs and return null.',
      ),
    ],
  );

  test('soleAtWarGreatPowerId determinism: identical inputs produce identical '
      'outputs (must-have #7)', () {
    final game = buildExpandPeaceGpsAndMinorsGame();
    final snapshot = expandPeaceMatrixSnapshot(
      playerId: expandPeaceMatrixGp1,
      atWarWith: const [expandPeaceMatrixGp2, expandPeaceMatrixMinor1],
    );
    final first = soleAtWarGreatPowerId(game: game, snapshot: snapshot);
    final second = soleAtWarGreatPowerId(game: game, snapshot: snapshot);
    final third = soleAtWarGreatPowerId(game: game, snapshot: snapshot);
    expect(first, expandPeaceMatrixGp2);
    expect(second, first);
    expect(third, first);
  });
}
