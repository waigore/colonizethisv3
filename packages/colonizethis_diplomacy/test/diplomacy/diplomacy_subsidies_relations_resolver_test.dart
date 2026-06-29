import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/src/game_player_lookup.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
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

  group('processOngoingSubsidies (percent model, Refs #3753 R3)', () {
    Game gameWith({
      required RelationState state,
      required List<OvertureState> overtures,
    }) => Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      players: const [
        Player(id: 'gp1', displayName: 'GP1', isHuman: true, treasury: 10_000),
      ],
      minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
      diplomacyRelations: [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'minor1',
          state: state,
          score: 50,
        ),
      ],
      overtureStates: overtures,
      subsidyStates: const [
        SubsidyState(payerId: 'gp1', targetId: 'minor1', percent: 10),
      ],
    );

    const embassy = OvertureState(
      gpId: 'gp1',
      targetId: 'minor1',
      stage: OvertureStage.embassy,
      sinceTurn: 0,
    );

    test('subsidy is retained at peace with an Embassy and charges no treasury',
        () {
      final game = gameWith(
        state: RelationState.atPeace,
        overtures: const [embassy],
      );
      final membership = DiplomacyFactionMembership.from(game);
      final after = processOngoingSubsidies(game, 2,
          factionMembership: membership);
      expect(after.subsidyStates.length, 1);
      expect(after.subsidyStates.single.percent, 10);
      expect(after.playerById('gp1')!.treasury, 10_000);
    });

    test('subsidy is cleared when the payer loses the Embassy (R3.5)', () {
      final game = gameWith(
        state: RelationState.atPeace,
        overtures: const [],
      );
      final membership = DiplomacyFactionMembership.from(game);
      final after = processOngoingSubsidies(game, 2,
          factionMembership: membership);
      expect(after.subsidyStates, isEmpty);
    });

    test('subsidy is cleared when the pair is at war', () {
      final game = gameWith(
        state: RelationState.atWar,
        overtures: const [embassy],
      );
      final membership = DiplomacyFactionMembership.from(game);
      final after = processOngoingSubsidies(game, 2,
          factionMembership: membership);
      expect(after.subsidyStates, isEmpty);
    });
  });
}
