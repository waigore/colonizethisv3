// Unit tests for `planExpandDeclareWar` in
// `packages/colonizethis_ai/lib/src/planning/expand_phase_planner.dart`
// (Refs #2509 S2 / S10).
//
// Spec contract (issue #2509 § EXPAND phase planner § planExpandDeclareWar):
//
//   "Priority-ordered scan of `invadableProvinceIdsSorted` (OW only).
//    Pick the first valid candidate:
//      1. Adjacent minor with uninvaded OW province
//         → Tiebreaker: lowest factionId.
//         → Skip if already at war with all candidates,
//           treasury < cheapestRegimentBuildTreasuryCost,
//           or suggestDeclareWarOrders rejects.
//      2. Already-at-war minor with uninvaded OW province
//      3. Sole GP frontier blocker (GP-only frontiers only):
//         declare on that GP only if mutual-plateau, our regiments
//         ≥ partner's, treasury ≥ regiment build cost.
//      4. null — skip declaring."
//
// Mirrors the test pattern established for `planExpandPeace` in the same
// package (`expand_phase_planner_test.dart`): small synthetic fixtures,
// one branch arm per test, in-module pin (the planner module never
// re-checks phase, so these tests stay scoped to the priority scan
// branches and the deterministic-tiebreak / treasury / regiment gates).
//
// The "suggestDeclareWarOrders rejects" gate noted in the spec is
// enforced at the orchestrator layer (#2509 S5) and is intentionally
// out of scope for this in-module pin.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'ai_planner_fixtures.dart';
import 'test_game_factories.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _minor1 = 'minor1';
const String _minor2 = 'minor2';
const String _minor3 = 'minor3';

