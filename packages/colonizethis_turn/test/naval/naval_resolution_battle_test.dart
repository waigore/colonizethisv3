import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/colonizethis_turn_testing.dart';

void main() {
  BattleContextSea battle({
    String side1Owner = 'gp1',
    String side2Owner = 'gp2',
  }) =>
      BattleContextSea(
        seaZoneId: 'sea|z1',
        side1: NavalBattleSide(
          ownerId: side1Owner,
          ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
          mission: FleetMission.none,
        ),
        side2: NavalBattleSide(
          ownerId: side2Owner,
          ships: const [ShipInstance(id: 's2', typeId: 'carrack')],
          mission: FleetMission.none,
        ),
      );

  Game navalDialogueGame() => TestFixtures.minimalGame(
        id: 'naval-battle',
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI Victor', isHuman: false),
          Player(id: 'gp3', displayName: 'AI Loser', isHuman: false),
        ],
      );

  group('navalBattleWinnerOwnerId', () {
    test('side1Victory returns side1 owner', () {
      final ctx = battle();
      expect(
        navalBattleWinnerOwnerId(NavalBattleOutcome.side1Victory, ctx),
        'gp1',
      );
    });

    test('side2Victory returns side2 owner', () {
      final ctx = battle();
      expect(
        navalBattleWinnerOwnerId(NavalBattleOutcome.side2Victory, ctx),
        'gp2',
      );
    });

    test('stalemate and mutualDestruction return null', () {
      final ctx = battle();
      expect(
        navalBattleWinnerOwnerId(NavalBattleOutcome.stalemate, ctx),
        isNull,
      );
      expect(
        navalBattleWinnerOwnerId(NavalBattleOutcome.mutualDestruction, ctx),
        isNull,
      );
    });
  });

  group('applyNavalBattleVictoryDossierAndDialogue', () {
    test('returns unchanged state when neither side is eliminated', () {
      final state = navalDialogueGame();
      final ctx = battle(side1Owner: 'gp2', side2Owner: 'gp3');
      final result = const NavalBattleResult(
        survivingShipsSide1: [ShipInstance(id: 's1', typeId: 'carrack')],
        survivingShipsSide2: [ShipInstance(id: 's2', typeId: 'carrack')],
      );

      final next = applyNavalBattleVictoryDossierAndDialogue(
        state: state,
        battle: ctx,
        result: result,
        turn: 3,
        battleIndex: 0,
        seedAfterBattle: 42,
      );

      expect(identical(next, state), isTrue);
    });

    test('side1 victory adds dossier evidence and invokes dialogue callback', () {
      final state = navalDialogueGame();
      final ctx = battle(side1Owner: 'gp2', side2Owner: 'gp3');
      final result = NavalBattleResult(
        survivingShipsSide1: const [ShipInstance(id: 's1', typeId: 'carrack')],
        survivingShipsSide2: const [],
        outcome: NavalBattleOutcome.side1Victory,
      );
      final dialogue = <DialogueEvent>[];

      final next = applyNavalBattleVictoryDossierAndDialogue(
        state: state,
        battle: ctx,
        result: result,
        turn: 3,
        battleIndex: 1,
        seedAfterBattle: 99,
        onDialogue: dialogue.add,
      );

      expect(next.dossierEvidenceEntries, isNotEmpty);
      expect(dialogue, isNotEmpty);
      expect(
        dialogue.any((e) => e.situation == 'battle_lost' && e.leaderId == 'gp3'),
        isTrue,
      );
    });

    test('side2 victory applies dossier without dialogue callback', () {
      final state = navalDialogueGame();
      final ctx = battle(side1Owner: 'gp2', side2Owner: 'gp3');
      final result = NavalBattleResult(
        survivingShipsSide1: const [],
        survivingShipsSide2: const [ShipInstance(id: 's2', typeId: 'carrack')],
        outcome: NavalBattleOutcome.side2Victory,
      );

      final next = applyNavalBattleVictoryDossierAndDialogue(
        state: state,
        battle: ctx,
        result: result,
        turn: 4,
        battleIndex: 2,
        seedAfterBattle: 7,
      );

      expect(next.dossierEvidenceEntries, isNotEmpty);
    });
  });
}
