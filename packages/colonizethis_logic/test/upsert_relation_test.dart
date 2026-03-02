import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('upsertRelation', () {
    test('inserts new relation when pair absent', () {
      final relations = <DiplomacyRelation>[];
      final result = upsertRelation(relations, 'gp1', 'gp2', (existing) {
        expect(existing, isNull);
        return const DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          score: 60,
          level: RelationLevel.friendly,
        );
      });

      expect(result.length, 1);
      expect(result[0].factionId1, 'gp1');
      expect(result[0].factionId2, 'gp2');
      expect(result[0].score, 60);
    });

    test('updates existing relation when pair present', () {
      final relations = [
        const DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          score: 50,
          level: RelationLevel.neutral,
        ),
      ];
      final result = upsertRelation(relations, 'gp1', 'gp2', (existing) {
        expect(existing, isNotNull);
        expect(existing!.score, 50);
        return existing.copyWith(score: 80, level: RelationLevel.allied);
      });

      expect(result.length, 1);
      expect(result[0].score, 80);
      expect(result[0].level, RelationLevel.allied);
    });

    test('pair lookup is order-independent', () {
      final relations = [
        const DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          score: 50,
        ),
      ];

      final result = upsertRelation(relations, 'gp2', 'gp1', (existing) {
        expect(existing, isNotNull);
        return existing!.copyWith(score: 99);
      });

      expect(result.length, 1);
      expect(result[0].score, 99);
    });

    test('does not modify original list', () {
      final relations = [
        const DiplomacyRelation(factionId1: 'a', factionId2: 'b', score: 10),
      ];
      final result = upsertRelation(relations, 'a', 'b', (existing) {
        return existing!.copyWith(score: 90);
      });

      expect(relations[0].score, 10);
      expect(result[0].score, 90);
    });

    test('preserves unrelated relations', () {
      final relations = [
        const DiplomacyRelation(factionId1: 'a', factionId2: 'b', score: 10),
        const DiplomacyRelation(factionId1: 'c', factionId2: 'd', score: 20),
      ];
      final result = upsertRelation(relations, 'a', 'b', (existing) {
        return existing!.copyWith(score: 99);
      });

      expect(result.length, 2);
      expect(result[0].score, 99);
      expect(result[1].score, 20);
    });

    test('appends when inserting into non-empty list', () {
      final relations = [
        const DiplomacyRelation(factionId1: 'a', factionId2: 'b', score: 10),
      ];
      final result = upsertRelation(relations, 'c', 'd', (existing) {
        expect(existing, isNull);
        return const DiplomacyRelation(
          factionId1: 'c',
          factionId2: 'd',
          score: 50,
        );
      });

      expect(result.length, 2);
      expect(result[0].score, 10);
      expect(result[1].factionId1, 'c');
    });
  });
}
