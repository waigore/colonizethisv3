import 'package:colonizethis_test/test.dart';

import 'package:ga_runner/ga_runner.dart';

/// FitnessScore value-object tests. SPEC/program/ga-fitness.md. Refs #3438.
void main() {
  group('FitnessScore', () {
    test('exposes the category and total scores it was built with', () {
      const score = FitnessScore(
        economic: 0.4,
        military: 0.3,
        diplomatic: 0.2,
        total: 0.9,
      );

      expect(score.economic, 0.4);
      expect(score.military, 0.3);
      expect(score.diplomatic, 0.2);
      expect(score.total, 0.9);
    });

    test('toString includes every component for diagnostic logging', () {
      const score = FitnessScore(
        economic: 0.1,
        military: 0.5,
        diplomatic: 0.25,
        total: 0.7,
      );

      final text = score.toString();
      expect(text, contains('economic: 0.1'));
      expect(text, contains('military: 0.5'));
      expect(text, contains('diplomatic: 0.25'));
      expect(text, contains('total: 0.7'));
    });
  });
}
