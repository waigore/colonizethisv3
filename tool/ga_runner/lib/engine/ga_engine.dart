import 'dart:io';
import 'dart:math' as math;

import '../config/ga_config.dart';
import '../fitness/fitness_function.dart';
import '../genetics/population.dart';
import '../observer/observer_runner.dart';
import '../package_logger.dart';
import '../persistence/run_state.dart';
import '../setup/capital_resolver.dart';
import '../setup/round_artifacts.dart';

final _log = packageLogger('engine');

/// Orchestrates GA generations. SPEC/program/ga-runner.md. Refs #3439.
class GaEngine {
  GaEngine({
    required this.repoRoot,
    required this.config,
    required this.runDir,
    required this.observerRunner,
    bool Function()? shouldStop,
  }) : shouldStop = shouldStop ?? (() => false);

  final String repoRoot;
  final GaConfig config;
  final String runDir;
  final ObserverRunner observerRunner;
  final bool Function() shouldStop;

  Future<int> runFresh({required String runId}) async {
    final seeds = loadSeedProfilesFromDir(config.seedProfilesDir);
    final rng = math.Random(config.seed);
    var population = buildInitialPopulation(
      seeds: seeds,
      populationSize: config.populationSize,
      rng: rng,
    );
    await Directory(runDir).create(recursive: true);
    await writeProfileFiles(runDir, population);

    final state = GaRunState(
      runId: runId,
      config: config,
      currentGeneration: -1,
      population: population,
      bestOverall: const GaBestOverall(
        profileId: '',
        fitness: double.negativeInfinity,
        generation: -1,
      ),
      convergence: GaConvergence(),
    );
    return _runGenerations(state, population, rng, startGeneration: 0);
  }

  Future<int> resume(GaRunState state) async {
    if (state.currentGeneration >= state.config.maxGenerations - 1) {
      await exportBestOverallProfile(runDir, state.bestOverall);
      _log.i('ga:already_complete generation=${state.currentGeneration}');
      return 0;
    }
    final rng = math.Random(
      state.config.seed + (state.currentGeneration + 1) * 1009,
    );
    return _runGenerations(
      state,
      state.population,
      rng,
      startGeneration: state.currentGeneration + 1,
    );
  }

  Future<int> _runGenerations(
    GaRunState state,
    List<PopulationMember> population,
    math.Random rng, {
    required int startGeneration,
  }) async {
    var current = population;
    var bestOverall = state.bestOverall;
    var convergence = state.convergence;

    for (var gen = startGeneration; gen < config.maxGenerations; gen++) {
      if (shouldStop()) {
        _log.i('ga:interrupted generation=$gen');
        return 130;
      }

      _log.i('ga:generation_start index=$gen');
      final evaluation = await _evaluateGeneration(
        generation: gen,
        population: current,
        rng: rng,
      );
      if (!evaluation.complete) {
        _log.i('ga:interrupted generation=$gen');
        return 130;
      }
      final fitnessBySlot = evaluation.fitnessBySlot;

      for (final member in current) {
        member.fitnessHistory.add(fitnessBySlot[member.slotId] ?? 0.0);
      }

      final values = fitnessBySlot.values.toList();
      final bestFitness = values.isEmpty ? 0.0 : values.reduce(math.max);
      final avgFitness = values.isEmpty
          ? 0.0
          : values.reduce((a, b) => a + b) / values.length;
      convergence.bestFitnessPerGeneration.add(bestFitness);
      convergence.avgFitnessPerGeneration.add(avgFitness);

      final bestSlot = fitnessBySlot.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      if (bestFitness > bestOverall.fitness) {
        bestOverall = GaBestOverall(
          profileId: bestSlot.key,
          fitness: bestFitness,
          generation: gen,
        );
      }

      final bestMember = current.firstWhere((m) => m.slotId == bestSlot.key);
      await writeGenerationArtifacts(
        runDir: runDir,
        generation: gen,
        fitnessBySlot: fitnessBySlot,
        bestMember: bestMember,
      );

      final nextState = GaRunState(
        runId: state.runId,
        config: config,
        currentGeneration: gen,
        population: current,
        bestOverall: bestOverall,
        convergence: convergence,
      );
      await writeProfileFiles(runDir, current);
      await persistRunState(runDir, nextState);
      await writeHistory(runDir, convergence);

      if (gen == config.maxGenerations - 1) {
        await exportBestOverallProfile(runDir, bestOverall);
        _log.i('ga:complete generations=${config.maxGenerations}');
        return 0;
      }

      if (shouldStop()) {
        _log.i('ga:interrupted after_generation=$gen');
        return 130;
      }

      current = evolvePopulation(
        current: current,
        generationFitness: [
          for (final m in current) fitnessBySlot[m.slotId] ?? 0.0,
        ],
        rng: rng,
      );
      await writeProfileFiles(runDir, current);
    }
    return 0;
  }

