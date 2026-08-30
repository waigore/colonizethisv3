// expandRecentlyPeacedWithGreatPower pins (Refs #4602 Slice B).

// Predicate-level unit tests for EXPAND-phase peace helpers in
// `expand_phase_planner.dart` (Refs #2847 § H4-a / § H2).
//
// `planExpandPeace` integration pins live in
// `expand_phase_planner_peace_test.dart`.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'test_game_factories.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _minor1 = 'minor1';

void registerPeacePredicatesRecentlyPeacedCases() {
  // `expandRecentlyPeacedWithGreatPower`. These tests are scoped to the
  // predicate itself; integration with `planExpandDeclareWar` arm 3 is
  // pinned in `expand_phase_planner_declare_war_test.dart`.
  group('expandRecentlyPeacedWithGreatPower (Refs #2847 H2)', () {
    Game gameWithEvents(List<DiplomaticEvent> events, {int turnNumber = 50}) {
      return Game(
        id: 'g-2847-h2-cooldown-t$turnNumber',
        worldState: WorldState(
          turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: _gp1, displayName: 'GP1', isHuman: false),
          Player(id: _gp2, displayName: 'GP2', isHuman: false),
        ],
        diplomaticHistoryEvents: events,
      );
    }

    test('peace event within cooldown window -> true', () {
      final game = gameWithEvents(const [
        DiplomaticEvent(
          turn: 49,
          intraTurnIndex: 0,
          type: DiplomaticEventType.peace,
          participants: {_gp1, _gp2},
          fromFactionId: _gp1,
          toFactionId: _gp2,
        ),
      ]);
      expect(
        expandRecentlyPeacedWithGreatPower(
          game: game,
          activePlayerId: _gp1,
          peerGpId: _gp2,
          currentTurn: 50,
        ),
        isTrue,
        reason:
            'Peace one turn ago is well inside the 4-turn default '
            'cooldown -> predicate returns true.',
      );
    });

    test('peace event exactly cooldownTurns ago -> false (strict <)', () {
      // Boundary pin: gate is `currentTurn - event.turn < cooldownTurns`.
      // 50 - 46 == 4, which is NOT < 4 -> the cooldown is lapsed.
      final game = gameWithEvents(const [
        DiplomaticEvent(
          turn: 46,
          intraTurnIndex: 0,
          type: DiplomaticEventType.peace,
          participants: {_gp1, _gp2},
          fromFactionId: _gp1,
          toFactionId: _gp2,
        ),
      ]);
      expect(
        expandRecentlyPeacedWithGreatPower(
          game: game,
          activePlayerId: _gp1,
          peerGpId: _gp2,
          currentTurn: 50,
        ),
        isFalse,
        reason:
            'Peace exactly kExpandPeerWarPeaceCooldownTurns turns ago: '
            'strict less-than gate so the cooldown has elapsed.',
      );
    });

    test('peace event with different peer -> false', () {
      // Active player peaced gp2, but we ask about a (non-existent
      // for this fixture) gp3. participants = {gp1, gp2} does NOT
      // contain gp3 -> the predicate must reject.
      final game = gameWithEvents(const [
        DiplomaticEvent(
          turn: 49,
          intraTurnIndex: 0,
          type: DiplomaticEventType.peace,
          participants: {_gp1, _gp2},
          fromFactionId: _gp1,
          toFactionId: _gp2,
        ),
      ]);
      expect(
        expandRecentlyPeacedWithGreatPower(
          game: game,
          activePlayerId: _gp1,
          peerGpId: 'gp99',
          currentTurn: 50,
        ),
        isFalse,
        reason:
            'Cooldown is per-peer; a peace with a different peer must '
            'not gate declarations against an unrelated faction.',
      );
    });

    test('non-peace event between the pair -> false', () {
      // A declareWar event between the same pair should not trigger the
      // peace cooldown — the predicate filters on event type strictly.
      final game = gameWithEvents(const [
        DiplomaticEvent(
          turn: 49,
          intraTurnIndex: 0,
          type: DiplomaticEventType.declareWar,
          participants: {_gp1, _gp2},
          fromFactionId: _gp1,
          toFactionId: _gp2,
        ),
      ]);
      expect(
        expandRecentlyPeacedWithGreatPower(
          game: game,
          activePlayerId: _gp1,
          peerGpId: _gp2,
          currentTurn: 50,
        ),
        isFalse,
        reason:
            'declareWar event must not satisfy the peace cooldown; the '
            'predicate looks for DiplomaticEventType.peace strictly.',
      );
    });

    test('cooldownTurns == 0 -> false even with fresh peace event '
        '(disable shortcut)', () {
      // Allows a future caller to disable the cooldown without
      // restructuring the priority arm.
      final game = gameWithEvents(const [
        DiplomaticEvent(
          turn: 50,
          intraTurnIndex: 0,
          type: DiplomaticEventType.peace,
          participants: {_gp1, _gp2},
          fromFactionId: _gp1,
          toFactionId: _gp2,
        ),
      ]);
      expect(
        expandRecentlyPeacedWithGreatPower(
          game: game,
          activePlayerId: _gp1,
          peerGpId: _gp2,
          currentTurn: 50,
          cooldownTurns: 0,
        ),
        isFalse,
        reason:
            'cooldownTurns == 0 must short-circuit to false even when a '
            'peace event is on the same turn (callers disable the '
            'cooldown by passing 0 explicitly).',
      );
    });

    test('multiple peace events: most-recent dominates (older one inside '
        'window, newer one outside)', () {
      // Two peace events: turn 30 (within if cooldownTurns >= 21) and
      // turn 49 (within default 4-turn window). With a 4-turn default,
      // the most-recent peace (turn 49) is inside the window -> true.
      // The older event must not be reached because the helper walks
      // from newest to oldest and returns on the first peace match.
      final game = gameWithEvents(const [
        DiplomaticEvent(
          turn: 30,
          intraTurnIndex: 0,
          type: DiplomaticEventType.peace,
          participants: {_gp1, _gp2},
          fromFactionId: _gp1,
          toFactionId: _gp2,
        ),
        DiplomaticEvent(
          turn: 49,
          intraTurnIndex: 0,
          type: DiplomaticEventType.peace,
          participants: {_gp1, _gp2},
          fromFactionId: _gp1,
          toFactionId: _gp2,
        ),
      ]);
      expect(
        expandRecentlyPeacedWithGreatPower(
          game: game,
          activePlayerId: _gp1,
          peerGpId: _gp2,
          currentTurn: 50,
        ),
        isTrue,
        reason:
            'Predicate walks history reverse-chronologically; the most '
            'recent peace (turn 49) determines the outcome.',
      );
    });

    test('determinism: identical inputs yield identical results', () {
      final game = gameWithEvents(const [
        DiplomaticEvent(
          turn: 49,
          intraTurnIndex: 0,
          type: DiplomaticEventType.peace,
          participants: {_gp1, _gp2},
          fromFactionId: _gp1,
          toFactionId: _gp2,
        ),
      ]);
      final first = expandRecentlyPeacedWithGreatPower(
        game: game,
        activePlayerId: _gp1,
        peerGpId: _gp2,
        currentTurn: 50,
      );
      final second = expandRecentlyPeacedWithGreatPower(
        game: game,
        activePlayerId: _gp1,
        peerGpId: _gp2,
        currentTurn: 50,
      );
      expect(
        second,
        first,
        reason: 'Pure predicate -> identical inputs yield identical results.',
      );
    });
  });
}
