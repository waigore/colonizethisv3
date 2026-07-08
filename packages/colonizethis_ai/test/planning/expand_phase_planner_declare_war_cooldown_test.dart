// Refs #2847 § H2 peer-war peace cooldown integration pins for
// `planExpandDeclareWar` arm 3 in `expand_phase_planner.dart`.
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

void main() {
  group('planExpandDeclareWar peer-war cooldown (Refs #2847 H2)', () {
    test('Refs #2847 § H2: peer-war peace cooldown active -> null '
        '(arm 3 suppressed during cooldown window)', () {
      // Refs #2847 § H2 positive case.
      //
      // Seed-42 post-H4-a refresh shape: gp1 (active player, 8 OW) and
      // peer gp2 (8 OW) just made peace last turn (the H4-a carve-out
      // in `planExpandPeace` fired and the mutual offer completed).
      // The next turn, every other arm-3 gate still passes —
      // treasury (9999 >= cheapest), regiment parity (5 == 5),
      // mutual-plateau (8 vs 8 below quota), gp2 sole adjacent OW
      // owner, gp2 not in atWarWith. Without the H2 cooldown the
      // planner would re-declare on gp2 the very next turn and the
      // war would re-open. The cooldown gate must short-circuit arm 3
      // and return null while a peace event between {_gp1, _gp2} sits
      // within the last `kExpandPeerWarPeaceCooldownTurns` turns.
      final owProvinces = <Province>[
        for (var i = 0; i < 8; i++)
          Province(id: 'oldWorld|gp1_$i', regionId: 'oldWorld', ownerId: _gp1),
        for (var i = 0; i < 8; i++)
          Province(id: 'oldWorld|gp2_$i', regionId: 'oldWorld', ownerId: _gp2),
      ];
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-declare-war',
        turnNumber: 50,
        oldWorldProvinces: owProvinces,
        armies: [
          homeArmyWithRegimentsAtCapital(_gp1, 5),
          homeArmyWithRegimentsAtCapital(_gp2, 5),
        ],
        diplomaticHistoryEvents: const [
          DiplomaticEvent(
            turn: 49,
            intraTurnIndex: 0,
            type: DiplomaticEventType.peace,
            participants: {_gp1, _gp2},
            fromFactionId: _gp1,
            toFactionId: _gp2,
          ),
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
            'Peace event between {gp1, gp2} on turn 49 is 1 turn old '
            'on turn 50; with kExpandPeerWarPeaceCooldownTurns = 4 '
            'the cooldown is active -> arm 3 must return null even '
            'though every other gate passes (treasury, regiments, '
            'mutual-plateau, sole GP blocker). Refs #2847 § H2.',
      );
    });

    test('Refs #2847 § H2: peer-war peace cooldown lapsed -> blocker GP '
        '(arm 3 fires once cooldown window expires)', () {
      // Refs #2847 § H2 boundary case (cooldown lapsed).
      //
      // Same fixture as the positive case but the peace event is
      // exactly `kExpandPeerWarPeaceCooldownTurns` turns old (turn 46
      // peace, current turn 50). The strict `<` boundary inside
      // `expandRecentlyPeacedWithGreatPower` means the cooldown is
      // **not** active and arm 3 must fire normally, returning gp2.
      final owProvinces = <Province>[
        for (var i = 0; i < 8; i++)
          Province(id: 'oldWorld|gp1_$i', regionId: 'oldWorld', ownerId: _gp1),
        for (var i = 0; i < 8; i++)
          Province(id: 'oldWorld|gp2_$i', regionId: 'oldWorld', ownerId: _gp2),
      ];
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-declare-war',
        turnNumber: 50,
        oldWorldProvinces: owProvinces,
        armies: [
          homeArmyWithRegimentsAtCapital(_gp1, 5),
          homeArmyWithRegimentsAtCapital(_gp2, 5),
        ],
        diplomaticHistoryEvents: const [
          DiplomaticEvent(
            turn: 46,
            intraTurnIndex: 0,
            type: DiplomaticEventType.peace,
            participants: {_gp1, _gp2},
            fromFactionId: _gp1,
            toFactionId: _gp2,
          ),
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
            'Peace event on turn 46 is exactly 4 turns old on turn 50; '
            'the cooldown predicate uses `currentTurn - event.turn < '
            'kExpandPeerWarPeaceCooldownTurns` so 4 < 4 is false -> '
            'cooldown lapses and arm 3 returns gp2. Refs #2847 § H2 '
            'boundary.',
      );
    });

    test('Refs #2847 § H2: cooldown applies symmetrically (peace event '
        'recorded with the peer as fromFactionId still suppresses)', () {
      // Refs #2847 § H2 symmetry pin.
      //
      // The peace event was finalized when gp2 (the peer) was the
      // mutual-offer second leg, so `fromFactionId: gp2` and
      // `toFactionId: gp1`. The H2 cooldown looks at `participants`
      // (a Set) only, so the active player gp1 must still see the
      // cooldown as active on turn 50. Guards against a regression
      // where the helper accidentally requires the active player to
      // be `event.fromFactionId`.
      final owProvinces = <Province>[
        for (var i = 0; i < 8; i++)
          Province(id: 'oldWorld|gp1_$i', regionId: 'oldWorld', ownerId: _gp1),
        for (var i = 0; i < 8; i++)
          Province(id: 'oldWorld|gp2_$i', regionId: 'oldWorld', ownerId: _gp2),
      ];
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-declare-war',
        turnNumber: 50,
        oldWorldProvinces: owProvinces,
        armies: [
          homeArmyWithRegimentsAtCapital(_gp1, 5),
          homeArmyWithRegimentsAtCapital(_gp2, 5),
        ],
        diplomaticHistoryEvents: const [
          DiplomaticEvent(
            turn: 49,
            intraTurnIndex: 0,
            type: DiplomaticEventType.peace,
            participants: {_gp1, _gp2},
            fromFactionId: _gp2,
            toFactionId: _gp1,
          ),
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
            'Peace event participants = {gp1, gp2} regardless of '
            'fromFactionId/toFactionId direction; the cooldown is '
            'symmetric so arm 3 must still be suppressed on turn 50. '
            'Refs #2847 § H2.',
      );
    });

    test('Refs #2847 § H2: peace event with a different peer GP does NOT '
        'suppress arm 3 against the blocker', () {
      // Refs #2847 § H2 cross-peer rejection pin.
      //
      // The active player gp1 recently peaced gp3 (a different GP).
      // The blocker on the GP-only frontier is gp2, with whom no
      // peace event exists. The cooldown predicate must not trigger
      // and arm 3 must fire on gp2.
      final owProvinces = <Province>[
        for (var i = 0; i < 8; i++)
          Province(id: 'oldWorld|gp1_$i', regionId: 'oldWorld', ownerId: _gp1),
        for (var i = 0; i < 8; i++)
          Province(id: 'oldWorld|gp2_$i', regionId: 'oldWorld', ownerId: _gp2),
      ];
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-declare-war',
        turnNumber: 50,
        oldWorldProvinces: owProvinces,
        armies: [
          homeArmyWithRegimentsAtCapital(_gp1, 5),
          homeArmyWithRegimentsAtCapital(_gp2, 5),
        ],
        diplomaticHistoryEvents: const [
          DiplomaticEvent(
            turn: 49,
            intraTurnIndex: 0,
            type: DiplomaticEventType.peace,
            participants: {_gp1, _gp3},
            fromFactionId: _gp1,
            toFactionId: _gp3,
          ),
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
            'Peace event participants = {gp1, gp3}; the blocker is gp2. '
            'Cooldown predicate filters on participants containing the '
            'queried peer -> rejects -> arm 3 fires as normal. Refs '
            '#2847 § H2 cross-peer rejection.',
      );
    });
  });
}
