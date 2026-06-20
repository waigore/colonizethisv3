import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';

import '../config/ga_config.dart';

/// Writes observer setup and per-slot profile JSON for a 2-player game.
Future<void> materializeRoundArtifacts({
  required String roundDir,
  required GameSetupConfig setup,
  required AiProfile profileA,
  required AiProfile profileB,
  required Map<String, String> capitalProvinces,
}) async {
  await materializeMultiPlayerRoundArtifacts(
    roundDir: roundDir,
    setup: setup,
    profilesBySlot: <String, AiProfile>{
      'gp1': profileA,
      'gp2': profileB,
    },
    capitalProvinces: capitalProvinces,
  );
}

/// Writes observer setup and `gp1`…`gpN` profile JSON for an N-player game.
Future<void> materializeMultiPlayerRoundArtifacts({
  required String roundDir,
  required GameSetupConfig setup,
  required Map<String, AiProfile> profilesBySlot,
  required Map<String, String> capitalProvinces,
}) async {
  if (profilesBySlot.length != setup.greatPowerCount) {
    throw FormatException(
      'profilesBySlot length (${profilesBySlot.length}) must match '
      'setup.greatPowerCount (${setup.greatPowerCount})',
    );
  }
  await Directory(roundDir).create(recursive: true);
  final setupFile = File('$roundDir/setup.json');
  await setupFile.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(gameSetupConfigToJson(setup))}\n',
  );
  final profilesDir = Directory('$roundDir/profiles');
  await profilesDir.create(recursive: true);
  for (final entry in profilesBySlot.entries) {
    await File('${profilesDir.path}/${entry.key}.json').writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(entry.value.toJson())}\n',
    );
  }
  await File('$roundDir/capitals.json').writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(capitalProvinces)}\n',
  );
}

/// Deletes the heavy `observer-traces` subtree under [roundDir].
///
/// Safe to call after a game has been scored: fitness reads the final snapshot
/// and `run-summary.json` during scoring, and nothing downstream
/// (prior-winner loading, generation artifacts) reads observer traces. The
/// lightweight round inputs (`setup.json`, `profiles/`, `capitals.json`) are
/// retained. Returns `true` when a trace directory existed and was removed.
Future<bool> pruneRoundObserverTraces(String roundDir) async {
  final traceRoot = Directory('$roundDir/observer-traces');
  if (!traceRoot.existsSync()) return false;
  await traceRoot.delete(recursive: true);
  return true;
}

Map<String, String> readCapitalProvinces(String roundDir) {
  final file = File('$roundDir/capitals.json');
  if (!file.existsSync()) return const <String, String>{};
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, dynamic>) return const <String, String>{};
  return decoded.map((k, v) => MapEntry(k, v.toString()));
}
