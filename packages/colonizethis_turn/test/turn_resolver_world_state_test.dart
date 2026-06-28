import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('TurnResolver (WorldState)', () {
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
      final movementIndex = turnResolutionSequence.indexOf(TurnPhase.movement);
      final diplomacyIndex = turnResolutionSequence.indexOf(TurnPhase.diplomacy);
      final researchIndex = turnResolutionSequence.indexOf(TurnPhase.research);
      final upgradeIndex = turnResolutionSequence.indexOf(
        TurnPhase.minorRegimentUpgrade,
      );
      final navalCombatIndex = turnResolutionSequence.indexOf(
        TurnPhase.navalInterceptionCombat,
      );
      final landCombatIndex = turnResolutionSequence.indexOf(TurnPhase.combat);
      expect(movementIndex, greaterThanOrEqualTo(0));
      expect(diplomacyIndex, greaterThanOrEqualTo(0));
      expect(researchIndex, greaterThanOrEqualTo(0));
      expect(diplomacyIndex, lessThan(researchIndex));
      expect(researchIndex, lessThan(movementIndex));
      expect(upgradeIndex, greaterThan(movementIndex));
      expect(upgradeIndex, lessThan(navalCombatIndex));
      expect(upgradeIndex, lessThan(landCombatIndex));
      expect(turnResolutionSequence.last, TurnPhase.endOfTurn);
    });
  });
}
