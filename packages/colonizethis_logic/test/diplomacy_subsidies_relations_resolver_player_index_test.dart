import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/diplomacy/diplomacy_resolver.dart';
import 'package:colonizethis_logic/src/diplomacy/diplomacy_subsidies_relations_resolver.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('diplomacy subsidies player index map (Refs #2394)', () {
    test('applyRelationModifiersAndUpdateScores deducts GrantAid via player index', () {
      var game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true, treasury: 2000),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor 1'),
        ],
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.embassy,
            sinceTurn: 0,
          ),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            score: 50,
            level: RelationLevel.neutral,
          ),
        ],
      );

      final after = applyRelationModifiersAndUpdateScores(
        game,
        {
          'gp1': [
            const DiplomaticOrder(
              type: DiplomaticOrderType.grantAid,
              targetFactionId: 'minor1',
              amount: 1000,
            ),
          ],
        },
        1,
      );

      expect(after.playerById('gp1')!.treasury, 1000);
    });

    test('processOngoingSubsidies GP target treasury transfer uses player index', () {
      var game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true, treasury: 5000),
          Player(id: 'gp2', displayName: 'GP2', isHuman: true, treasury: 1000),
        ],
        subsidyStates: const [
          SubsidyState(
            payerId: 'gp1',
            targetId: 'gp2',
            amountPerTurn: 500,
          ),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 50,
            level: RelationLevel.neutral,
          ),
        ],
      );

      final membership = DiplomacyFactionMembership.from(game);
      final after = processOngoingSubsidies(
        game,
        2,
        factionMembership: membership,
      );

      expect(after.playerById('gp1')!.treasury, 4500);
      expect(after.playerById('gp2')!.treasury, 1500);
    });
  });
}
