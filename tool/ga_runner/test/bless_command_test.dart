import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import 'package:ga_runner/bless/bless_command.dart';
import 'package:ga_runner/bless/blessed_profile_manifest.dart';
import 'package:ga_runner/bless/compare_command.dart';
import 'package:ga_runner/bless/list_command.dart';
import 'package:ga_runner/ga_runner.dart';
import 'package:ga_runner/ga_runner_cli.dart';

Future<Directory> _writeCompletedRun({
  required String runId,
  required PopulationMember member,
}) async {
  final dir = await Directory.systemTemp.createTemp('ga_bless_run_');
  final config = GaConfig(
    populationSize: 1,
    gamesPerProfile: 1,
    maxGenerations: 1,
    gamePlayerCount: 2,
    maxTurns: 3,
    seedProfilesDir: 'seeds',
    gameSetupConfig: GameSetupConfig(
      selectedGreatPowerIds: const ['england', 'france'],
      minorNationCount: 3,
      tribeCount: 3,
      numProvincesOldWorld: 23,
      numProvincesNewWorld: 12,
    ),
    outputDir: 'out',
    seed: 1,
  );
  final state = GaRunState(
    runId: runId,
    config: config,
    currentGeneration: 0,
    population: [member],
    bestOverall: GaBestOverall(
      profileId: member.slotId,
      fitness: 2.5,
      generation: 0,
    ),
    convergence: GaConvergence(
      bestFitnessPerGeneration: <double>[2.5],
      avgFitnessPerGeneration: <double>[2.5],
    ),
  );
  await writeProfileFiles(dir.path, [member]);
  await persistRunState(dir.path, state);
  await exportBestOverallProfile(dir.path, state.bestOverall);
  return dir;
}

