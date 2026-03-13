import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/src/diplomacy/diplomacy_relation_updates.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('applyGrantAidModifier', () {
    test('updates existing relation when pair already present', () {
      final relations = [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          score: 50,
          level: RelationLevel.neutral,
        ),
      ];
      final result = applyGrantAidModifier(
        relations: relations,
        gpId: 'gp1',
        targetId: 'gp2',
        turn: 2,
      );
      expect(result.length, 1);
      expect(result[0].score, 55);
      expect(result[0].lastInteractionTurn, 2);
    });
  });

  group('applySubsidyBoost', () {
    test('updates existing relation when pair already present', () {
      final relations = [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          score: 60,
          level: RelationLevel.friendly,
        ),
      ];
      final result = applySubsidyBoost(
        relations: relations,
        payerId: 'gp1',
        targetId: 'gp2',
        boost: 10,
        turn: 3,
      );
      expect(result.length, 1);
      expect(result[0].score, 70);
      expect(result[0].lastInteractionTurn, 3);
    });
  });
}
