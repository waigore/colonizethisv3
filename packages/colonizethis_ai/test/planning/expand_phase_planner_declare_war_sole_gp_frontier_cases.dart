// Topic-split case bodies for `expand_phase_planner_declare_war_test.dart` (Refs #4104 Slice C, #4602 Slice B).
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

void registerExpandPhasePlannerDeclareWarSoleGpFrontierCases() {
  group('planExpandDeclareWar', () {
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
  });
}
