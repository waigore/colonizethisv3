import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

Game _twoGpGame({List<AllianceBreakCooldownState> cooldowns = const []}) {
  return Game(
    id: 'g',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 5),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'A', isHuman: true),
      Player(id: 'gp2', displayName: 'B', isHuman: false),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
        score: 80,
        formalAlliance: true,
      ),
    ],
    allianceBreakCooldowns: cooldowns,
  );
}

void main() {
  suppressLogsForTests();

  group('isAllianceBreakCooldownActive', () {
    test('active only on the break turn', () {
      final game = _twoGpGame(
        cooldowns: const [
          AllianceBreakCooldownState(
            factionId1: 'gp1',
            factionId2: 'gp2',
            sinceTurn: 5,
          ),
        ],
      );
      expect(isAllianceBreakCooldownActive(game, 'gp1', 'gp2'), isTrue);
      expect(isAllianceBreakCooldownActive(game, 'gp2', 'gp1'), isTrue);
      final nextTurn = game.copyWith(
        worldState: game.worldState.copyWith(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 6),
        ),
      );
      expect(isAllianceBreakCooldownActive(nextTurn, 'gp1', 'gp2'), isFalse);
    });
  });

  group('applyVoluntaryAllianceBreak', () {
    test('records cooldown and clears formal alliance', () {
      final game = _twoGpGame();
      final membership = DiplomacyFactionMembership.from(game);
      final next = applyVoluntaryAllianceBreak(
        game,
        breakerId: 'gp1',
        brokenWithAllyId: 'gp2',
        turn: 5,
        factionMembership: membership,
      );
      final rel = getRelation(next, 'gp1', 'gp2');
      expect(rel?.formalAlliance, isFalse);
      expect(next.allianceBreakCooldowns, hasLength(1));
      expect(next.allianceBreakCooldowns.single.sinceTurn, 5);
      expect(isAllianceBreakCooldownActive(next, 'gp1', 'gp2'), isTrue);
    });

    test('idempotent when no formal alliance remains', () {
      final game = _twoGpGame().copyWith(
        diplomacyRelations: const [
          DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2', score: 50),
        ],
      );
      final membership = DiplomacyFactionMembership.from(game);
      final next = applyVoluntaryAllianceBreak(
        game,
        breakerId: 'gp1',
        brokenWithAllyId: 'gp2',
        turn: 5,
        factionMembership: membership,
      );
      expect(identical(next, game), isTrue);
    });
  });
}
