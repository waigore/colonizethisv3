import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';

import 'operators.dart';

/// One member of the GA population.
class PopulationMember {
  PopulationMember({
    required this.slotId,
    required this.profile,
    List<double>? fitnessHistory,
    this.generationsSurvived = 0,
  }) : fitnessHistory = fitnessHistory ?? <double>[];

  /// Stable slot id (`profile-000` …).
  final String slotId;
  AiProfile profile;
  final List<double> fitnessHistory;
  int generationsSurvived;
}

/// Loads seed profiles from [dir]. Throws [FormatException] when empty or invalid.
List<AiProfile> loadSeedProfilesFromDir(String dir) {
  final directory = Directory(dir);
  if (!directory.existsSync()) {
    throw FormatException('seed_profiles_dir not found: $dir');
  }
  final files = directory
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  if (files.isEmpty) {
    throw FormatException('seed_profiles_dir is empty: $dir');
  }
  final profiles = <AiProfile>[];
  for (final file in files) {
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('profile JSON must be an object');
      }
      profiles.add(AiProfile.fromJson(decoded));
    } on Object catch (e) {
      throw FormatException('failed to parse seed profile ${file.path}: $e');
    }
  }
  return profiles;
}

/// Builds the initial population: up to seven seeds plus mutated variants.
List<PopulationMember> buildInitialPopulation({
  required List<AiProfile> seeds,
  required int populationSize,
  required math.Random rng,
}) {
  if (seeds.isEmpty) {
    throw const FormatException('at least one seed profile is required');
  }
  final seedMembers = seeds.take(7).toList();
  final population = <PopulationMember>[];
  for (var i = 0; i < populationSize; i++) {
    final slotId = _slotId(i);
    if (i < seedMembers.length) {
      final seed = seedMembers[i];
      population.add(
        PopulationMember(
          slotId: slotId,
          profile: AiProfile(
            schemaVersion: seed.schemaVersion,
            profileId: slotId,
            displayName: seed.displayName,
            parameters: seed.parameters,
          ),
        ),
      );
    } else {
      final clone = seedMembers[rng.nextInt(seedMembers.length)];
      final mutated = mutateProfile(
        AiProfile(
          schemaVersion: clone.schemaVersion,
          profileId: slotId,
          displayName: slotId,
          parameters: clone.parameters,
        ),
        rng,
      );
      population.add(PopulationMember(slotId: slotId, profile: mutated));
    }
  }
  return population;
}

/// Produces the next generation from evaluated [current] members.
List<PopulationMember> evolvePopulation({
  required List<PopulationMember> current,
  required List<double> generationFitness,
  required math.Random rng,
}) {
  final indices = List<int>.generate(current.length, (i) => i);
  indices.sort(
    (a, b) => generationFitness[b].compareTo(generationFitness[a]),
  );

  final next = <PopulationMember>[];
  for (var e = 0; e < kEliteCount && e < indices.length; e++) {
    final elite = current[indices[e]];
    next.add(
      PopulationMember(
        slotId: elite.slotId,
        profile: elite.profile,
        fitnessHistory: List<double>.from(elite.fitnessHistory),
        generationsSurvived: elite.generationsSurvived + 1,
      ),
    );
  }

  while (next.length < current.length) {
    final parentAIdx = _tournamentIndex(generationFitness, current.length, rng);
    var parentBIdx = _tournamentIndex(generationFitness, current.length, rng);
    if (parentBIdx == parentAIdx && current.length > 1) {
      parentBIdx = (parentBIdx + 1) % current.length;
    }
    final slotId = _slotId(next.length);
    var child = uniformCrossover(
      current[parentAIdx].profile,
      current[parentBIdx].profile,
      slotId,
      rng,
    );
    child = mutateProfile(child, rng);
    next.add(PopulationMember(slotId: slotId, profile: child));
  }
  return next;
}

int _tournamentIndex(List<double> fitness, int length, math.Random rng) {
  final picks = <int>[];
  for (var i = 0; i < kTournamentSize; i++) {
    picks.add(rng.nextInt(length));
  }
  return tournamentPick(fitness, picks, rng);
}

String _slotId(int index) => 'profile-${index.toString().padLeft(3, '0')}';
