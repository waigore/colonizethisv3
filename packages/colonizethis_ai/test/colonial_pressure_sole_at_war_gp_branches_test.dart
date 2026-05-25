// Pins the branch table of `soleAtWarGreatPowerId` from
// `colonial_pressure.dart` at the function-unit boundary (Refs #2509 S10).
//
//   SPEC/ai/ai-architecture.md § Observer goal phases (Full AI):
//     "Sole Great Power foe" predicate gates two peace decisions —
//     `unwinnableSoleGpFrontierPeaceTarget` (below-quota outgunned peace)
//     and `consolidateGainsSoleGpPeaceTarget` (quota-met consolidate
//     peace). Both call into this predicate as a precondition before any
//     gap / quota comparison runs.
//
// The implementation in `colonial_pressure.dart`:
//
//   String? soleAtWarGreatPowerId({
//     required Game game,
//     required AIWorldSnapshot snapshot,
//   }) {
//     final gpWars = <String>[
//       for (final factionId in snapshot.threats.atWarWith)
//         if (game.playerById(factionId) != null) factionId,
//     ];
//     if (gpWars.length != 1) {
//       return null;
//     }
//     return gpWars.single;
//   }
//
// Consumers in `colonial_pressure.dart`:
//
//   - `unwinnableSoleGpFrontierPeaceTarget` — uses a null return to skip
//     below-quota outgunned peace entirely (no sole GP foe → no candidate).
//   - `consolidateGainsSoleGpPeaceTarget` — uses a null return to skip
//     quota-met consolidate peace entirely.
//
// A regression in this predicate would silently change peace behavior
// on every turn where multiple Great Powers are at war with the
// planning GP, or where the at-war list mixes Great Powers and minors:
//
//   - Returning the first faction id without enforcing the `length == 1`
//     guard would treat a multi-front war as a "sole foe", peacing the
//     wrong GP and leaving an unpinned blocker on the OW frontier.
//   - Dropping the `playerById` filter would treat a minor or tribe as
//     a Great Power foe, blocking the GP-only peace pipeline from
//     running when the GP actually has zero GP wars and a minor war.
//   - Treating an empty `atWarWith` list as `gpWars.length == 1` would
//     conjure a sole-GP foe from thin air on a peaceful turn.
//
// Sibling coverage that this file complements (but does not duplicate):
//
//   - `diplomacy_planner_below_quota_peace_test.dart` and
//     `diplomacy_planner_stalled_peace_test.dart` exercise
//     `unwinnableSoleGpFrontierPeaceTarget` and the broader peace
//     pipeline at the orchestrator boundary; they assume a single GP
//     war setup and never pin the multi-GP-at-war null exit, the
//     minor-only at-war null exit, or the GP+minor sole-GP path.
//   - `colonial_pressure_test.dart` covers other predicates in the
//     same file; it does not reference `soleAtWarGreatPowerId`.
//
// Coverage layers:
//
//   - **Empty `atWarWith` → null (B1):** no war state means no sole-GP
//     foe; both consumer peace decisions must short-circuit to null.
//   - **`atWarWith` contains only a minor → null (B2):** a minor war
//     by itself does not satisfy the predicate; `playerById` filters
//     it out and the empty `gpWars` list collapses to length 0 → null.
//   - **`atWarWith` contains only a tribe id → null (B3):** an arbitrary
//     unknown-faction id (tribe / removed player) similarly fails the
//     `playerById` lookup and is excluded from `gpWars`.
//   - **`atWarWith` contains exactly one GP → returns that GP (B4):**
//     the canonical sole-GP-foe happy path.
//   - **`atWarWith` mixes one GP and one minor → returns the GP only
//     (B5):** the minor is filtered out, the resulting `gpWars` list
//     length is 1, and the single GP is returned. This pins the
//     "ignore minor wars when counting GP foes" contract.
//   - **`atWarWith` contains two GPs → null (B6):** the length guard
//     refuses to elect a sole-GP foe when more than one GP is at war.
//     This is the regression that would otherwise peace the wrong GP
//     on a multi-front war turn.
//   - **`atWarWith` contains two GPs and a minor → null (B6 + filter):**
//     the minor is filtered, but `gpWars.length` is 2; the null exit
//     stands. This guards against accidental "GP + minor counts as
//     sole-GP" collapses.
//   - **Determinism (must-have #7):** identical inputs produce identical
//     outputs across repeat invocations.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _minor1 = 'minor1';
const String _tribe1 = 'tribe1';

