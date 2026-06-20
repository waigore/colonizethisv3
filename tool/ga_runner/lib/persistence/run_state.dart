import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';

import '../config/ga_config.dart';
import '../genetics/population.dart';

/// Supported `run-state.json` schema version.
const int kGaRunStateSchemaVersion = 1;

/// Mid-generation evaluation checkpoint when SIGINT arrives during the 7-GP
/// stage after all 2-player games completed. Refs #3488.
class GaEvaluationCheckpoint {
  const GaEvaluationCheckpoint({
    required this.generation,
    required this.twoPlayerScores,
    required this.sevenGpScores,
    required this.profileIndex,
    required this.gameIndex,
  });

  /// Generation index being evaluated (not yet persisted as complete).
  final int generation;

  /// Per-slot successfully scored 2-player game totals.
  final Map<String, List<double>> twoPlayerScores;

  /// Per-slot successfully scored 7-GP game totals (may be partial).
  final Map<String, List<double>> sevenGpScores;

  /// Next profile index in the 7-GP loop.
  final int profileIndex;

  /// Next game index within [profileIndex]'s 7-GP stage.
  final int gameIndex;

  static const String stageSevenGp = 'seven_gp';

  Map<String, dynamic> toJson() => <String, dynamic>{
    'generation': generation,
    'evaluation_stage': stageSevenGp,
    'two_player_scores': twoPlayerScores.map(
      (k, v) => MapEntry(k, List<double>.from(v)),
    ),
    'seven_gp_scores': sevenGpScores.map(
      (k, v) => MapEntry(k, List<double>.from(v)),
    ),
    'profile_index': profileIndex,
    'game_index': gameIndex,
  };

  factory GaEvaluationCheckpoint.fromJson(Map<String, dynamic> json) {
    final stage = json['evaluation_stage'] as String?;
    if (stage != stageSevenGp) {
      throw FormatException(
        'unsupported evaluation_stage $stage (expected $stageSevenGp)',
      );
    }
    return GaEvaluationCheckpoint(
      generation: (json['generation'] as num).toInt(),
      twoPlayerScores: _readScoreMap(json['two_player_scores']),
      sevenGpScores: _readScoreMap(json['seven_gp_scores']),
      profileIndex: (json['profile_index'] as num).toInt(),
      gameIndex: (json['game_index'] as num).toInt(),
    );
  }

  static Map<String, List<double>> _readScoreMap(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('checkpoint score map must be an object');
    }
    return raw.map(
      (k, v) => MapEntry(
        k,
        (v as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
      ),
    );
  }
}

/// Serializable GA run state. SPEC/program/ga-runner.md.
class GaRunState {
  GaRunState({
    required this.runId,
    required this.config,
    required this.currentGeneration,
    required this.population,
    required this.bestOverall,
    required this.convergence,
    this.evaluationCheckpoint,
  });

  final String runId;
  final GaConfig config;
  final int currentGeneration;
  final List<PopulationMember> population;
  final GaBestOverall bestOverall;
  final GaConvergence convergence;

  /// Non-null when a generation was interrupted during the 7-GP stage.
  final GaEvaluationCheckpoint? evaluationCheckpoint;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schema_version': kGaRunStateSchemaVersion,
    'run_id': runId,
    'config': config.toJson(),
    'current_generation': currentGeneration,
    'population': [
      for (final m in population)
        <String, dynamic>{
          'profile_id': m.slotId,
          'fitness_history': List<double>.from(m.fitnessHistory),
          'generations_survived': m.generationsSurvived,
        },
    ],
    'best_overall': bestOverall.toJson(),
    'convergence': convergence.toJson(),
    if (evaluationCheckpoint != null)
      'evaluation_checkpoint': evaluationCheckpoint!.toJson(),
  };

  factory GaRunState.fromJson(Map<String, dynamic> json, String runDir) {
    final version = json['schema_version'];
    if (version != kGaRunStateSchemaVersion) {
      throw FormatException(
        'unsupported run-state schema_version $version '
        '(expected $kGaRunStateSchemaVersion)',
      );
    }
    final configJson = json['config'];
    if (configJson is! Map<String, dynamic>) {
      throw const FormatException('run-state config must be an object');
    }
    final config = GaConfig.fromJson(configJson);
    final popJson = json['population'];
    if (popJson is! List<dynamic>) {
      throw const FormatException('run-state population must be an array');
    }
    final population = <PopulationMember>[];
    for (final row in popJson) {
      if (row is! Map<String, dynamic>) {
        throw const FormatException('population entry must be an object');
      }
      final profileId = row['profile_id'];
      if (profileId is! String) {
        throw const FormatException('population profile_id must be a string');
      }
      final profileFile = File('$runDir/profiles/$profileId.json');
      if (!profileFile.existsSync()) {
        throw FormatException('missing population profile file: ${profileFile.path}');
      }
      final profileDecoded = jsonDecode(profileFile.readAsStringSync());
      if (profileDecoded is! Map<String, dynamic>) {
        throw FormatException('invalid profile JSON: ${profileFile.path}');
      }
      final history = row['fitness_history'];
      population.add(
        PopulationMember(
          slotId: profileId,
          profile: AiProfile.fromJson(profileDecoded),
          fitnessHistory: history is List<dynamic>
              ? history.map((e) => (e as num).toDouble()).toList()
              : <double>[],
          generationsSurvived: (row['generations_survived'] as num?)?.toInt() ?? 0,
        ),
      );
    }
    final bestJson = json['best_overall'];
    if (bestJson is! Map<String, dynamic>) {
      throw const FormatException('best_overall must be an object');
    }
    final convJson = json['convergence'];
    if (convJson is! Map<String, dynamic>) {
      throw const FormatException('convergence must be an object');
    }
    final checkpointJson = json['evaluation_checkpoint'];
    GaEvaluationCheckpoint? checkpoint;
    if (checkpointJson != null) {
      if (checkpointJson is! Map<String, dynamic>) {
        throw const FormatException('evaluation_checkpoint must be an object');
      }
      checkpoint = GaEvaluationCheckpoint.fromJson(checkpointJson);
    }
    return GaRunState(
      runId: json['run_id'] as String? ?? 'unknown',
      config: config,
      currentGeneration: (json['current_generation'] as num?)?.toInt() ?? -1,
      population: population,
      bestOverall: GaBestOverall.fromJson(bestJson),
      convergence: GaConvergence.fromJson(convJson),
      evaluationCheckpoint: checkpoint,
    );
  }
}

