// Refs #2847 S7-D H1 refutation pin for `planExpandDeclareWar` in
// `expand_phase_planner.dart`.
//
// Core priority-arm pins live in `expand_phase_planner_declare_war_test.dart`.

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
  group('planExpandDeclareWar S7-D refutation (Refs #2847)', () {
    test('Refs #2847 S7-D H1 refutation: at-war minors that own no invadable '
        '-> arm 2 has no candidates -> null (proximate cause is geographic '
        'peer-war lock, not arm-2 candidate filtering)', () {
      // Refs #2847 § S7-T H1 refutation.
      //
      // Pin for the seed-42 turn-99 snapshot recorded in the S7-D diagnostic
      // for gp3 / gp4 / gp5 / gp6:
      //
      //   * gp3 (FAIL: +1 OW): atWarWith=[gp4, minor1, minor2, minor3, minor4,
      //     minor6], adjacentOwnerFactionIdsSorted=[gp4], invadable=6 (all
      //     owned by gp4).
      //   * gp4 (FAIL: +2 OW): symmetric mirror (adjacent=[gp3], invadable
      //     all owned by gp3).
      //   * gp5 (FAIL: +1 OW): atWarWith=[minor1, minor2, minor4, minor6],
      //     adjacent=[gp6], invadable owned by gp6.
      //   * gp6 (FAIL: +2 OW): atWarWith=[minor2], adjacent=[gp5], invadable
      //     owned by gp5.
      //
      // Five of the six at-war minors for gp3 (minor1..minor6) own zero
      // invadable provinces because none of them is adjacent to gp3's
      // anchor provinces at turn 99 — gp4's territory geographically
      // surrounds gp3. Therefore `atWarMinors` is empty inside
      // `planExpandDeclareWar` and arm 2 cannot fire even though
      // `ThreatSummary.atWarWith` lists five minors.
      //
      // The S7-D diagnostic note ranked arm-2 candidate filtering (the
      // `adjacentOwners` cross-check or the `atWarMinors` set construction)
      // as H1. This pin demonstrates that the filtering is **correct**:
      // when an at-war minor is not adjacent, `invadableProvinceIdsSorted`
      // structurally excludes its provinces and the planner returns null
      // by design (the spec gives no arm for at-war minors that own no
      // invadable; conquest army-move must reach them through other
      // territory first).
      //
      // S7-T scope for #2847 therefore shifts away from H1 toward the
      // peer-war geographic lock (gp3↔gp4 and gp5↔gp6 mutually surround
      // each other and starve each other of treasury and reachable
      // targets). See the issue's S7-D follow-up comment and the updated
      // S7-T tuning surface in
      // `seed42_observer_conquest_s7d_diagnostic_test.dart`.
      final owProvinces = <Province>[
        for (var i = 0; i < 8; i++)
          Province(id: 'oldWorld|gp1_$i', regionId: 'oldWorld', ownerId: _gp1),
        for (var i = 0; i < 6; i++)
          Province(id: 'oldWorld|gp2_$i', regionId: 'oldWorld', ownerId: _gp2),
        Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        Province(id: 'oldWorld|m2_a', regionId: 'oldWorld', ownerId: _minor2),
        Province(id: 'oldWorld|m3_a', regionId: 'oldWorld', ownerId: _minor3),
      ];
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-declare-war',
        players: const [
          Player(id: _gp1, displayName: 'GP1', isHuman: false, treasury: 50),
          Player(id: _gp2, displayName: 'GP2', isHuman: false, treasury: 0),
          Player(id: _gp3, displayName: 'GP3', isHuman: false, treasury: 9999),
        ],
        oldWorldProvinces: owProvinces,
        minorNations: const [
          MinorNation(id: _minor1, displayName: 'M1'),
          MinorNation(id: _minor2, displayName: 'M2'),
          MinorNation(id: _minor3, displayName: 'M3'),
        ],
        armies: [
          homeArmyWithRegimentsAtCapital(_gp1, 2),
          homeArmyWithRegimentsAtCapital(_gp2, 2),
        ],
      );
      final snapshot = buildExpandSnapshot(
        // gp1 plays the gp3 role (failing GP): at war with the peer
        // GP2 (= gp4) **and** with several minors (m1/m2/m3) that own
        // OW provinces but whose tiles are NOT in the invadable set
        // because they are not P-P neighbors of gp1's anchor provinces.
        atWarWith: const [_gp2, _minor1, _minor2, _minor3],
        // Six invadable provinces, every one owned by the at-war peer
        // GP2. Mirrors gp3's turn-99 snapshot.
        invadableOw: const [
          'oldWorld|gp2_0',
          'oldWorld|gp2_1',
          'oldWorld|gp2_2',
          'oldWorld|gp2_3',
          'oldWorld|gp2_4',
          'oldWorld|gp2_5',
        ],
        // Only the at-war peer GP is geographically adjacent — the
        // at-war minors are *not* in adjacentOwnerFactionIdsSorted, so
        // their non-invadable OW provinces never make it into the
        // `atWarMinors` set inside `planExpandDeclareWar`.
        adjacentOwners: const [_gp2],
        oldWorldProvincesOwned: 8,
      );
      expect(
        planExpandDeclareWar(game: game, snapshot: snapshot),
        isNull,
        reason:
            'H1 refutation pin: with all invadable OW provinces owned by '
            'the at-war peer GP and zero at-war minors holding any of '
            'them, arm 2 has structurally no candidates regardless of '
            'how many minors are in ThreatSummary.atWarWith. Arm 1 is '
            'also empty (no adjacent non-at-war minor) and arm 3 is '
            'blocked because the sole GP frontier blocker is already '
            'at war. The planner correctly returns null; tuning arm-2 '
            'candidate filtering will not move the seed-42 needle. '
            'Refs #2847 S7-T scope shift away from H1.',
      );
    });
  });
}
