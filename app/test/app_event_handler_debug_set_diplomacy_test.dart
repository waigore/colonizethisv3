import 'package:colonizethis_app/core/services/app_event_handler_debug_set_diplomacy.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

Game _buildGame({
  TurnPhase phase = TurnPhase.orders,
  int turnNumber = 1,
  List<DiplomacyRelation> relations = const [],
  List<OvertureState> overtures = const [],
  Set<String> ftpKeys = const {},
  Set<String> usedPairKeys = const {},
}) {
  return Game(
    id: 'g-set-diplomacy',
    worldState: WorldState(
      turnState: TurnState(phase: phase, turnNumber: turnNumber),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'england', displayName: 'England', isHuman: true),
      Player(id: 'france', displayName: 'France', isHuman: false),
    ],
    minorNations: const [MinorNation(id: 'ireland', displayName: 'Ireland')],
    tribes: const [Tribe(id: 'zulu', displayName: 'Zulu Kingdom')],
    diplomacyRelations: relations,
    overtureStates: overtures,
    ftpPartnershipKeys: ftpKeys,
    debugDiplomacyUsedPairKeys: usedPairKeys,
  );
}

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

void main() {
  suppressLogsForTests();

  group('applyDebugSetDiplomacyRelation', () {
    test('AC1: 1-faction war sets atWar + declareWar history event', () {
      final result = applyDebugSetDiplomacyRelation(
        currentGame: _buildGame(),
        event: _event(factionB: 'ireland', action: DebugDiplomacyAction.war),
      );

      final game = result.game;
      expect(game, isNotNull);
      expect(getRelation(game!, 'england', 'ireland')?.state,
          RelationState.atWar);
      expect(
        game.diplomaticHistoryEvents
            .where((e) => e.type == DiplomaticEventType.declareWar)
            .length,
        1,
      );
    });

    test('AC2: 2-faction alliance sets formalAlliance true', () {
      final result = applyDebugSetDiplomacyRelation(
        currentGame: _buildGame(),
        event: _event(
          factionA: 'england',
          factionB: 'france',
          action: DebugDiplomacyAction.alliance,
        ),
      );

      final game = result.game;
      expect(game, isNotNull);
      expect(getRelation(game!, 'england', 'france')?.formalAlliance, isTrue);
    });

    test('AC3: war rejected when a formal alliance exists', () {
      final game = _buildGame(
        relations: const [
          DiplomacyRelation(
            factionId1: 'england',
            factionId2: 'france',
            formalAlliance: true,
          ),
        ],
      );
      final result = applyDebugSetDiplomacyRelation(
        currentGame: game,
        event: _event(
          factionA: 'england',
          factionB: 'france',
          action: DebugDiplomacyAction.war,
        ),
      );

      expect(result.game, isNull);
      expect(result.message, contains('formal alliance'));
    });

    test('AC4: per-turn quota rejects a second mutation for the same pair', () {
      final first = applyDebugSetDiplomacyRelation(
        currentGame: _buildGame(),
        event: _event(factionB: 'ireland', action: DebugDiplomacyAction.war),
      );
      expect(first.game, isNotNull);

      final second = applyDebugSetDiplomacyRelation(
        currentGame: first.game,
        event: _event(factionB: 'ireland', action: DebugDiplomacyAction.peace),
      );

      expect(second.game, isNull);
      expect(second.message,
          contains('already used debug diplomacy for this pair this turn'));
    });

    test('AC5: quota survives a save/load round trip', () {
      final first = applyDebugSetDiplomacyRelation(
        currentGame: _buildGame(),
        event: _event(factionB: 'ireland', action: DebugDiplomacyAction.war),
      );
      expect(first.game, isNotNull);

      final reloaded = Game.fromJson(first.game!.toJson());
      expect(
        reloaded.debugDiplomacyUsedPairKeys.contains(pairKey('england', 'ireland')),
        isTrue,
      );

      final third = applyDebugSetDiplomacyRelation(
        currentGame: reloaded,
        event: _event(factionB: 'ireland', action: DebugDiplomacyAction.peace),
      );
      expect(third.game, isNull);
      expect(third.message, contains('already used debug diplomacy'));
    });

    test('AC6: command rejected outside the Orders phase', () {
      final result = applyDebugSetDiplomacyRelation(
        currentGame: _buildGame(phase: TurnPhase.diplomacy),
        event: _event(factionB: 'ireland', action: DebugDiplomacyAction.war),
      );

      expect(result.game, isNull);
      expect(result.message, contains('Orders phase'));
    });

    test('AC7: consulate overture is created from initiator toward target', () {
      final result = applyDebugSetDiplomacyRelation(
        currentGame: _buildGame(),
        event:
            _event(factionB: 'ireland', action: DebugDiplomacyAction.consulate),
      );

      final game = result.game;
      expect(game, isNotNull);
      final overture = getOverture(game!, 'england', 'ireland');
      expect(overture, isNotNull);
      expect(overture!.stage, OvertureStage.tradeConsulate);
    });

    test('AC8: ftp set with mutual embassy overtures', () {
      final game = _buildGame(
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
      );
      final result = applyDebugSetDiplomacyRelation(
        currentGame: game,
        event: _event(factionB: 'france', action: DebugDiplomacyAction.ftp),
      );

      final next = result.game;
      expect(next, isNotNull);
      expect(hasFtpPartnership(next!, 'england', 'france'), isTrue);
    });

    test('AC9: ftp rejected when there is no embassy overture', () {
      final result = applyDebugSetDiplomacyRelation(
        currentGame: _buildGame(),
        event: _event(factionB: 'france', action: DebugDiplomacyAction.ftp),
      );

      expect(result.game, isNull);
      expect(result.message, contains('embassy'));
    });

    test('AC10: war clears overtures + FTP and logs side-effect events', () {
      final game = _buildGame(
        overtures: const [
          OvertureState(
            gpId: 'england',
            targetId: 'ireland',
            stage: OvertureStage.tradeConsulate,
          ),
        ],
        ftpKeys: {pairKey('england', 'ireland')},
      );
      final result = applyDebugSetDiplomacyRelation(
        currentGame: game,
        event: _event(factionB: 'ireland', action: DebugDiplomacyAction.war),
      );

      final next = result.game;
      expect(next, isNotNull);
      expect(getOverture(next!, 'england', 'ireland'), isNull);
      expect(hasFtpPartnership(next, 'england', 'ireland'), isFalse);
      final types = next.diplomaticHistoryEvents.map((e) => e.type).toSet();
      expect(types, contains(DiplomaticEventType.declareWar));
      expect(types, contains(DiplomaticEventType.agreementsClearedOnWar));
      expect(types, contains(DiplomaticEventType.ftpBroken));
    });

    test('AC11: unknown faction produces a not-found error', () {
      final result = applyDebugSetDiplomacyRelation(
        currentGame: _buildGame(),
        event: _event(factionB: 'Atlantis', action: DebugDiplomacyAction.war),
      );

      expect(result.game, isNull);
      expect(result.message, 'Faction not found: Atlantis');
    });

    test('AC12: self-target is rejected', () {
      final result = applyDebugSetDiplomacyRelation(
        currentGame: _buildGame(),
        event: _event(
          factionA: 'england',
          factionB: 'england',
          action: DebugDiplomacyAction.war,
        ),
      );

      expect(result.game, isNull);
      expect(result.message, contains('cannot set a relation with itself'));
    });

    test('AC14: display name resolution (case-insensitive)', () {
      final result = applyDebugSetDiplomacyRelation(
        currentGame: _buildGame(),
        event: _event(
          factionB: 'zulu kingdom',
          action: DebugDiplomacyAction.war,
        ),
      );

      final game = result.game;
      expect(game, isNotNull);
      expect(getRelation(game!, 'england', 'zulu')?.state, RelationState.atWar);
    });

    test('AC15: war rejected when already at war (no re-triggered effects)', () {
      final game = _buildGame(
        relations: const [
          DiplomacyRelation(
            factionId1: 'england',
            factionId2: 'ireland',
            state: RelationState.atWar,
          ),
        ],
      );
      final result = applyDebugSetDiplomacyRelation(
        currentGame: game,
        event: _event(factionB: 'ireland', action: DebugDiplomacyAction.war),
      );

      expect(result.game, isNull);
      expect(result.message, contains('already at war'));
    });

    test('alliance rejected when a participant is not a Great Power', () {
      final result = applyDebugSetDiplomacyRelation(
        currentGame: _buildGame(),
        event:
            _event(factionB: 'ireland', action: DebugDiplomacyAction.alliance),
      );

      expect(result.game, isNull);
      expect(result.message, contains('Great Power'));
    });

    test('peace rejected when already at peace', () {
      final result = applyDebugSetDiplomacyRelation(
        currentGame: _buildGame(),
        event: _event(factionB: 'ireland', action: DebugDiplomacyAction.peace),
      );

      expect(result.game, isNull);
      expect(result.message, contains('already at peace'));
    });

    test('no_alliance succeeds as a no-op when no alliance exists', () {
      final result = applyDebugSetDiplomacyRelation(
        currentGame: _buildGame(),
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
      final game = _buildGame(
        relations: const [
          DiplomacyRelation(
            factionId1: 'england',
            factionId2: 'france',
            formalAlliance: true,
          ),
        ],
      );
      final result = applyDebugSetDiplomacyRelation(
        currentGame: game,
        event: _event(
          factionA: 'england',
          factionB: 'france',
          action: DebugDiplomacyAction.noAlliance,
        ),
      );

      final next = result.game;
      expect(next, isNotNull);
      expect(getRelation(next!, 'england', 'france')?.formalAlliance, isFalse);
      expect(
        next.diplomaticHistoryEvents
            .any((e) => e.type == DiplomaticEventType.allianceBroken),
        isTrue,
      );
    });

    test('clear_overture removes an existing overture', () {
      final game = _buildGame(
        overtures: const [
          OvertureState(
            gpId: 'england',
            targetId: 'ireland',
            stage: OvertureStage.embassy,
          ),
        ],
      );
      final result = applyDebugSetDiplomacyRelation(
        currentGame: game,
        event: _event(
          factionB: 'ireland',
          action: DebugDiplomacyAction.clearOverture,
        ),
      );

      final next = result.game;
      expect(next, isNotNull);
      expect(getOverture(next!, 'england', 'ireland'), isNull);
    });
  });
}
