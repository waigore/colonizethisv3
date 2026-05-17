import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('WorldState', () {
    test('toJson/fromJson round-trip', () {
      final state = WorldState(
        turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 3),
        oldWorld: const RegionData(
          provinces: [
            Province(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              ownerId: 'player1',
            ),
          ],
          units: [],
        ),
        newWorld: const RegionData(),
      );
      final state2 = WorldState.fromJson(state.toJson());
      expect(state2.turnState.turnNumber, 3);
      expect(state2.oldWorld.provinces.length, 1);
      expect(state2.oldWorld.provinces.first.id, 'oldWorld|p1');
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
    test('fromJson hard-fails on legacy local sea-zone tile bucket keys', () {
      const regionId = 'oldWorld';
      const localSeaId = 's1';
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
            localSeaId: [seaTile],
          },
        },
      };

      expect(
        () => WorldState.fromJson(json),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('legacy local sea-zone bucket key'),
          ),
        ),
      );
    });

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

    test('fromJson rejects unprefixed province ids in region provinces', () {
      final json = <String, dynamic>{
        'turnState': const TurnState(
          phase: TurnPhase.orders,
          turnNumber: 1,
        ).toJson(),
        'oldWorld': const RegionData(
          provinces: [Province(id: 'oldWorld|p1', regionId: 'oldWorld')],
        ).toJson(),
        'newWorld': const RegionData(
          provinces: [Province(id: 'newWorld|n1', regionId: 'newWorld')],
        ).toJson(),
      };
      (json['oldWorld'] as Map<String, dynamic>)['provinces'] = [
        {'id': 'p1', 'regionId': 'oldWorld'},
      ];
      expect(() => WorldState.fromJson(json), throwsA(isA<ArgumentError>()));
    });
  });
}
