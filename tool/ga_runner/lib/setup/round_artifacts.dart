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
  await Directory(roundDir).create(recursive: true);
  final setupFile = File('$roundDir/setup.json');
  await setupFile.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(gameSetupConfigToJson(setup))}\n',
  );
  final profilesDir = Directory('$roundDir/profiles');
  await profilesDir.create(recursive: true);
  await File('${profilesDir.path}/gp1.json').writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(profileA.toJson())}\n',
  );
  await File('${profilesDir.path}/gp2.json').writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(profileB.toJson())}\n',
  );
  await File('$roundDir/capitals.json').writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(capitalProvinces)}\n',
  );
}

Map<String, String> readCapitalProvinces(String roundDir) {
  final file = File('$roundDir/capitals.json');
  if (!file.existsSync()) return const <String, String>{};
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, dynamic>) return const <String, String>{};
  return decoded.map((k, v) => MapEntry(k, v.toString()));
}
