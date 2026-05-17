import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/diplomacy/diplomacy_subsidies_relations_resolver.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'diplomacy_resolver_phase_test_support.dart';

void main() {
  group(
    'applyRelationModifiersAndUpdateScores subsidy pair index (Refs #2394)',
    () {
      test(
        'two SetSubsidy toward same target in one pass keeps one state with final amount',
        () {
          var game = diplomacyResolverPhaseTestBaseGame().copyWith(
            players: [
              const Player(
                id: 'gp1',
                displayName: 'GP1',
                isHuman: true,
                treasury: 10000,
              ).copyWith(
                techUnlocked: const {kTechIdDiplomaticExpertise: true},
              ),
            ],
            overtureStates: const [
              OvertureState(
                gpId: 'gp1',
                targetId: 'minor1',
                stage: OvertureStage.tradeConsulate,
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

          final after = applyRelationModifiersAndUpdateScores(game, {
            'gp1': [
              const DiplomaticOrder(
                type: DiplomaticOrderType.setSubsidy,
                targetFactionId: 'minor1',
                amount: 500,
              ),
              const DiplomaticOrder(
                type: DiplomaticOrderType.setSubsidy,
                targetFactionId: 'minor1',
                amount: 800,
              ),
            ],
          }, 1);

          expect(after.subsidyStates, hasLength(1));
          final s = after.subsidyStates.single;
          expect(s.payerId, 'gp1');
          expect(s.targetId, 'minor1');
          expect(s.amountPerTurn, 800);
          final gp1 = after.players.where((p) => p.id == 'gp1').single;
          expect(gp1.treasury, 10000 - 500 - 800);
        },
      );

      test(
        'two SetSubsidy toward different targets in one pass records both',
        () {
          var game = diplomacyResolverPhaseTestBaseGame().copyWith(
            minorNations: const [
              MinorNation(id: 'minor1', displayName: 'Minor 1'),
              MinorNation(id: 'minor2', displayName: 'Minor 2'),
            ],
            players: [
              const Player(
                id: 'gp1',
                displayName: 'GP1',
                isHuman: true,
                treasury: 10000,
              ).copyWith(
                techUnlocked: const {kTechIdDiplomaticExpertise: true},
              ),
            ],
            overtureStates: const [
              OvertureState(
                gpId: 'gp1',
                targetId: 'minor1',
                stage: OvertureStage.tradeConsulate,
                sinceTurn: 0,
              ),
              OvertureState(
                gpId: 'gp1',
                targetId: 'minor2',
                stage: OvertureStage.tradeConsulate,
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
              DiplomacyRelation(
                factionId1: 'gp1',
                factionId2: 'minor2',
                score: 50,
                level: RelationLevel.neutral,
              ),
            ],
          );

          final after = applyRelationModifiersAndUpdateScores(game, {
            'gp1': [
              const DiplomaticOrder(
                type: DiplomaticOrderType.setSubsidy,
                targetFactionId: 'minor1',
                amount: 300,
              ),
              const DiplomaticOrder(
                type: DiplomaticOrderType.setSubsidy,
                targetFactionId: 'minor2',
                amount: 400,
              ),
            ],
          }, 1);

          expect(after.subsidyStates, hasLength(2));
          final byTarget = {
            for (final x in after.subsidyStates) x.targetId: x.amountPerTurn,
          };
          expect(byTarget['minor1'], 300);
          expect(byTarget['minor2'], 400);
        },
      );

      test(
        'pre-existing subsidy row is updated by later SetSubsidy in same pass',
        () {
          var game = diplomacyResolverPhaseTestBaseGame().copyWith(
            players: [
              const Player(
                id: 'gp1',
                displayName: 'GP1',
                isHuman: true,
                treasury: 10000,
              ).copyWith(
                techUnlocked: const {kTechIdDiplomaticExpertise: true},
              ),
            ],
            overtureStates: const [
              OvertureState(
                gpId: 'gp1',
                targetId: 'minor1',
                stage: OvertureStage.tradeConsulate,
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
            subsidyStates: const [
              SubsidyState(
                payerId: 'gp1',
                targetId: 'minor1',
                amountPerTurn: 200,
              ),
            ],
          );

          final after = applyRelationModifiersAndUpdateScores(game, {
            'gp1': [
              const DiplomaticOrder(
                type: DiplomaticOrderType.setSubsidy,
                targetFactionId: 'minor1',
                amount: 600,
              ),
            ],
          }, 1);

          expect(after.subsidyStates, hasLength(1));
          expect(after.subsidyStates.single.amountPerTurn, 600);
        },
      );
    },
  );
}
