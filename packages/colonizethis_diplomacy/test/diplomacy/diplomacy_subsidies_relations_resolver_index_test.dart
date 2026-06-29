import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/src/game_player_lookup.dart';

import '../support/diplomacy_resolver_phase_test_support.dart';

void main() {
  group('applyRelationModifiersAndUpdateScores (Refs #2394 index maps)', () {
    test(
      'setSubsidy updates existing percent row without duplicate or cost',
      () {
        var game = diplomacyResolverPhaseTestBaseGame().copyWith(
          overtureStates: const [
            OvertureState(
              gpId: 'gp1',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
          subsidyStates: const [
            SubsidyState(
              payerId: 'gp1',
              targetId: 'minor1',
              percent: 5,
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
        final startTreasury = game.playerById('gp1')!.treasury;

        final out = applyRelationModifiersAndUpdateScores(game, {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.setSubsidy,
              targetFactionId: 'minor1',
              amount: 15,
            ),
          ],
        }, 1);

        expect(out.subsidyStates, hasLength(1));
        expect(out.subsidyStates.single.percent, 15);
        // Percent subsidies charge no treasury (Refs #3753 R3).
        expect(out.playerById('gp1')!.treasury, startTreasury);
      },
    );

    test('grantAid deduction uses stable player index map across orders', () {
      var game = diplomacyResolverPhaseTestBaseGame().copyWith(
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

      final out = applyRelationModifiersAndUpdateScores(game, {
        'gp1': const [
          DiplomaticOrder(
            type: DiplomaticOrderType.grantAid,
            targetFactionId: 'minor1',
            amount: 1000,
          ),
          DiplomaticOrder(
            type: DiplomaticOrderType.grantAid,
            targetFactionId: 'minor1',
            amount: 1000,
          ),
        ],
      }, 1);

      expect(out.playerById('gp1')!.treasury, 2000 - 2000);
    });
  });

  group('processOngoingSubsidies (percent model, Refs #3753 R3)', () {
    test('valid Minor subsidy with Embassy is retained and charges nothing', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true, treasury: 5000),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            score: 50,
            level: RelationLevel.neutral,
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
        subsidyStates: const [
          SubsidyState(payerId: 'gp1', targetId: 'minor1', percent: 10),
        ],
      );

      final membership = DiplomacyFactionMembership.from(game);
      final out = processOngoingSubsidies(
        game,
        2,
        factionMembership: membership,
      );

      expect(out.subsidyStates.single.percent, 10);
      expect(out.playerById('gp1')!.treasury, 5000);
    });
  });
}
