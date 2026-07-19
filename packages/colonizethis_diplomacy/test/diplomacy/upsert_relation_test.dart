// Ported from colonizethis_logic (Refs #4090 Slice D).
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('upsertRelation', () {
    test('provinceCountOwnedBy includes newWorld provinces', () {
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'minor1'),
          ]),
          newWorld: RegionData(provinces: [
            Province(id: 'newWorld|n1', regionId: 'newWorld', ownerId: 'minor1'),
            Province(id: 'newWorld|n2', regionId: 'newWorld', ownerId: 'minor1'),
          ]),
        ),
        players: const [],
      );
      expect(provinceCountOwnedBy(game, 'minor1'), 3);
    });

    test('shipCountForFaction sums shipTypeIds length over owned fleets', () {
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [
            Fleet(id: 'f1', ownerId: 'gp1', regionId: 'oldWorld', shipTypeIds: ['carrack', 'carrack', 'fluyte']),
            Fleet(id: 'f2', ownerId: 'gp2', regionId: 'oldWorld', shipTypeIds: ['carrack']),
          ],
        ),
        players: const [],
      );
      expect(shipCountForFaction(game, 'gp1'), 3);
      expect(shipCountForFaction(game, 'gp2'), 1);
      expect(shipCountForFaction(game, 'gp3'), 0);
    });

    test('greatPowerPowerScore uses provinces, regiment strength, ships per SPEC', () {
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
              Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'gp1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(id: 'f1', ownerId: 'gp1', regionId: 'oldWorld', shipTypeIds: ['carrack']),
          ],
        ),
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: false)],
      );
      // 2 provinces * 10 + 0 regiment + 1 ship * 5 = 25
      expect(greatPowerPowerScore(game, 'gp1'), 25);
    });
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