void main() {
  group('planExpandDeclareWar', () {
    test('empty invadable list -> null', () {
      // No OW frontier means there is no province to expand into. The
      // function must short-circuit before any priority-arm scan or
      // treasury check.
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-declare-war',
      );
      final snapshot = buildExpandSnapshot(atWarWith: const []);
      expect(planExpandDeclareWar(game: game, snapshot: snapshot), isNull);
    });

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

    test('priority 2: only at-war minor candidates -> lowest factionId', () {
      // Two minors both already at war and both own invadable OW.
      // Tiebreak ascending picks minor1.
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
        atWarWith: const [_minor1, _minor2],
        invadableOw: const ['oldWorld|m2_a', 'oldWorld|m1_a'],
        // adjacentOwners does NOT contain either minor so priority 1
        // must fall through to priority 2.
        adjacentOwners: const [],
      );
      expect(
        planExpandDeclareWar(game: game, snapshot: snapshot),
        _minor1,
        reason:
            'Priority 2 (at-war minors with invadable OW) returns the '
            'lowest factionId regardless of invadable list order.',
      );
    });

    test('AC: sole GP frontier blocker, mutual-plateau, regiments OK -> '
        'blocker GP factionId', () {
      // Acceptance criterion (issue #2509 § Phase planner unit tests):
      // GP at OW=8 with a sole GP owning the only invadable OW
      // frontier, both sides mutual-plateau, regiments parity ->
      // declare-war target = blocker GP.
      final owProvinces = <Province>[
        for (var i = 0; i < 8; i++)
          Province(id: 'oldWorld|gp1_$i', regionId: 'oldWorld', ownerId: _gp1),
        for (var i = 0; i < 8; i++)
          Province(id: 'oldWorld|gp2_$i', regionId: 'oldWorld', ownerId: _gp2),
      ];
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-declare-war',
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
        _gp2,
        reason:
            'Priority 3 (sole GP blocker on a GP-only mutual-plateau '
            'frontier with our regiments >= partner) returns the '
            'blocker GP factionId. Refs #2509 § EXPAND declare-war.',
      );
    });

    test('AC: sole GP blocker, mutual-plateau, but our regiments < partner '
        '-> null', () {
      // Same scenario but with regiment parity flipped: our 3 < their
      // 5. Per the spec, declare-war is suppressed.
      final owProvinces = <Province>[
        for (var i = 0; i < 8; i++)
          Province(id: 'oldWorld|gp1_$i', regionId: 'oldWorld', ownerId: _gp1),
        for (var i = 0; i < 8; i++)
          Province(id: 'oldWorld|gp2_$i', regionId: 'oldWorld', ownerId: _gp2),
      ];
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-declare-war',
        oldWorldProvinces: owProvinces,
        armies: [
          homeArmyWithRegimentsAtCapital(_gp1, 3),
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
            'Regiment shortfall blocks priority 3 (issue spec: declare '
            'on the blocker GP only if our regiments >= partners). '
            'Refs #2509 § EXPAND declare-war.',
      );
    });

    test('sole GP blocker but at quota (our OW = 10) -> null '
        '(carve-out blocked: not mutual plateau)', () {
      // When `oldWorldProvincesOwned` reaches the quota, the planner
      // is no longer in EXPAND territory for the carve-out: the
      // mutual-plateau predicate requires both sides below quota.
      final owProvinces = <Province>[
        for (var i = 0; i < 10; i++)
          Province(id: 'oldWorld|gp1_$i', regionId: 'oldWorld', ownerId: _gp1),
        for (var i = 0; i < 8; i++)
          Province(id: 'oldWorld|gp2_$i', regionId: 'oldWorld', ownerId: _gp2),
      ];
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-declare-war',
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
        oldWorldProvincesOwned: 10,
      );
      expect(
        planExpandDeclareWar(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Carve-out gates on `_isMutualBelowQuotaPlateauPeer`; with '
            'own OW = 10 the carve-out cannot fire and the planner '
            'leaves the at-quota GP alone (DEVELOP / COLONIAL phases '
            'will dispatch instead).',
      );
    });

    test('sole GP blocker but already at war -> null', () {
      // Priority 3 is suppressed when the sole GP blocker is already
      // at war so the orchestrator does not re-issue a declareWar.
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-declare-war',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|gp2_0', regionId: 'oldWorld', ownerId: _gp2),
        ],
        armies: [
          homeArmyWithRegimentsAtCapital(_gp1, 5),
          homeArmyWithRegimentsAtCapital(_gp2, 5),
        ],
      );
      final snapshot = buildExpandSnapshot(
        atWarWith: const [_gp2],
        invadableOw: const ['oldWorld|gp2_0'],
        adjacentOwners: const [_gp2],
        oldWorldProvincesOwned: 8,
      );
      expect(
        planExpandDeclareWar(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Already-at-war GP is skipped in priority 3 (declareWar is '
            'a no-op against an active war front).',
      );
    });

    test('frontier mixes GP + minor owner -> null', () {
      // A minor owns one invadable OW tile -> the frontier is not
      // GP-only and priority 3 is short-circuited. The minor itself is
      // not adjacent and not at war, so priorities 1 and 2 do not
      // qualify either: result is null.
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-declare-war',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
          Province(id: 'oldWorld|gp2_0', regionId: 'oldWorld', ownerId: _gp2),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        armies: [
          homeArmyWithRegimentsAtCapital(_gp1, 5),
          homeArmyWithRegimentsAtCapital(_gp2, 5),
        ],
      );
      final snapshot = buildExpandSnapshot(
        atWarWith: const [],
        invadableOw: const ['oldWorld|m1_a', 'oldWorld|gp2_0'],
        // No adjacent owners declared -> minor1 cannot match priority 1.
        adjacentOwners: const [],
        oldWorldProvincesOwned: 8,
      );
      expect(
        planExpandDeclareWar(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Priority 3 requires a GP-only frontier; a minor on the '
            'invadable list disables the carve-out. With no priority-1 '
            'or priority-2 minor match either, the planner returns null.',
      );
    });

    test('two GPs both own invadable OW -> null (frontier not "sole")', () {
      // Priority 3 fires only for a SOLE GP blocker.
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-declare-war',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|gp2_0', regionId: 'oldWorld', ownerId: _gp2),
          Province(id: 'oldWorld|gp3_0', regionId: 'oldWorld', ownerId: _gp3),
        ],
        armies: [
          homeArmyWithRegimentsAtCapital(_gp1, 5),
          homeArmyWithRegimentsAtCapital(_gp2, 5),
          homeArmyWithRegimentsAtCapital(_gp3, 5),
        ],
      );
      final snapshot = buildExpandSnapshot(
        atWarWith: const [],
        invadableOw: const ['oldWorld|gp2_0', 'oldWorld|gp3_0'],
        adjacentOwners: const [_gp2, _gp3],
        oldWorldProvincesOwned: 8,
      );
      expect(
        planExpandDeclareWar(game: game, snapshot: snapshot),
        isNull,
        reason:
            'When the GP-only invadable frontier has two GP owners, '
            'priority 3 short-circuits because the spec carve-out '
            'requires "exactly ONE GP owns the frontier".',
      );
    });

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