Game _gameWithGpsAndMinors({
  List<String> playerIds = const [_gp1, _gp2, _gp3],
  List<String> minorIds = const [_minor1],
}) {
  return Game(
    id: 'g-2509-sole-at-war-gp-branches',
    worldState: WorldState(
      turnState: const TurnState(
        turnNumber: 60,
        phase: TurnPhase.orders,
      ),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: [
      for (final id in playerIds)
        Player(id: id, displayName: id.toUpperCase(), isHuman: false),
    ],
    minorNations: [
      for (final id in minorIds) MinorNation(id: id, displayName: id),
    ],
  );
}

AIWorldSnapshot _snapshotAtWarWith(List<String> atWarWith) {
  return AIWorldSnapshot(
    playerId: _gp1,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

void main() {
  group('soleAtWarGreatPowerId branch table', () {
    test('empty atWarWith returns null (B1)', () {
      final game = _gameWithGpsAndMinors();
      final snapshot = _snapshotAtWarWith(const []);
      expect(
        soleAtWarGreatPowerId(game: game, snapshot: snapshot),
        isNull,
        reason:
            'No active wars means no sole-GP foe; both '
            'unwinnableSoleGpFrontierPeaceTarget and '
            'consolidateGainsSoleGpPeaceTarget must short-circuit. A '
            'regression that treated an empty `atWarWith` as a sole-GP '
            'foe would conjure a peace candidate on a peaceful turn.',
      );
    });

    test('atWarWith contains only one minor returns null (B2)', () {
      final game = _gameWithGpsAndMinors();
      final snapshot = _snapshotAtWarWith(const [_minor1]);
      expect(
        soleAtWarGreatPowerId(game: game, snapshot: snapshot),
        isNull,
        reason:
            '`playerById` filters minor ids out of `gpWars`, so a '
            'minor-only at-war state collapses the resulting list '
            'length to 0. A regression that dropped the `playerById` '
            'filter would treat the minor as a sole GP foe.',
      );
    });

    test('atWarWith contains only an unknown tribe id returns null (B3)', () {
      // Tribes / removed players are not in `game.players`; `playerById`
      // returns null and the id is excluded from `gpWars`.
      final game = _gameWithGpsAndMinors(minorIds: const []);
      final snapshot = _snapshotAtWarWith(const [_tribe1]);
      expect(
        soleAtWarGreatPowerId(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Unknown-faction at-war entries (e.g. NW tribes, removed '
            'players) must be filtered out so the predicate only ever '
            'returns a current Great Power id.',
      );
    });

    test('atWarWith with exactly one GP returns that GP (B4)', () {
      final game = _gameWithGpsAndMinors();
      final snapshot = _snapshotAtWarWith(const [_gp2]);
      expect(
        soleAtWarGreatPowerId(game: game, snapshot: snapshot),
        _gp2,
        reason:
            'The canonical sole-GP-foe happy path: one entry in '
            '`atWarWith`, that entry resolves to a current Great Power, '
            'and the predicate returns that GP id.',
      );
    });

    test(
      'atWarWith with one GP and one minor returns only the GP (B5)',
      () {
        // Minor wars are deliberately ignored when counting GP foes;
        // the resulting `gpWars` list is length 1 and the GP wins.
        final game = _gameWithGpsAndMinors();
        final snapshot = _snapshotAtWarWith(const [_gp2, _minor1]);
        expect(
          soleAtWarGreatPowerId(game: game, snapshot: snapshot),
          _gp2,
          reason:
              'Minor wars are filtered out before the length check, so '
              'a GP + minor mix is treated as a sole-GP foe. A '
              'regression that included minors in `gpWars` would refuse '
              'to elect the GP whenever a concurrent minor war existed.',
        );
      },
    );

    test('atWarWith with two GPs returns null (B6 length guard)', () {
      final game = _gameWithGpsAndMinors();
      final snapshot = _snapshotAtWarWith(const [_gp2, _gp3]);
      expect(
        soleAtWarGreatPowerId(game: game, snapshot: snapshot),
        isNull,
        reason:
            'The `length != 1` guard refuses to elect a sole-GP foe '
            'when more than one GP is at war. A regression that '
            'returned `gpWars.first` here would peace the wrong GP on '
            'a multi-front war turn (Refs #2509 turn-100 verify exit '
            'code 5).',
      );
    });

    test(
      'atWarWith with two GPs and a minor returns null (B6 with minor filter)',
      () {
        // The minor is filtered, but `gpWars.length` is 2; the null
        // exit stands. Pins that the minor filter does not collapse a
        // two-GP war into a "sole GP plus filtered minor" outcome.
        final game = _gameWithGpsAndMinors();
        final snapshot = _snapshotAtWarWith(const [_gp2, _gp3, _minor1]);
        expect(
          soleAtWarGreatPowerId(game: game, snapshot: snapshot),
          isNull,
          reason:
              'Filtering the minor must not turn a two-GP war into a '
              'sole-GP-foe outcome; the predicate must still see two '
              'GPs and return null.',
        );
      },
    );

    test(
      'determinism: identical inputs produce identical outputs (must-have #7)',
      () {
        final game = _gameWithGpsAndMinors();
        final snapshot = _snapshotAtWarWith(const [_gp2, _minor1]);
        final first = soleAtWarGreatPowerId(game: game, snapshot: snapshot);
        final second = soleAtWarGreatPowerId(game: game, snapshot: snapshot);
        final third = soleAtWarGreatPowerId(game: game, snapshot: snapshot);
        expect(first, _gp2);
        expect(second, first);
        expect(third, first);
      },
    );
  });
}
