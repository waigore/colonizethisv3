import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('TurnState', () {
    test('toJson/fromJson round-trip', () {
      const s = TurnState(phase: TurnPhase.endOfTurn, turnNumber: 5);
      final json = s.toJson();
      expect(TurnState.fromJson(json).phase, TurnPhase.endOfTurn);
      expect(TurnState.fromJson(json).turnNumber, 5);
    });
    test('copyWith', () {
      const s = TurnState(phase: TurnPhase.orders, turnNumber: 1);
      final s2 = s.copyWith(turnNumber: 2);
      expect(s2.turnNumber, 2);
      expect(s2.phase, TurnPhase.orders);
    });
    test('equality', () {
      const a = TurnState(phase: TurnPhase.endOfTurn, turnNumber: 1);
      const b = TurnState(phase: TurnPhase.endOfTurn, turnNumber: 1);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
    test('all phases round-trip', () {
      for (final phase in TurnPhase.values) {
        final s = TurnState(phase: phase, turnNumber: 0);
        expect(TurnState.fromJson(s.toJson()).phase, phase);
      }
    });
    test('fromJson rejects unknown phase string', () {
      expect(
        () => TurnState.fromJson({'phase': 'notARealPhase', 'turnNumber': 0}),
        throwsArgumentError,
      );
    });
  });
}
