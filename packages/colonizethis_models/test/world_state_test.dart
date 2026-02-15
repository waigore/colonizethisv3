import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:test/test.dart';

void main() {
  group('WorldState', () {
    test('toJson/fromJson round-trip', () {
      final state = WorldState(
        turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 3),
        oldWorld: const RegionData(
          provinces: [Province(id: 'p1', regionId: 'oldWorld', ownerId: 'player1')],
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
  });
}
