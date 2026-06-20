import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';

import '../ga_runner_cli.dart';
import '../persistence/run_state.dart';
import 'blessed_profile_manifest.dart';

const int kExitBlessDuplicate = 2;

Future<int> runBlessCommand({
  required List<String> arguments,
  required String repoRoot,
  required void Function(String line) emitStdout,
  required void Function(String line) emitStderr,
}) async {
  String? runDir;
  String? profileSlotId;
  String? name;
  var force = false;

  for (var i = 0; i < arguments.length; i++) {
    final arg = arguments[i];
    switch (arg) {
      case '--run':
        runDir = _nextValue(arguments, ++i, emitStderr, '--run');
      case '--profile':
        profileSlotId = _nextValue(arguments, ++i, emitStderr, '--profile');
      case '--name':
        name = _nextValue(arguments, ++i, emitStderr, '--name');
      case '--force':
        force = true;
      case '--help':
      case '-h':
        emitStdout(_blessUsage());
        return 0;
      default:
        emitStderr('Error: unknown bless option: $arg');
        emitStdout(_blessUsage());
        return kExitUsage;
    }
  }

  if (runDir == null || name == null || name.isEmpty) {
    emitStderr('Error: bless requires --run and --name.');
    emitStdout(_blessUsage());
    return kExitUsage;
  }

  final runDirectory = Directory(runDir);
  if (!runDirectory.existsSync()) {
    emitStderr('Error: run directory not found: $runDir');
    return kExitError;
  }

  GaRunState state;
  try {
    state = loadRunState(runDir);
  } on FormatException catch (e) {
    emitStderr('Error: $e');
    return kExitError;
  }

  final manifestPath = blessedManifestPath(repoRoot);
  final manifest = BlessedProfileManifest.readFile(manifestPath);
  final existing = manifest.entryByName(name);
  if (existing != null && !force) {
    emitStderr(
      "Error: profile '$name' already blessed; pass --force to overwrite",
    );
    return kExitBlessDuplicate;
  }

  final slotId = profileSlotId ?? state.bestOverall.profileId;
  if (slotId.isEmpty) {
    emitStderr('Error: no best-overall profile in run state; pass --profile');
    return kExitError;
  }

  final sourceProfileFile = File('$runDir/profiles/$slotId.json');
  final File profileSource;
  if (sourceProfileFile.existsSync()) {
    profileSource = sourceProfileFile;
  } else {
    final fallback = File('$runDir/best-overall-profile.json');
    if (fallback.existsSync()) {
      profileSource = fallback;
    } else {
      emitStderr('Error: profile file not found for slot $slotId');
      return kExitError;
    }
  }

  Map<String, dynamic> profileJson;
  try {
    final decoded = jsonDecode(profileSource.readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('profile JSON must be an object');
    }
    profileJson = decoded;
    AiProfile.fromJson(profileJson);
  } on Object catch (e) {
    emitStderr('Error: invalid profile JSON: $e');
    return kExitError;
  }

  final destPath = blessedProfileAssetPath(repoRoot, name);
  final destFile = File(destPath);
  if (existing == null || force) {
    await destFile.parent.create(recursive: true);
    await destFile.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(profileJson)}\n',
    );
  }

  double resolvedFitness = state.bestOverall.fitness;
  for (final member in state.population) {
    if (member.slotId == slotId && member.fitnessHistory.isNotEmpty) {
      resolvedFitness = member.fitnessHistory.last;
      break;
    }
  }
  final entry = BlessedProfileManifestEntry(
    name: name,
    sourceRunId: state.runId,
    sourceProfileId: slotId,
    sourceFitness: resolvedFitness,
    blessedAt: DateTime.now().toUtc().toIso8601String(),
  );

  final updatedProfiles = [
    for (final row in manifest.profiles)
      if (row.name != name) row,
    entry,
  ]..sort((a, b) => a.name.compareTo(b.name));

  await BlessedProfileManifest(profiles: updatedProfiles).writeFile(manifestPath);

  emitStdout("Blessed profile '$name' -> $destPath");
  return 0;
}

String? _nextValue(
  List<String> args,
  int index,
  void Function(String line) emitStderr,
  String flag,
) {
  if (index >= args.length) {
    emitStderr('Error: $flag requires a value');
    return null;
  }
  return args[index];
}

String _blessUsage() => '''
Usage:
  melos run ga_runner -- bless --run <dir> --name <profile-name> [--profile <slot-id>] [--force]

Blesses a GA run profile into app/assets/profiles/ and updates manifest.json.
''';
