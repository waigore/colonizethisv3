import 'package:colonizethis_app_debug/colonizethis_app_debug.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'debug_handler_test_fixtures.dart';

SetDebugDiplomacyRelationEvent _event({
  String? factionA,
  required String factionB,
  required DebugDiplomacyAction action,
  String humanPlayerId = 'england',
}) {
  return SetDebugDiplomacyRelationEvent(
    humanPlayerId: humanPlayerId,
    factionA: factionA,
    factionB: factionB,
    action: action,
  );
}

DebugCommandResult _apply({
  Game? currentGame,
  required SetDebugDiplomacyRelationEvent event,
}) {
  return applyDebugSetDiplomacyRelation(
    currentGame: currentGame ?? buildDebugHandlerDiplomacyGame(),
    event: event,
  );
}

void _expectRejected(DebugCommandResult result, Object messageMatcher) {
  expect(result.game, isNull);
  expect(result.message, messageMatcher);
}

Game _expectApplied(DebugCommandResult result) {
  expect(result.game, isNotNull);
  return result.game!;
}

void main() {
  suppressLogsForTests();

  group('applyDebugSetDiplomacyRelation', () {
    test('AC1: 1-faction war sets atWar + declareWar history event', () {
      final game = _expectApplied(
        _apply(event: _event(factionB: 'ireland', action: DebugDiplomacyAction.war)),
      );
      expect(getRelation(game, 'england', 'ireland')?.state, RelationState.atWar);
      expect(
        game.diplomaticHistoryEvents
            .where((e) => e.type == DiplomaticEventType.declareWar)
            .length,
        1,
      );
    });

    test('AC2: 2-faction alliance sets formalAlliance true', () {
      final game = _expectApplied(
        _apply(
          event: _event(
            factionA: 'england',
            factionB: 'france',
            action: DebugDiplomacyAction.alliance,
          ),
        ),
      );
      expect(getRelation(game, 'england', 'france')?.formalAlliance, isTrue);
    });

    test('AC3: war rejected when a formal alliance exists', () {
      _expectRejected(
        _apply(
          currentGame: buildDebugHandlerDiplomacyGame(
            relations: const [
              DiplomacyRelation(
                factionId1: 'england',
                factionId2: 'france',
                formalAlliance: true,
              ),
            ],
          ),
          event: _event(
            factionA: 'england',
            factionB: 'france',
            action: DebugDiplomacyAction.war,
          ),
        ),
        contains('formal alliance'),
      );
    });

    test('AC4: per-turn quota rejects a second mutation for the same pair', () {
      final first = _expectApplied(
        _apply(event: _event(factionB: 'ireland', action: DebugDiplomacyAction.war)),
      );
      _expectRejected(
        _apply(
          currentGame: first,
          event: _event(factionB: 'ireland', action: DebugDiplomacyAction.peace),
        ),
        contains('already used debug diplomacy for this pair this turn'),
      );
    });

    test('AC5: quota survives a save/load round trip', () {
      final first = _expectApplied(
        _apply(event: _event(factionB: 'ireland', action: DebugDiplomacyAction.war)),
      );
      final reloaded = Game.fromJson(first.toJson());
      expect(
        reloaded.debugDiplomacyUsedPairKeys.contains(pairKey('england', 'ireland')),
        isTrue,
      );
      _expectRejected(
        _apply(
          currentGame: reloaded,
          event: _event(factionB: 'ireland', action: DebugDiplomacyAction.peace),
        ),
        contains('already used debug diplomacy'),
      );
    });

    test('AC6: command rejected outside the Orders phase', () {
      _expectRejected(
        _apply(
          currentGame: buildDebugHandlerDiplomacyGame(phase: TurnPhase.diplomacy),
          event: _event(factionB: 'ireland', action: DebugDiplomacyAction.war),
        ),
        contains('Orders phase'),
      );
    });

    test('AC7: consulate overture is created from initiator toward target', () {
      final game = _expectApplied(
        _apply(
          event: _event(factionB: 'ireland', action: DebugDiplomacyAction.consulate),
        ),
      );
      final overture = getOverture(game, 'england', 'ireland');
      expect(overture, isNotNull);
      expect(overture!.stage, OvertureStage.tradeConsulate);
    });

    test('AC8: ftp set with mutual embassy overtures', () {
      final next = _expectApplied(
        _apply(
          currentGame: buildDebugHandlerDiplomacyGame(
            overtures: const [
              OvertureState(
                gpId: 'england',
                targetId: 'france',
                stage: OvertureStage.embassy,
              ),
              OvertureState(
                gpId: 'france',
                targetId: 'england',
                stage: OvertureStage.embassy,
              ),
            ],
          ),
          event: _event(factionB: 'france', action: DebugDiplomacyAction.ftp),
        ),
      );
      expect(hasFtpPartnership(next, 'england', 'france'), isTrue);
    });

    test('AC9: ftp rejected when there is no embassy overture', () {
      _expectRejected(
        _apply(event: _event(factionB: 'france', action: DebugDiplomacyAction.ftp)),
        contains('embassy'),
      );
    });

    test('AC10: war clears overtures + FTP and logs side-effect events', () {
      final next = _expectApplied(
        _apply(
          currentGame: buildDebugHandlerDiplomacyGame(
            overtures: const [
              OvertureState(
                gpId: 'england',
                targetId: 'ireland',
                stage: OvertureStage.tradeConsulate,
              ),
            ],
            ftpKeys: {pairKey('england', 'ireland')},
          ),
          event: _event(factionB: 'ireland', action: DebugDiplomacyAction.war),
        ),
      );
      expect(getOverture(next, 'england', 'ireland'), isNull);
      expect(hasFtpPartnership(next, 'england', 'ireland'), isFalse);
      final types = next.diplomaticHistoryEvents.map((e) => e.type).toSet();
      expect(types, contains(DiplomaticEventType.declareWar));
      expect(types, contains(DiplomaticEventType.agreementsClearedOnWar));
      expect(types, contains(DiplomaticEventType.ftpBroken));
    });

    test('AC11: unknown faction produces a not-found error', () {
      _expectRejected(
        _apply(event: _event(factionB: 'Atlantis', action: DebugDiplomacyAction.war)),
        'Faction not found: Atlantis',
      );
    });

    test('AC12: self-target is rejected', () {
      _expectRejected(
        _apply(
          event: _event(
            factionA: 'england',
            factionB: 'england',
            action: DebugDiplomacyAction.war,
          ),
        ),
        contains('cannot set a relation with itself'),
      );
    });

    test('AC14: display name resolution (case-insensitive)', () {
      final game = _expectApplied(
        _apply(
          event: _event(
            factionB: 'zulu kingdom',
            action: DebugDiplomacyAction.war,
          ),
        ),
      );
      expect(getRelation(game, 'england', 'zulu')?.state, RelationState.atWar);
    });

    test('AC15: war rejected when already at war (no re-triggered effects)', () {
      _expectRejected(
        _apply(
          currentGame: buildDebugHandlerDiplomacyGame(
            relations: const [
              DiplomacyRelation(
                factionId1: 'england',
                factionId2: 'ireland',
                state: RelationState.atWar,
              ),
            ],
          ),
          event: _event(factionB: 'ireland', action: DebugDiplomacyAction.war),
        ),
        contains('already at war'),
      );
    });

    test('alliance rejected when a participant is not a Great Power', () {
      _expectRejected(
        _apply(
          event: _event(factionB: 'ireland', action: DebugDiplomacyAction.alliance),
        ),
        contains('Great Power'),
      );
    });

    test('peace rejected when already at peace', () {
      _expectRejected(
        _apply(event: _event(factionB: 'ireland', action: DebugDiplomacyAction.peace)),
        contains('already at peace'),
      );
    });

    test('no_alliance succeeds as a no-op when no alliance exists', () {
      final result = _apply(
        event: _event(
          factionA: 'england',
          factionB: 'france',
          action: DebugDiplomacyAction.noAlliance,
        ),
      );
      expect(result.game, isNotNull);
      expect(result.message, contains('no change'));
    });

    test('no_alliance breaks an existing alliance with a history event', () {
      final next = _expectApplied(
        _apply(
          currentGame: buildDebugHandlerDiplomacyGame(
            relations: const [
              DiplomacyRelation(
                factionId1: 'england',
                factionId2: 'france',
                formalAlliance: true,
              ),
            ],
          ),
          event: _event(
            factionA: 'england',
            factionB: 'france',
            action: DebugDiplomacyAction.noAlliance,
          ),
        ),
      );
      expect(getRelation(next, 'england', 'france')?.formalAlliance, isFalse);
      expect(
        next.diplomaticHistoryEvents
            .any((e) => e.type == DiplomaticEventType.allianceBroken),
        isTrue,
      );
    });

    test('clear_overture removes an existing overture', () {
      final next = _expectApplied(
        _apply(
          currentGame: buildDebugHandlerDiplomacyGame(
            overtures: const [
              OvertureState(
                gpId: 'england',
                targetId: 'ireland',
                stage: OvertureStage.embassy,
              ),
            ],
          ),
          event: _event(
            factionB: 'ireland',
            action: DebugDiplomacyAction.clearOverture,
          ),
        ),
      );
      expect(getOverture(next, 'england', 'ireland'), isNull);
    });
  });
}
