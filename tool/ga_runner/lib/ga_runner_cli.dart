import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import 'config/ga_config.dart';
import 'engine/ga_engine.dart';
import 'observer/observer_runner.dart';
import 'package_logger.dart';
import 'persistence/run_state.dart';

final _log = packageLogger('cli');

const int kExitUsage = 64;
const int kExitError = 1;
const int kExitInterrupted = 130;

String _usage(ArgParser parser) {
  final buf = StringBuffer()
    ..writeln('Usage:')
    ..writeln('  melos run ga_runner -- --config <path>')
    ..writeln('  melos run ga_runner -- --resume <dir>')
    ..writeln('')
    ..writeln('Genetic-algorithm tuning of AI profiles (SPEC/program/ga-runner.md).')
    ..writeln('')
    ..writeln('Options:')
    ..writeln(parser.usage);
  return buf.toString();
}

/// Finds the repository root (directory containing melos root pubspec).
String findRepoRoot({String? start}) {
  var dir = Directory(start ?? Directory.current.path).absolute;
  while (true) {
    final pubspec = File('${dir.path}/pubspec.yaml');
    if (pubspec.existsSync()) {
      final text = pubspec.readAsStringSync();
      if (text.contains('melos:') && text.contains('workspace:')) {
        return dir.path;
      }
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return Directory.current.path;
}

Future<int> runGaRunnerCli(
  List<String> arguments, {
  required void Function(String line) emitStdout,
  required void Function(String line) emitStderr,
  ObserverRunner? observerRunner,
}) async {
  final parser = ArgParser(usageLineLength: 100)
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Print usage and exit.')
    ..addOption('config', help: 'Path to ga-config.json for a new run.')
    ..addOption('resume', help: 'Resume from a run directory containing run-state.json.');

  ArgResults args;
  try {
    args = parser.parse(arguments);
  } on ArgParserException catch (e) {
    emitStderr('Error: $e\n');
    emitStdout(_usage(parser));
    return kExitUsage;
  }

  if (args['help'] == true) {
    emitStdout(_usage(parser));
    return 0;
  }

  final configPath = args['config'] as String?;
  final resumeDir = args['resume'] as String?;
  if ((configPath == null) == (resumeDir == null)) {
    emitStderr('Error: specify exactly one of --config or --resume.\n');
    emitStdout(_usage(parser));
    return kExitUsage;
  }

  final repoRoot = findRepoRoot();
  final runner = observerRunner ?? const MelosObserverRunner();
  var stopRequested = false;
  final sub = ProcessSignal.sigint.watch().listen((_) {
    stopRequested = true;
    _log.w('ga:sigint received');
  });

  try {
    if (resumeDir != null) {
      return await _resume(
        resumeDir: resumeDir,
        repoRoot: repoRoot,
        runner: runner,
        isStopRequested: () => stopRequested,
        emitStderr: emitStderr,
      );
    }
    return await _startFresh(
      configPath: configPath!,
      repoRoot: repoRoot,
      runner: runner,
      isStopRequested: () => stopRequested,
      emitStderr: emitStderr,
    );
  } finally {
    await sub.cancel();
  }
}

Future<int> _startFresh({
  required String configPath,
  required String repoRoot,
  required ObserverRunner runner,
  required bool Function() isStopRequested,
  required void Function(String line) emitStderr,
}) async {
  final file = File(configPath);
  if (!file.existsSync()) {
    emitStderr('Error: config file not found: $configPath');
    return kExitError;
  }
  GaConfig config;
  try {
    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    config = GaConfig.fromJson(decoded);
  } on Object catch (e) {
    emitStderr('Error: invalid ga-config.json: $e');
    return kExitError;
  }

  final runId = newRunId();
  final runDir = '${config.outputDir}/$runId';
  final engine = GaEngine(
    repoRoot: repoRoot,
    config: config,
    runDir: runDir,
    observerRunner: runner,
    shouldStop: isStopRequested,
  );
  _log.i('ga:run_start id=$runId dir=$runDir');
  try {
    return await engine.runFresh(runId: runId);
  } on FormatException catch (e) {
    emitStderr('Error: $e');
    return kExitError;
  }
}

Future<int> _resume({
  required String resumeDir,
  required String repoRoot,
  required ObserverRunner runner,
  required bool Function() isStopRequested,
  required void Function(String line) emitStderr,
}) async {
  GaRunState state;
  try {
    state = loadRunState(resumeDir);
  } on FormatException catch (e) {
    emitStderr('Error: $e');
    return kExitError;
  }

  if (state.currentGeneration >= state.config.maxGenerations - 1) {
    _log.i('ga:resume_already_complete dir=$resumeDir');
    return 0;
  }

  final engine = GaEngine(
    repoRoot: repoRoot,
    config: state.config,
    runDir: resumeDir,
    observerRunner: runner,
    shouldStop: isStopRequested,
  );
  try {
    return await engine.resume(state);
  } on FormatException catch (e) {
    emitStderr('Error: $e');
    return kExitError;
  }
}
