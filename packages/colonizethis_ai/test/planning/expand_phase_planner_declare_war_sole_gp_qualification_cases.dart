// Topic-split case module (Refs #4602 Slice B).

// Case bodies for `expand_phase_planner_declare_war_test.dart` (Refs #4104 Slice C).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'ai_planner_fixtures.dart';
import 'expand_phase_planner_declare_war_support.dart';
import 'test_game_factories.dart';

const String _gp1 = expandDeclareWarGp1;
const String _gp2 = expandDeclareWarGp2;
const String _gp3 = expandDeclareWarGp3;
const String _minor1 = expandDeclareWarMinor1;
const String _minor2 = expandDeclareWarMinor2;
const String _minor3 = expandDeclareWarMinor3;

void registerExpandPhasePlannerDeclareWarSoleGpQualificationCases() {
  group('planExpandDeclareWar', () {
    test('determinism: identical inputs yield identical output', () {
      // Refs #2509 Must-have #7: pure-function determinism pin.
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-declare-war',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
          Province(id: 'oldWorld|m3_a', regionId: 'oldWorld', ownerId: _minor3),
        ],
        minorNations: const [
          MinorNation(id: _minor1, displayName: 'M1'),
          MinorNation(id: _minor3, displayName: 'M3'),
        ],
      );
      final snapshot = buildExpandSnapshot(
        atWarWith: const [],
        invadableOw: const ['oldWorld|m3_a', 'oldWorld|m1_a'],
        adjacentOwners: const [_minor1, _minor3],
      );
      final first = planExpandDeclareWar(game: game, snapshot: snapshot);
      final second = planExpandDeclareWar(game: game, snapshot: snapshot);
      expect(first, _minor1);
      expect(second, _minor1, reason: 'Same inputs -> same output.');
    });

    test('treasury exactly at cheapest regiment cost -> qualifies', () {
      // Boundary pin: the gate is `treasury < cheapest`, so `==` must
      // pass (a regression flipping `<` to `<=` would surface here).
      final cheapest = cheapestRegimentBuildCost();
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-declare-war',
        players: [
          Player(
            id: _gp1,
            displayName: 'GP1',
            isHuman: false,
            treasury: cheapest,
          ),
          const Player(
            id: _gp2,
            displayName: 'GP2',
            isHuman: false,
            treasury: 9999,
          ),
          const Player(
            id: _gp3,
            displayName: 'GP3',
            isHuman: false,
            treasury: 9999,
          ),
        ],
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = buildExpandSnapshot(
        atWarWith: const [],
        invadableOw: const ['oldWorld|m1_a'],
        adjacentOwners: const [_minor1],
      );
      expect(
        planExpandDeclareWar(game: game, snapshot: snapshot),
        _minor1,
        reason:
            'Boundary: treasury == cheapestRegimentBuildTreasuryCost '
            'must pass (gate is strict less-than).',
      );
    });

    test('player not in game -> null (defensive)', () {
      // Defensive guard: a snapshot.playerId pointing at a non-existent
      // player must not crash; the planner returns null.
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-declare-war',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = buildExpandSnapshot(
        atWarWith: const [],
        invadableOw: const ['oldWorld|m1_a'],
        adjacentOwners: const [_minor1],
        playerId: 'ghost-player',
      );
      expect(planExpandDeclareWar(game: game, snapshot: snapshot), isNull);
    });
  });
}
