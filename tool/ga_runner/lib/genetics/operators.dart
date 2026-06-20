import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';

/// Genetic operators for [AiProfile] tuning. SPEC/program/ga-runner.md.
/// Refs #3439.

const int kEliteCount = 2;
const int kTournamentSize = 3;
const double kMutationProbability = 0.05;
const double kMutationSigmaFraction = 0.05;

/// Picks the highest-fitness index from [candidates] using [rng].
int tournamentPick(List<double> fitnessByIndex, List<int> candidates, math.Random rng) {
  var best = candidates.first;
  var bestFitness = fitnessByIndex[best];
  for (var i = 1; i < candidates.length; i++) {
    final idx = candidates[i];
    final f = fitnessByIndex[idx];
    if (f > bestFitness) {
      best = idx;
      bestFitness = f;
    }
  }
  return best;
}

/// Uniform crossover: each parameter independently from parent A or B.
AiProfile uniformCrossover(
  AiProfile parentA,
  AiProfile parentB,
  String childProfileId,
  math.Random rng,
) {
  final childParams = <String, num>{};
  for (final param in AiParameterRegistry.allParams) {
    final fromA = rng.nextBool();
    final source = fromA ? parentA.parameters : parentB.parameters;
    childParams[param.name] = source[param.name] ?? param.defaultValue;
  }
  return AiProfile(
    schemaVersion: kAiProfileSchemaVersion,
    profileId: childProfileId,
    displayName: childProfileId,
    parameters: Map<String, num>.unmodifiable(childParams),
  );
}

/// Applies per-parameter mutation with Gaussian noise.
AiProfile mutateProfile(AiProfile profile, math.Random rng) {
  final next = Map<String, num>.from(profile.parameters);
  for (final param in AiParameterRegistry.allParams) {
    if (rng.nextDouble() >= kMutationProbability) continue;
    final current = next[param.name] ?? param.defaultValue;
    final range = param.maxValue - param.minValue;
    final sigma = kMutationSigmaFraction * range.toDouble();
    final noise = _gaussian(rng) * sigma;
    final mutated = current + noise;
    next[param.name] = _clampAndRound(param, mutated);
  }
  return AiProfile(
    schemaVersion: profile.schemaVersion,
    profileId: profile.profileId,
    displayName: profile.displayName,
    parameters: Map<String, num>.unmodifiable(next),
  );
}

num _clampAndRound(AiParameter param, num value) {
  final clamped = value.clamp(param.minValue, param.maxValue);
  return param.isInteger ? clamped.round() : clamped.toDouble();
}

double _gaussian(math.Random rng) {
  final u1 = rng.nextDouble().clamp(1e-12, 1.0);
  final u2 = rng.nextDouble();
  return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
}
