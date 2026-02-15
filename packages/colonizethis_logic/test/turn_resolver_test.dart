import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:test/test.dart';

void main() {
  group('TurnResolver', () {
    test('resolve advances turn number', () {
      final state = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      );
      final next = resolveTurn(state);
      expect(next.turnState.turnNumber, 2);
      expect(next.turnState.phase, TurnPhase.orders);
    });

    test('resolve returns new state, does not mutate input', () {
      final state = WorldState(
        turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 5),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      );
      final next = resolveTurn(state);
      expect(state.turnState.turnNumber, 5);
      expect(next.turnState.turnNumber, 6);
    });

    test('phase sequence is defined', () {
      expect(turnResolutionSequence, isNotEmpty);
      expect(turnResolutionSequence.last, TurnPhase.endOfTurn);
    });
  });
}
