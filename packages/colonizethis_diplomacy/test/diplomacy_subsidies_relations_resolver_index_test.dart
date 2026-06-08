import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_diplomacy/src/diplomacy/diplomacy_subsidies_relations_resolver.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/src/game_player_lookup.dart';

import 'support/diplomacy_resolver_phase_test_support.dart';

void main() {
  group('applyRelationModifiersAndUpdateScores (Refs #2394 index maps)', () {
    test(
      'setSubsidy updates existing row by payer+target without duplicate',
      () {
        var game = diplomacyResolverPhaseTestBaseGame().copyWith(
          overtureStates: const [
            OvertureState(
              gpId: 'gp1',
              targetId: 'minor1',
              stage: OvertureStage.tradeConsulate,
              sinceTurn: 0,
            ),
          ],
          subsidyStates: const [
            SubsidyState(
              payerId: 'gp1',
              targetId: 'minor1',
              amountPerTurn: 100,
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
              type: DiplomaticOrderType.setSubsidy,
              targetFactionId: 'minor1',
              amount: 200,
            ),
          ],
        }, 1);

        expect(out.subsidyStates, hasLength(1));
        expect(out.subsidyStates.single.amountPerTurn, 200);
        expect(out.playerById('gp1')!.treasury, 2000 - 200);
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

  group('processOngoingSubsidies (Refs #2394 player index map)', () {
    test('GP-to-GP subsidy credits target via O(1) player id index', () {
      final game = Game(
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
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 50,
            level: RelationLevel.neutral,
          ),
        ],
        subsidyStates: const [
          SubsidyState(payerId: 'gp1', targetId: 'gp2', amountPerTurn: 200),
        ],
      );

      final membership = DiplomacyFactionMembership.from(game);
      final out = processOngoingSubsidies(
        game,
        2,
        factionMembership: membership,
      );

      expect(out.playerById('gp1')!.treasury, 4800);
      expect(out.playerById('gp2')!.treasury, 1200);
    });
  });
}
