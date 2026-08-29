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

void registerExpandPhasePlannerDeclareWarPriorityTailLateCases() {
  group('planExpandDeclareWar', () {
    test('AC: treasury below cheapest, mixed arm-1 + arm-2 candidates -> '
        'at-war minor wins (arm 1 skipped for treasury)', () {
      // When treasury is below the cheapest regiment cost, arm 1 (NEW
      // declaration on `minor2` — adjacent + not at war) is skipped and
      // arm 2 fires on `minor1` (already at war). Pins that arm-1
      // candidacy does NOT block fall-through to arm 2 when treasury
      // disqualifies arm 1, and that the lex tiebreak inside each arm
      // is unaffected by the cross-arm priority.
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-declare-war',
        players: const [
          Player(id: _gp1, displayName: 'GP1', isHuman: false, treasury: 0),
          Player(id: _gp2, displayName: 'GP2', isHuman: false, treasury: 9999),
          Player(id: _gp3, displayName: 'GP3', isHuman: false, treasury: 9999),
        ],
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
          Province(id: 'oldWorld|m2_a', regionId: 'oldWorld', ownerId: _minor2),
        ],
        minorNations: const [
          MinorNation(id: _minor1, displayName: 'M1'),
          MinorNation(id: _minor2, displayName: 'M2'),
        ],
      );
      final snapshot = buildExpandSnapshot(
        atWarWith: const [_minor1],
        invadableOw: const ['oldWorld|m1_a', 'oldWorld|m2_a'],
        adjacentOwners: const [_minor1, _minor2],
      );
      expect(
        planExpandDeclareWar(game: game, snapshot: snapshot),
        _minor1,
        reason:
            'Arm 1 (minor2, new war) is skipped because treasury < '
            'cheapestRegimentBuildTreasuryCost; arm 2 (minor1, already at '
            'war) fires next regardless of treasury per issue #2509 spec.',
      );
    });

    test('AC: treasury below cheapest, sole-GP-blocker carve-out -> null '
        '(arm 3 inline treasury gate)', () {
      // Negative pin: the per-arm treasury gate must also apply to
      // arm 3 (declare war on a sole GP frontier blocker). With the
      // top-level hoist removed, an inline treasury check now sits
      // directly in the priority-3 branch; this test ensures arm 3 does
      // not slip through when treasury is below the cheapest regiment
      // cost.
      final owProvinces = <Province>[
        for (var i = 0; i < 8; i++)
          Province(id: 'oldWorld|gp1_$i', regionId: 'oldWorld', ownerId: _gp1),
        for (var i = 0; i < 8; i++)
          Province(id: 'oldWorld|gp2_$i', regionId: 'oldWorld', ownerId: _gp2),
      ];
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-declare-war',
        players: const [
          Player(id: _gp1, displayName: 'GP1', isHuman: false, treasury: 0),
          Player(id: _gp2, displayName: 'GP2', isHuman: false, treasury: 9999),
          Player(id: _gp3, displayName: 'GP3', isHuman: false, treasury: 9999),
        ],
        oldWorldProvinces: owProvinces,
        armies: [
          homeArmyWithRegimentsAtCapital(_gp1, 5),
          homeArmyWithRegimentsAtCapital(_gp2, 5),
        ],
      );
      final snapshot = buildExpandSnapshot(
        atWarWith: const [],
        invadableOw: const ['oldWorld|gp2_0'],
        adjacentOwners: const [_gp2],
        oldWorldProvincesOwned: 8,
      );
      expect(
        planExpandDeclareWar(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Arm 3 requires treasury >= cheapestRegimentBuildTreasuryCost '
            'per issue #2509 spec ("declare on that GP only if ... '
            'treasury >= regiment build cost"). Even with regiment parity '
            'and mutual-plateau peers, treasury == 0 must suppress arm 3.',
      );
    });

    test('AC: adjacent minor with invadable OW -> that minor factionId', () {
      // Acceptance criterion (issue #2509 § Phase planner unit tests):
      // GP at OW=8 + adjacent minor owning a province in
      // invadableProvinceIdsSorted -> declare-war target = that minor.
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
      );
      expect(
        planExpandDeclareWar(game: game, snapshot: snapshot),
        _minor1,
        reason:
            'Priority 1: an adjacent minor (in '
            'adjacentOwnerFactionIdsSorted) that owns an invadable OW '
            'province and is not yet at war is the canonical EXPAND '
            'declare-war target.',
      );
    });

    test('multiple adjacent minor candidates -> lowest factionId tiebreak', () {
      // Two adjacent minors both own invadable OW provinces; the
      // lexicographic ascending tiebreak surfaces minor1 over minor2.
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-declare-war',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
          Province(id: 'oldWorld|m2_a', regionId: 'oldWorld', ownerId: _minor2),
        ],
        minorNations: const [
          MinorNation(id: _minor1, displayName: 'M1'),
          MinorNation(id: _minor2, displayName: 'M2'),
        ],
      );
      final snapshot = buildExpandSnapshot(
        atWarWith: const [],
        // Reverse-sorted invadable list to verify the tiebreak does
        // NOT depend on iteration order of invadable provinces.
        invadableOw: const ['oldWorld|m2_a', 'oldWorld|m1_a'],
        adjacentOwners: const [_minor1, _minor2],
      );
      expect(
        planExpandDeclareWar(game: game, snapshot: snapshot),
        _minor1,
        reason:
            'Tiebreak: lowest factionId (minor1) wins over minor2 even '
            'when minor2 appears first in invadableProvinceIdsSorted.',
      );
    });

    test('adjacent minor already at war -> drops from priority 1', () {
      // The candidate set for priority 1 excludes minors already in
      // atWarWith so we do not re-issue a declareWar on a faction we
      // are already fighting. The next priority arm picks it up.
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-declare-war',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = buildExpandSnapshot(
        atWarWith: const [_minor1],
        invadableOw: const ['oldWorld|m1_a'],
        adjacentOwners: const [_minor1],
      );
      // Priority 2 fires (already-at-war minor with invadable OW) and
      // returns the same minor as a "formalize" target.
      expect(
        planExpandDeclareWar(game: game, snapshot: snapshot),
        _minor1,
        reason:
            'A minor in atWarWith is excluded from priority 1 but '
            'matches priority 2 (already-at-war minor with invadable '
            'OW province) so the planner formalizes the war target.',
      );
    });
  });
}
