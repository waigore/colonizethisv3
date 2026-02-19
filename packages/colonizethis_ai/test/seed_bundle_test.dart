import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('AISeedBundle', () {
    test('fromTurnSeed is deterministic', () {
      final a = AISeedBundle.fromTurnSeed(12345);
      final b = AISeedBundle.fromTurnSeed(12345);
      expect(a.perceptionSeed, b.perceptionSeed);
      expect(a.goalSeed, b.goalSeed);
      expect(a.tacticalSeed, b.tacticalSeed);
    });
    test('different turnSeed produces different sub-seeds', () {
      final a = AISeedBundle.fromTurnSeed(1);
      final b = AISeedBundle.fromTurnSeed(2);
      expect(a.perceptionSeed, isNot(b.perceptionSeed));
      expect(a.tacticalSeed, isNot(b.tacticalSeed));
    });
  });
}
