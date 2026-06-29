// Unit tests for `planning_helpers.dart` (Refs #3278), part 3.
//
// Split from `planning_helpers_test.dart` to keep each file within the repo
// non-comment line limit (SPEC/program/dart-file-non-comment-line-size.md).
// Pins the diplomatic-cooldown and at-war peace/order scoring helpers:
//   - `hasRecentDiplomaticEventWithinCooldown` — newest-match-wins reversed
//     history scan, strict `<` cooldown window, predicate filtering (Refs #3717)
//   - `atWarPeaceTargetBonus` — at-war GP eligibility gate, lazy predicate
//     short-circuit, flat-bonus emission (Refs #3717)
//   - `atWarGreatPowerOrderTarget` — at-war Great-Power order-target gate
//     (Refs #3717)

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/planning_helpers.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _minor1 = 'minor1';

AIWorldSnapshot _snapshotWithAtWar(List<String> atWarWith) {
  return AIWorldSnapshot(
    playerId: _gp1,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

Game _gameWithEvents(List<DiplomaticEvent> events) {
  return Game(
    id: 'g-3717-cooldown-scan',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: const RegionData(provinces: []),
      newWorld: const RegionData(provinces: []),
    ),
    players: const [
      Player(id: _gp1, displayName: 'GP1', isHuman: false),
      Player(id: _gp2, displayName: 'GP2', isHuman: false),
    ],
    diplomaticHistoryEvents: events,
  );
}

DiplomaticEvent _ev(
  int turn, {
  DiplomaticEventType type = DiplomaticEventType.declareWar,
  String from = _gp1,
  String to = _gp2,
}) {
  return DiplomaticEvent(
    turn: turn,
    intraTurnIndex: 0,
    type: type,
    participants: {from, to},
    fromFactionId: from,
    toFactionId: to,
  );
}

bool _warFromGp1ToGp2(DiplomaticEvent e) =>
    e.type == DiplomaticEventType.declareWar &&
    e.fromFactionId == _gp1 &&
    e.toFactionId == _gp2;

void main() {
  group('hasRecentDiplomaticEventWithinCooldown (Refs #3717)', () {
    test('true when the newest matching event is inside the window', () {
      final game = _gameWithEvents([_ev(2)]);
      expect(
        hasRecentDiplomaticEventWithinCooldown(
          game: game,
          currentTurn: 5,
          cooldownTurns: 4,
          matches: _warFromGp1ToGp2,
        ),
        isTrue, // 5 - 2 = 3 < 4
      );
    });

    test(
      'false when matching event is exactly cooldownTurns old (strict <)',
      () {
        final game = _gameWithEvents([_ev(1)]);
        expect(
          hasRecentDiplomaticEventWithinCooldown(
            game: game,
            currentTurn: 5,
            cooldownTurns: 4,
            matches: _warFromGp1ToGp2,
          ),
          isFalse, // 5 - 1 = 4, not < 4
        );
      },
    );

    test('false when no event satisfies the predicate', () {
      final game = _gameWithEvents([_ev(4, type: DiplomaticEventType.peace)]);
      expect(
        hasRecentDiplomaticEventWithinCooldown(
          game: game,
          currentTurn: 5,
          cooldownTurns: 4,
          matches: _warFromGp1ToGp2,
        ),
        isFalse,
      );
    });

    test('false on empty diplomatic history', () {
      final game = _gameWithEvents(const []);
      expect(
        hasRecentDiplomaticEventWithinCooldown(
          game: game,
          currentTurn: 5,
          cooldownTurns: 4,
          matches: _warFromGp1ToGp2,
        ),
        isFalse,
      );
    });

    test(
      'newest matching event decides; non-matching newer events skipped',
      () {
        // History ascending by turn; `.reversed` visits turn 5 (peace, no
        // match) first and must continue to the older matching declare-war at
        // turn 4 rather than stopping at the first non-match.
        final game = _gameWithEvents([
          _ev(4),
          _ev(5, type: DiplomaticEventType.peace),
        ]);
        expect(
          hasRecentDiplomaticEventWithinCooldown(
            game: game,
            currentTurn: 6,
            cooldownTurns: 4,
            matches: _warFromGp1ToGp2,
          ),
          isTrue, // newest matching is turn 4: 6 - 4 = 2 < 4
        );
      },
    );

    test('directional predicate ignores the reverse-direction event', () {
      final game = _gameWithEvents([_ev(4, from: _gp2, to: _gp1)]);
      expect(
        hasRecentDiplomaticEventWithinCooldown(
          game: game,
          currentTurn: 5,
          cooldownTurns: 4,
          matches: _warFromGp1ToGp2,
        ),
        isFalse,
      );
    });
  });

  group('atWarPeaceTargetBonus (Refs #3717)', () {
    test('returns the bonus when eligible and the predicate matches', () {
      expect(
        atWarPeaceTargetBonus(
          atWarGreatPowerTarget: true,
          isPeaceTarget: () => true,
          bonus: 7,
        ),
        equals(7),
      );
    });

    test('returns 0 when eligible but the predicate does not match', () {
      expect(
        atWarPeaceTargetBonus(
          atWarGreatPowerTarget: true,
          isPeaceTarget: () => false,
          bonus: 7,
        ),
        equals(0),
      );
    });

    test('returns 0 when not an at-war Great Power target', () {
      expect(
        atWarPeaceTargetBonus(
          atWarGreatPowerTarget: false,
          isPeaceTarget: () => true,
          bonus: 7,
        ),
        equals(0),
      );
    });

    test('skips the predicate (short-circuit) when ineligible', () {
      var calls = 0;
      final result = atWarPeaceTargetBonus(
        atWarGreatPowerTarget: false,
        isPeaceTarget: () {
          calls++;
          return true;
        },
        bonus: 7,
      );
      expect(result, equals(0));
      expect(calls, equals(0));
    });

    test('evaluates the predicate exactly once when eligible', () {
      var calls = 0;
      final result = atWarPeaceTargetBonus(
        atWarGreatPowerTarget: true,
        isPeaceTarget: () {
          calls++;
          return true;
        },
        bonus: 7,
      );
      expect(result, equals(7));
      expect(calls, equals(1));
    });
  });

  group('atWarGreatPowerOrderTarget (Refs #3717)', () {
    const Player gp = Player(id: _gp2, displayName: 'GP2', isHuman: false);

    test('true when target is a Great Power we are at war with', () {
      expect(
        atWarGreatPowerOrderTarget(
          targetGp: gp,
          snapshot: _snapshotWithAtWar([_gp2]),
          targetFactionId: _gp2,
        ),
        isTrue,
      );
    });

    test('false when the target is not a Great Power (targetGp null)', () {
      // A minor/tribe target the player is at war with still fails the gate:
      // only Player Great Powers are eligible offer-peace candidates here.
      expect(
        atWarGreatPowerOrderTarget(
          targetGp: null,
          snapshot: _snapshotWithAtWar([_minor1]),
          targetFactionId: _minor1,
        ),
        isFalse,
      );
    });

    test('false when the Great Power target is not currently at war', () {
      expect(
        atWarGreatPowerOrderTarget(
          targetGp: gp,
          snapshot: _snapshotWithAtWar([_gp3]),
          targetFactionId: _gp2,
        ),
        isFalse,
      );
    });

    test('false when both eligibility conditions fail', () {
      expect(
        atWarGreatPowerOrderTarget(
          targetGp: null,
          snapshot: _snapshotWithAtWar(const []),
          targetFactionId: _gp2,
        ),
        isFalse,
      );
    });
  });
}
