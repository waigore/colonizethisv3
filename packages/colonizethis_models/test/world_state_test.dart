import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('WorldState', () {
    test('toJson/fromJson round-trip', () {
      final state = WorldState(
        turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 3),
        oldWorld: const RegionData(
          provinces: [
            Province(id: 'p1', regionId: 'oldWorld', ownerId: 'player1'),
          ],
          units: [],
        ),
        newWorld: const RegionData(),
      );
      final state2 = WorldState.fromJson(state.toJson());
      expect(state2.turnState.turnNumber, 3);
      expect(state2.oldWorld.provinces.length, 1);
      expect(state2.oldWorld.provinces.first.id, 'p1');
    });
    test('copyWith', () {
      final state = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      );
      final state2 = state.copyWith(
        turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 2),
      );
      expect(state2.turnState.turnNumber, 2);
    });
    test('equality', () {
      final state = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      );
      final state2 = WorldState.fromJson(state.toJson());
      expect(state, state2);
      expect(state.hashCode, state2.hashCode);
    });
    test(
      'fromJson migrates legacy local sea-zone tile buckets to prefixed keys',
      () {
        const regionId = 'oldWorld';
        const localSeaId = 's1';
        const prefixedSeaId = '$regionId|$localSeaId';
        const seaTile = '$regionId|$localSeaId|0|0';
        const landTile = '$regionId|p1|1|1';
        final json = <String, dynamic>{
          'turnState': const TurnState(
            phase: TurnPhase.orders,
            turnNumber: 1,
          ).toJson(),
          'oldWorld': const RegionData(
            provinces: [Province(id: '$regionId|p1', regionId: regionId)],
          ).toJson(),
          'newWorld': const RegionData().toJson(),
          'tileKeysByRegionAndProvince': {
            regionId: {
              localSeaId: [seaTile],
              'p1': [landTile],
            },
          },
        };

        final state = WorldState.fromJson(json);
        final regionBuckets = state.tileKeysByRegionAndProvince[regionId]!;
        expect(regionBuckets[prefixedSeaId], [seaTile]);
        expect(regionBuckets.containsKey(localSeaId), isFalse);
        expect(regionBuckets['p1'], [landTile]);
      },
    );

    test('fromJson accepts canonical prefixed sea-zone tile buckets', () {
      const regionId = 'oldWorld';
      const localSeaId = 's1';
      const prefixedSeaId = '$regionId|$localSeaId';
      const seaTile = '$regionId|$localSeaId|0|0';
      final json = <String, dynamic>{
        'turnState': const TurnState(
          phase: TurnPhase.orders,
          turnNumber: 1,
        ).toJson(),
        'oldWorld': const RegionData(
          provinces: [Province(id: '$regionId|p1', regionId: regionId)],
        ).toJson(),
        'newWorld': const RegionData().toJson(),
        'tileKeysByRegionAndProvince': {
          regionId: {
            prefixedSeaId: [seaTile],
          },
        },
      };

      final state = WorldState.fromJson(json);
      expect(state.tileKeysByRegionAndProvince[regionId]?[prefixedSeaId], [
        seaTile,
      ]);
    });
  });
}