void main() {
  group('ga_runner bless/compare/list', () {
    late Directory repoRoot;
    late Directory runDir;

    setUp(() async {
      repoRoot = await Directory.systemTemp.createTemp('ga_bless_repo_');
      final profilesDir = Directory('${repoRoot.path}/app/assets/profiles');
      await profilesDir.create(recursive: true);
      await File('${profilesDir.path}/manifest.json').writeAsString(
        '{"profiles":[]}\n',
      );
      runDir = await _writeCompletedRun(
        runId: 'ga-run-baseline',
        member: PopulationMember(
          slotId: 'profile-000',
          profile: seedAiProfilesById['victoria']!,
          fitnessHistory: <double>[2.5],
          generationsSurvived: 1,
        ),
      );
    });

    tearDown(() async {
      await runDir.delete(recursive: true);
      await repoRoot.delete(recursive: true);
    });

    test('bless copies best profile and updates manifest', () async {
      final out = <String>[];
      final code = await runBlessCommand(
        arguments: <String>['--run', runDir.path, '--name', 'aggressive_v2'],
        repoRoot: repoRoot.path,
        emitStdout: out.add,
        emitStderr: (_) {},
      );
      expect(code, 0);
      final profileFile = File(
        blessedProfileAssetPath(repoRoot.path, 'aggressive_v2'),
      );
      expect(profileFile.existsSync(), isTrue);
      final manifest = BlessedProfileManifest.readFile(
        blessedManifestPath(repoRoot.path),
      );
      expect(manifest.profiles.length, 1);
      expect(manifest.profiles.single.name, 'aggressive_v2');
      expect(manifest.profiles.single.sourceRunId, 'ga-run-baseline');
    });

    test('bless rejects duplicate name without --force', () async {
      final err = <String>[];
      await runBlessCommand(
        arguments: <String>['--run', runDir.path, '--name', 'dup_test'],
        repoRoot: repoRoot.path,
        emitStdout: (_) {},
        emitStderr: err.add,
      );
      final code = await runBlessCommand(
        arguments: <String>['--run', runDir.path, '--name', 'dup_test'],
        repoRoot: repoRoot.path,
        emitStdout: (_) {},
        emitStderr: err.add,
      );
      expect(code, kExitBlessDuplicate);
      expect(err.join('\n'), contains('already blessed'));
      final manifest = BlessedProfileManifest.readFile(
        blessedManifestPath(repoRoot.path),
      );
      expect(manifest.profiles.where((e) => e.name == 'dup_test').length, 1);
    });

    test('bless --force replaces manifest entry in place', () async {
      await runBlessCommand(
        arguments: <String>['--run', runDir.path, '--name', 'force_test'],
        repoRoot: repoRoot.path,
        emitStdout: (_) {},
        emitStderr: (_) {},
      );
      final candidate = await _writeCompletedRun(
        runId: 'ga-run-candidate',
        member: PopulationMember(
          slotId: 'profile-000',
          profile: seedAiProfilesById['napoleon']!,
          fitnessHistory: <double>[9.0],
          generationsSurvived: 2,
        ),
      );
      addTearDown(() => candidate.delete(recursive: true));
      final code = await runBlessCommand(
        arguments: <String>[
          '--run',
          candidate.path,
          '--name',
          'force_test',
          '--force',
        ],
        repoRoot: repoRoot.path,
        emitStdout: (_) {},
        emitStderr: (_) {},
      );
      expect(code, 0);
      final manifest = BlessedProfileManifest.readFile(
        blessedManifestPath(repoRoot.path),
      );
      expect(manifest.profiles.where((e) => e.name == 'force_test').length, 1);
      expect(manifest.profiles.single.sourceRunId, 'ga-run-candidate');
    });

    test('list prints population fitness rows', () async {
      final out = <String>[];
      final code = await runListCommand(
        arguments: <String>['--run', runDir.path],
        emitStdout: out.add,
        emitStderr: (_) {},
      );
      expect(code, 0);
      expect(out.join('\n'), contains('profile-000'));
      expect(out.join('\n'), contains('fitness=2.5'));
    });

    test('compare resolves --baseline-name via manifest', () async {
      final runsRoot = Directory('${repoRoot.path}/runs');
      await runsRoot.create(recursive: true);
      final baseline = await _writeCompletedRun(
        runId: 'ga-run-baseline',
        member: PopulationMember(
          slotId: 'profile-000',
          profile: seedAiProfilesById['victoria']!,
          fitnessHistory: <double>[2.5],
          generationsSurvived: 1,
        ),
      );
      await baseline.rename('${runsRoot.path}/ga-run-baseline');
      await runBlessCommand(
        arguments: <String>[
          '--run',
          '${runsRoot.path}/ga-run-baseline',
          '--name',
          'baseline_v1',
        ],
        repoRoot: repoRoot.path,
        emitStdout: (_) {},
        emitStderr: (_) {},
      );
      final candidate = await _writeCompletedRun(
        runId: 'ga-run-candidate-compare',
        member: PopulationMember(
          slotId: 'profile-000',
          profile: seedAiProfilesById['napoleon']!,
          fitnessHistory: <double>[3.0],
          generationsSurvived: 1,
        ),
      );
      await candidate.rename('${runsRoot.path}/ga-run-candidate-compare');
      final out = <String>[];
      final code = await runCompareCommand(
        arguments: <String>[
          '--baseline-name',
          'baseline_v1',
          '--candidate',
          '${runsRoot.path}/ga-run-candidate-compare',
        ],
        repoRoot: repoRoot.path,
        emitStdout: out.add,
        emitStderr: (_) {},
      );
      expect(code, 0);
      expect(out.join('\n'), contains('Parameter diff'));
    });

    test('bless --profile blesses a specific slot id', () async {
      final code = await runBlessCommand(
        arguments: <String>[
          '--run',
          runDir.path,
          '--profile',
          'profile-000',
          '--name',
          'slot_specific',
        ],
        repoRoot: repoRoot.path,
        emitStdout: (_) {},
        emitStderr: (_) {},
      );
      expect(code, 0);
      expect(
        File(blessedProfileAssetPath(repoRoot.path, 'slot_specific'))
            .existsSync(),
        isTrue,
      );
      final manifest = BlessedProfileManifest.readFile(
        blessedManifestPath(repoRoot.path),
      );
      expect(manifest.profiles.single.sourceProfileId, 'profile-000');
    });

    test('compare --baseline direct path emits curves and diff', () async {
      final candidate = await _writeCompletedRun(
        runId: 'ga-run-direct-candidate',
        member: PopulationMember(
          slotId: 'profile-000',
          profile: seedAiProfilesById['napoleon']!,
          fitnessHistory: <double>[7.0],
          generationsSurvived: 1,
        ),
      );
      addTearDown(() => candidate.delete(recursive: true));
      final out = <String>[];
      final code = await runCompareCommand(
        arguments: <String>[
          '--baseline',
          runDir.path,
          '--candidate',
          candidate.path,
        ],
        repoRoot: repoRoot.path,
        emitStdout: out.add,
        emitStderr: (_) {},
      );
      expect(code, 0);
      final printed = out.join('\n');
      expect(printed, contains('Fitness per generation'));
      expect(printed, contains('Parameter diff'));
    });

    test('compare --baseline-name not in manifest exits non-zero', () async {
      final err = <String>[];
      final code = await runCompareCommand(
        arguments: <String>[
          '--baseline-name',
          'never_blessed',
          '--candidate',
          runDir.path,
        ],
        repoRoot: repoRoot.path,
        emitStdout: (_) {},
        emitStderr: err.add,
      );
      expect(code, isNot(0));
      expect(err.join('\n'), contains('not in manifest'));
    });

    test('compare rejects both --baseline and --baseline-name', () async {
      final err = <String>[];
      final code = await runCompareCommand(
        arguments: <String>[
          '--baseline',
          runDir.path,
          '--baseline-name',
          'x',
          '--candidate',
          runDir.path,
        ],
        repoRoot: repoRoot.path,
        emitStdout: (_) {},
        emitStderr: err.add,
      );
      expect(code, kExitUsage);
      expect(err.join('\n'), contains('mutually exclusive'));
    });
  });
}