class GaBestOverall {
  const GaBestOverall({
    required this.profileId,
    required this.fitness,
    required this.generation,
  });

  final String profileId;
  final double fitness;
  final int generation;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'profile_id': profileId,
    if (fitness.isFinite) 'fitness': fitness,
    'generation': generation,
  };

  factory GaBestOverall.fromJson(Map<String, dynamic> json) {
    final generation = (json['generation'] as num?)?.toInt() ?? 0;
    final rawFitness = json['fitness'];
    final double fitness;
    if (rawFitness == null) {
      fitness = generation < 0 ? double.negativeInfinity : 0.0;
    } else {
      fitness = (rawFitness as num).toDouble();
    }
    return GaBestOverall(
      profileId: json['profile_id'] as String? ?? '',
      fitness: fitness,
      generation: generation,
    );
  }
}

class GaConvergence {
  GaConvergence({
    List<double>? bestFitnessPerGeneration,
    List<double>? avgFitnessPerGeneration,
  }) : bestFitnessPerGeneration = bestFitnessPerGeneration ?? <double>[],
       avgFitnessPerGeneration = avgFitnessPerGeneration ?? <double>[];

  final List<double> bestFitnessPerGeneration;
  final List<double> avgFitnessPerGeneration;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'best_fitness_per_generation': List<double>.from(bestFitnessPerGeneration),
    'avg_fitness_per_generation': List<double>.from(avgFitnessPerGeneration),
  };

  factory GaConvergence.fromJson(Map<String, dynamic> json) => GaConvergence(
    bestFitnessPerGeneration:
        (json['best_fitness_per_generation'] as List<dynamic>?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        <double>[],
    avgFitnessPerGeneration:
        (json['avg_fitness_per_generation'] as List<dynamic>?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        <double>[],
  );
}

/// Atomic write of [state] to [runDir]/run-state.json.
Future<void> persistRunState(String runDir, GaRunState state) async {
  final file = File('$runDir/run-state.json');
  final temp = File('${file.path}.tmp');
  await temp.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(state.toJson())}\n',
  );
  await temp.rename(file.path);
}

Future<void> writeProfileFiles(String runDir, List<PopulationMember> population) async {
  final profilesDir = Directory('$runDir/profiles');
  await profilesDir.create(recursive: true);
  for (final member in population) {
    final path = '${profilesDir.path}/${member.slotId}.json';
    await File(path).writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(member.profile.toJson())}\n',
    );
  }
}

Future<void> writeHistory(String runDir, GaConvergence convergence) async {
  await File('$runDir/history.json').writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(convergence.toJson())}\n',
  );
}

Future<void> writeGenerationArtifacts({
  required String runDir,
  required int generation,
  required Map<String, double> fitnessBySlot,
  required PopulationMember bestMember,
}) async {
  final genDir = Directory('$runDir/gen-${generation.toString().padLeft(3, '0')}');
  await genDir.create(recursive: true);
  await File('${genDir.path}/fitness.json').writeAsString(
  '${const JsonEncoder.withIndent('  ').convert(fitnessBySlot)}\n',
  );
  await File('${genDir.path}/best-profile.json').writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(bestMember.profile.toJson())}\n',
  );
}

/// Exports the best-overall member's profile to `<runDir>/best-overall-profile.json`.
///
/// Idempotent: copies the `gen-NNN/best-profile.json` recorded for
/// [bestOverall].generation. No-op when no generation has completed or the
/// source artifact is absent. SPEC/program/ga-runner.md.
Future<void> exportBestOverallProfile(String runDir, GaBestOverall bestOverall) async {
  if (bestOverall.generation < 0) return;
  final genLabel = bestOverall.generation.toString().padLeft(3, '0');
  final source = File('$runDir/gen-$genLabel/best-profile.json');
  if (!source.existsSync()) return;
  await File('$runDir/best-overall-profile.json').writeAsString(
    source.readAsStringSync(),
  );
}

GaRunState loadRunState(String runDir) {
  final file = File('$runDir/run-state.json');
  if (!file.existsSync()) {
    throw FormatException('no resumable run state at $runDir');
  }
  Map<String, dynamic> decoded;
  try {
    decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  } on Object catch (e) {
    throw FormatException('failed to parse run-state.json: $e');
  }
  return GaRunState.fromJson(decoded, runDir);
}