  Future<({Map<String, double> fitnessBySlot, bool complete})> _evaluateGeneration({
    required int generation,
    required List<PopulationMember> population,
    required math.Random rng,
  }) async {
    final fitnessTotals = <String, List<double>>{
      for (final m in population) m.slotId: <double>[],
    };

    for (var profileIndex = 0; profileIndex < population.length; profileIndex++) {
      final subject = population[profileIndex];
      for (var gameIndex = 0; gameIndex < config.gamesPerProfile; gameIndex++) {
        if (shouldStop()) {
          _log.i('ga:evaluation_interrupted generation=$generation');
          return (fitnessBySlot: const <String, double>{}, complete: false);
        }
        final opponentIndex = _pickOpponentIndex(
          subjectIndex: profileIndex,
          populationLength: population.length,
          rng: rng,
        );
        final opponent = population[opponentIndex];
        final roundDir =
            '$runDir/gen-${generation.toString().padLeft(3, '0')}/'
            '${subject.slotId}-g${gameIndex.toString().padLeft(2, '0')}';
        final gameSeed = _deriveGameSeed(
          config.seed,
          generation,
          profileIndex,
          gameIndex,
        );
        final setup = withGameSeed(config.gameSetupConfig, gameSeed);
        final capitals = resolveCapitalProvinces(setup);
        await materializeRoundArtifacts(
          roundDir: roundDir,
          setup: setup,
          profileA: subject.profile,
          profileB: opponent.profile,
          capitalProvinces: capitals,
        );

        final observerResult = await observerRunner.run(
          repoRoot: repoRoot,
          setupPath: '$roundDir/setup.json',
          profilesDir: '$roundDir/profiles',
          outputDir: roundDir,
          maxTurns: config.maxTurns,
          seed: gameSeed,
        );

        final score = _scoreGame(
          observerResult: observerResult,
          roundDir: roundDir,
          subjectSlotId: subject.slotId,
          generation: generation,
          gameIndex: gameIndex,
        );
        if (score != null) {
          fitnessTotals[subject.slotId]!.add(score);
        }
      }
    }

    return (
      fitnessBySlot: {
        for (final entry in fitnessTotals.entries)
          entry.key: _aggregateFitness(entry.value, entry.key, generation),
      },
      complete: true,
    );
  }

  double? _scoreGame({
    required ObserverRunResult observerResult,
    required String roundDir,
    required String subjectSlotId,
    required int generation,
    required int gameIndex,
  }) {
    if (observerResult.exitCode != 0 || observerResult.gameTraceDir == null) {
      _log.w(
        'ga:game_failed generation=$generation profile=$subjectSlotId '
        'game=$gameIndex exit=${observerResult.exitCode}',
      );
      return null;
    }
    final artifacts = loadFinalObserverArtifacts(observerResult.gameTraceDir!);
    if (artifacts == null) {
      _log.w(
        'ga:artifacts_missing generation=$generation profile=$subjectSlotId '
        'game=$gameIndex',
      );
      return null;
    }
    final capitals = readCapitalProvinces(roundDir);
    final scores = computeFitness(
      artifacts.snapshot,
      artifacts.runSummary,
      capitalProvinceByPlayerId: capitals,
    );
    final gp1 = scores['gp1'];
    final total = gp1?.total;
    if (total == null || !total.isFinite) {
      _log.w(
        'ga:fitness_invalid generation=$generation profile=$subjectSlotId '
        'game=$gameIndex',
      );
      return null;
    }
    return total;
  }

  double _aggregateFitness(List<double> scores, String slotId, int generation) {
    if (scores.isEmpty) {
      _log.e(
        'ga:all_games_failed generation=$generation profile=$slotId',
      );
      return 0.0;
    }
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  int _pickOpponentIndex({
    required int subjectIndex,
    required int populationLength,
    required math.Random rng,
  }) {
    if (populationLength <= 1) return subjectIndex;
    var opponent = rng.nextInt(populationLength - 1);
    if (opponent >= subjectIndex) opponent++;
    return opponent;
  }
}

int deriveGameSeed(int masterSeed, int generation, int profileIndex, int gameIndex) =>
    masterSeed ^ (generation * 1000003) ^ (profileIndex * 9973) ^ (gameIndex * 101);

int _deriveGameSeed(int masterSeed, int generation, int profileIndex, int gameIndex) =>
    deriveGameSeed(masterSeed, generation, profileIndex, gameIndex);

String newRunId() {
  final now = DateTime.now().toUtc();
  final stamp =
      '${now.year}${now.month.toString().padLeft(2, '0')}'
      '${now.day.toString().padLeft(2, '0')}-'
      '${now.hour.toString().padLeft(2, '0')}'
      '${now.minute.toString().padLeft(2, '0')}'
      '${now.second.toString().padLeft(2, '0')}';
  return 'ga-run-$stamp';
}
