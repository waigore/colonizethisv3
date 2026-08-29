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

void registerExpandPhasePlannerDeclareWarPriorityTailEarlyCases() {
  group('planExpandDeclareWar', () {
    test('treasury below cheapest regiment cost -> null', () {
      // Treasury gate (arm 1 skip clause): when an adjacent minor
      // candidate exists but the GP cannot afford a single regiment,
      // arm 1 is skipped. With no at-war minor (arm 2 empty) and a
      // minor on the invadable frontier (arm 3 short-circuit), the
      // planner returns null.
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-declare-war',
        players: const [
          Player(id: _gp1, displayName: 'GP1', isHuman: false, treasury: 0),
          Player(id: _gp2, displayName: 'GP2', isHuman: false, treasury: 9999),
          Player(id: _gp3, displayName: 'GP3', isHuman: false, treasury: 9999),
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
      expect(planExpandDeclareWar(game: game, snapshot: snapshot), isNull);
    });

    test('AC: treasury below cheapest but at-war minor on invadable OW -> '
        'that minor (arm 2 fires without treasury gate)', () {
      // Acceptance criterion (issue #2509 § EXPAND § planExpandDeclareWar
      // arm 2): the at-war "formalize" arm has NO treasury gate per
      // spec — the war is already open and existing regiments commit on
      // it. Regression pin for the seed-42 turn-100 trap (Refs #2509
      // PR #2823 10-turn trace) where gp1's treasury collapsed below
      // `cheapestRegimentBuildTreasuryCost` from turn 4 onward yet the
      // GP still had at-war minors on invadable OW; the prior global
      // treasury hoist suppressed arm 2 and the planner returned `null`,
      // stalling gp1 at +0 net OW gain over 100 turns.
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-declare-war',
        players: const [
          Player(id: _gp1, displayName: 'GP1', isHuman: false, treasury: 0),
          Player(id: _gp2, displayName: 'GP2', isHuman: false, treasury: 9999),
          Player(id: _gp3, displayName: 'GP3', isHuman: false, treasury: 9999),
        ],
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = buildExpandSnapshot(
        atWarWith: const [_minor1],
        invadableOw: const ['oldWorld|m1_a'],
        // No adjacent-not-at-war candidates so arm 1 is empty regardless
        // of treasury; arm 2 must fire on the already-at-war minor.
        adjacentOwners: const [_minor1],
      );
      expect(
        planExpandDeclareWar(game: game, snapshot: snapshot),
        _minor1,
        reason:
            'Arm 2 (already-at-war minor with invadable OW) must fire '
            'even when treasury is below cheapestRegimentBuildTreasuryCost. '
            'Per issue #2509 spec the treasury skip clause is arm-1-only; '
            'arm 2 formalizes an existing war so the conquest army-move '
            'pass commits on already-built regiments.',
      );
    });

  });
}
