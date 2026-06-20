import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import 'package:ga_runner/ga_runner.dart';

AiProfile _profile(String id, {Map<String, num>? overrides}) {
  final base = seedAiProfilesById['victoria']!;
  final params = Map<String, num>.from(base.parameters);
  if (overrides != null) {
    params.addAll(overrides);
  }
  return AiProfile(
    schemaVersion: kAiProfileSchemaVersion,
    profileId: id,
    displayName: id,
    parameters: Map<String, num>.unmodifiable(params),
  );
}

void main() {
  group('uniformCrossover', () {
    test('each parameter equals one parent and stays in bounds', () {
      final rng = math.Random(42);
      final a = _profile('a', overrides: {'personalityDomainWeights.economy': 80});
      final b = _profile('b', overrides: {'personalityDomainWeights.economy': 20});
      final child = uniformCrossover(a, b, 'child', rng);
      for (final param in AiParameterRegistry.allParams) {
        final value = child.parameters[param.name]!;
        expect(value >= param.minValue && value <= param.maxValue, isTrue);
        final fromA = a.parameters[param.name];
        final fromB = b.parameters[param.name];
        expect(value == fromA || value == fromB, isTrue);
      }
    });

    test('is deterministic for fixed RNG seed', () {
      final a = _profile('a');
      final b = _profile('b');
      final c1 = uniformCrossover(a, b, 'child', math.Random(7));
      final c2 = uniformCrossover(a, b, 'child', math.Random(7));
      expect(c1.parameters, c2.parameters);
    });
  });

  group('mutateProfile', () {
    test('clamps mutated values to registry bounds', () {
      final profile = _profile('p');
      final mutated = mutateProfile(profile, math.Random(99));
      for (final param in AiParameterRegistry.allParams) {
        final value = mutated.parameters[param.name]!;
        expect(value >= param.minValue && value <= param.maxValue, isTrue);
        if (param.isInteger) {
          expect(value, equals(value.round()));
        }
      }
    });
  });

  group('tournamentPick', () {
    test('picks highest fitness among candidates', () {
      final fitness = <double>[1, 5, 3, 2];
      final pick = tournamentPick(fitness, <int>[0, 2, 3], math.Random(1));
      expect(pick, 2);
    });
  });
}
