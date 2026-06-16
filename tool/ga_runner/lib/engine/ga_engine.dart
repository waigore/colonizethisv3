import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';

import '../bless/blessed_profile_manifest.dart';
import '../config/ga_config.dart';
import '../fitness/fitness_function.dart';
import '../fitness/stage_fitness.dart';
import '../genetics/population.dart';
import '../observer/observer_runner.dart';
import '../package_logger.dart';
import '../persistence/run_state.dart';
import '../setup/capital_resolver.dart';
import '../setup/prior_generation_winners.dart';
import '../setup/round_artifacts.dart';
import '../setup/seven_gp_opponent_roster.dart';
import 'ga_seeds.dart';

export 'ga_seeds.dart';

final _log = packageLogger('engine');

/// Orchestrates GA generations. SPEC/program/ga-runner.md. Refs #3439, #3488.
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
    if (state.evaluationCheckpoint == null &&
        state.currentGeneration >= state.config.maxGenerations - 1) {
      await exportBestOverallProfile(runDir, state.bestOverall);
      _log.i('ga:already_complete generation=${state.currentGeneration}');
      return 0;
    }
    final rng = math.Random(
      state.config.seed + (state.currentGeneration + 1) * 1009,
    );
    final startGeneration = state.evaluationCheckpoint?.generation ??
        state.currentGeneration + 1;
    return _runGenerations(
      state,
      state.population,
      rng,
      startGeneration: startGeneration,
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
    var evaluationCheckpoint = state.evaluationCheckpoint;

    for (var gen = startGeneration; gen < config.maxGenerations; gen++) {
      if (shouldStop()) {
        _log.i('ga:interrupted generation=$gen');
        return 130;
      }

      _log.i('ga:generation_start index=$gen');
      final resumeCheckpoint =
          evaluationCheckpoint?.generation == gen ? evaluationCheckpoint : null;
      final evaluation = await _evaluateGeneration(
        generation: gen,
        population: current,
        rng: rng,
        checkpoint: resumeCheckpoint,
      );
      if (!evaluation.complete) {
        if (evaluation.checkpoint != null) {
          await persistRunState(
            runDir,
            GaRunState(
              runId: state.runId,
              config: config,
              currentGeneration: state.currentGeneration,
              population: current,
              bestOverall: bestOverall,
              convergence: convergence,
              evaluationCheckpoint: evaluation.checkpoint,
            ),
          );
        }
        _log.i('ga:interrupted generation=$gen');
        return 130;
      }
      evaluationCheckpoint = null;
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
        evaluationCheckpoint: null,
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

  Future<
      ({
        Map<String, double> fitnessBySlot,
        bool complete,
        GaEvaluationCheckpoint? checkpoint,
      })> _evaluateGeneration({
    required int generation,
    required List<PopulationMember> population,
    required math.Random rng,
    GaEvaluationCheckpoint? checkpoint,
  }) async {
    final twoPlayerScores = <String, List<double>>{
      for (final m in population) m.slotId: <double>[],
    };
    final sevenGpScores = <String, List<double>>{
      for (final m in population) m.slotId: <double>[],
    };

    if (checkpoint != null) {
      for (final entry in checkpoint.twoPlayerScores.entries) {
        twoPlayerScores[entry.key] = List<double>.from(entry.value);
      }
      for (final entry in checkpoint.sevenGpScores.entries) {
        sevenGpScores[entry.key] = List<double>.from(entry.value);
      }
    }

    final skipTwoPlayer =
        checkpoint != null && checkpoint.generation == generation;

    if (!skipTwoPlayer) {
      for (var profileIndex = 0; profileIndex < population.length; profileIndex++) {
        final subject = population[profileIndex];
        for (var gameIndex = 0; gameIndex < config.gamesPerProfile; gameIndex++) {
          if (shouldStop()) {
            _log.i('ga:evaluation_interrupted generation=$generation');
            return (
              fitnessBySlot: const <String, double>{},
              complete: false,
              checkpoint: null,
            );
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
          final gameSeed = deriveGameSeed(
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

          final score = await _runObserverAndScore(
            roundDir: roundDir,
            gameSeed: gameSeed,
            generation: generation,
            profileSlotId: subject.slotId,
            gameIndex: gameIndex,
            stageLabel: 'two_player',
          );
          if (score != null) {
            twoPlayerScores[subject.slotId]!.add(score);
          }
        }
      }
    }

    final priorWinners = loadPriorGenerationWinners(
      runDir: runDir,
      beforeGeneration: generation,
    );
    final blessedProfiles = config.sevenGpUseBlessedProfiles
        ? _loadBlessedProfiles()
        : const <AiProfile>[];

    final sevenGpStartProfile = checkpoint?.generation == generation
        ? checkpoint!.profileIndex
        : 0;
    final sevenGpStartGame = checkpoint?.generation == generation
        ? checkpoint!.gameIndex
        : 0;

    for (
      var profileIndex = sevenGpStartProfile;
      profileIndex < population.length;
      profileIndex++
    ) {
      final subject = population[profileIndex];
      final scoredTwoPlayer = twoPlayerScores[subject.slotId]!;
      if (config.sevenGpGamesPerProfile == 0 || scoredTwoPlayer.isEmpty) {
        continue;
      }

      final opponents = buildSevenGpOpponentRoster(
        subjectProfile: subject.profile,
        priorWinners: priorWinners,
        blessedProfiles: blessedProfiles,
        config: config,
        rng: math.Random(
          deriveSevenGpRosterSeed(config.seed, generation, profileIndex),
        ),
        masterSeed: config.seed,
        generation: generation,
        subjectIndex: profileIndex,
      );

      final gameStartIndex = profileIndex == sevenGpStartProfile
          ? sevenGpStartGame
          : 0;
      for (var gameIndex = gameStartIndex;
          gameIndex < config.sevenGpGamesPerProfile;
          gameIndex++) {
        if (shouldStop()) {
          _log.i('ga:evaluation_interrupted generation=$generation');
          return (
            fitnessBySlot: const <String, double>{},
            complete: false,
            checkpoint: GaEvaluationCheckpoint(
              generation: generation,
              twoPlayerScores: _copyScoreMap(twoPlayerScores),
              sevenGpScores: _copyScoreMap(sevenGpScores),
              profileIndex: profileIndex,
              gameIndex: gameIndex,
            ),
          );
        }
        final roundDir =
            '$runDir/gen-${generation.toString().padLeft(3, '0')}/'
            '${subject.slotId}-7gp-g${gameIndex.toString().padLeft(2, '0')}';
        final gameSeed = deriveSevenGpGameSeed(
          config.seed,
          generation,
          profileIndex,
          gameIndex,
        );
        final setup = withGameSeed(config.sevenGpGameSetupConfig, gameSeed);
        final capitals = resolveCapitalProvinces(setup);
        final profilesBySlot = <String, AiProfile>{
          'gp1': subject.profile,
          for (var i = 0; i < opponents.length; i++)
            'gp${i + 2}': opponents[i],
        };
        await materializeMultiPlayerRoundArtifacts(
          roundDir: roundDir,
          setup: setup,
          profilesBySlot: profilesBySlot,
          capitalProvinces: capitals,
        );

        final score = await _runObserverAndScore(
          roundDir: roundDir,
          gameSeed: gameSeed,
          generation: generation,
          profileSlotId: subject.slotId,
          gameIndex: gameIndex,
          stageLabel: 'seven_gp',
        );
        if (score != null) {
          sevenGpScores[subject.slotId]!.add(score);
        }
      }
    }

    return (
      fitnessBySlot: {
        for (final member in population)
          member.slotId: combineStageFitness(
            twoPlayerFitness: meanStageFitness(twoPlayerScores[member.slotId]!),
            sevenGpFitness: config.sevenGpGamesPerProfile == 0 ||
                    twoPlayerScores[member.slotId]!.isEmpty
                ? null
                : meanStageFitness(sevenGpScores[member.slotId]!),
            weights: config.stageFitnessWeights,
            sevenGpSkipped: twoPlayerScores[member.slotId]!.isEmpty,
          ),
      },
      complete: true,
      checkpoint: null,
    );
  }

  Map<String, List<double>> _copyScoreMap(Map<String, List<double>> source) =>
      source.map((k, v) => MapEntry(k, List<double>.from(v)));

  List<AiProfile> _loadBlessedProfiles() {
    final manifest = BlessedProfileManifest.readFile(
      blessedManifestPath(repoRoot),
    );
    final profiles = <AiProfile>[];
    for (final entry in manifest.profiles) {
      final file = File(blessedProfileAssetPath(repoRoot, entry.name));
      if (!file.existsSync()) continue;
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic>) continue;
      profiles.add(AiProfile.fromJson(decoded));
    }
    return profiles;
  }

  Future<double?> _runObserverAndScore({
    required String roundDir,
    required int gameSeed,
    required int generation,
    required String profileSlotId,
    required int gameIndex,
    required String stageLabel,
  }) async {
    final observerResult = await observerRunner.run(
      repoRoot: repoRoot,
      setupPath: '$roundDir/setup.json',
      profilesDir: '$roundDir/profiles',
      outputDir: roundDir,
      maxTurns: config.maxTurns,
      seed: gameSeed,
    );
    return _scoreGame(
      observerResult: observerResult,
      roundDir: roundDir,
      subjectSlotId: profileSlotId,
      generation: generation,
      gameIndex: gameIndex,
      stageLabel: stageLabel,
    );
  }

  double? _scoreGame({
    required ObserverRunResult observerResult,
    required String roundDir,
    required String subjectSlotId,
    required int generation,
    required int gameIndex,
    required String stageLabel,
  }) {
    if (observerResult.exitCode != 0 || observerResult.gameTraceDir == null) {
      _log.w(
        'ga:game_failed stage=$stageLabel generation=$generation '
        'profile=$subjectSlotId game=$gameIndex '
        'exit=${observerResult.exitCode}',
      );
      return null;
    }
    final artifacts = loadFinalObserverArtifacts(observerResult.gameTraceDir!);
    if (artifacts == null) {
      _log.w(
        'ga:artifacts_missing stage=$stageLabel generation=$generation '
        'profile=$subjectSlotId game=$gameIndex',
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
        'ga:fitness_invalid stage=$stageLabel generation=$generation '
        'profile=$subjectSlotId game=$gameIndex',
      );
      return null;
    }
    return total;
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
