import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/src/game_player_lookup.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_diplomacy/src/diplomacy/diplomacy_subsidies_relations_resolver.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('applyRelationModifiersAndUpdateScores', () {
    test('GrantAid deducts payer treasury using stable player row index', () {
      const startTreasury = 5000;
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'gp1',
            displayName: 'GP1',
            isHuman: true,
            treasury: startTreasury,
            techUnlocked: const {kTechIdDiplomaticExpertise: true},
          ),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            state: RelationState.atPeace,
            score: 50,
          ),
        ],
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.embassy,
            sinceTurn: 0,
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
      expect(after.playerById('gp1')!.treasury, startTreasury - 1000);
    });
  });

  group('processOngoingSubsidies', () {
    test('GP target receives treasury transfer via indexed player row', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: [
          const Player(
            id: 'gp1',
            displayName: 'GP1',
            isHuman: true,
            treasury: 10_000,
          ),
          const Player(
            id: 'gp2',
            displayName: 'GP2',
            isHuman: false,
            treasury: 200,
          ),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            state: RelationState.atPeace,
            score: 0,
          ),
        ],
        subsidyStates: [
          SubsidyState(
            payerId: 'gp1',
            targetId: 'gp2',
            amountPerTurn: 500,
          ),
        ],
      );
      final membership = DiplomacyFactionMembership.from(game);
      final after = processOngoingSubsidies(
        game,
        2,
        factionMembership: membership,
      );
      expect(after.playerById('gp1')!.treasury, 10_000 - 500);
      expect(after.playerById('gp2')!.treasury, 200 + 500);
    });
  });
}
