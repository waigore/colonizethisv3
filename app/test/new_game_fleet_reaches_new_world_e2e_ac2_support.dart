// AC2 source-reading helpers for fleet-reach E2E library pin (Refs #2336).

import 'dart:io';

const String fleetReachE2eIntegrationTestRelativePath =
    'integration_test/new_game_fleet_reaches_new_world_e2e_test.dart';

const List<String> fleetReachE2eRetiredHelpersPartFileRelativePaths = <String>[
  'integration_test/new_game_fleet_reaches_new_world_e2e_helpers.dart',
  'integration_test/new_game_fleet_reaches_new_world_e2e_helpers_part2.dart',
];

const List<String> fleetReachE2eRetiredPrivateConstantNames = <String>[
  '_kMaxNextTurnTapsForNwFleetReach',
  '_kMaxUiResponseWait',
  '_kFleetE2eMaxWallClock',
];

final RegExp fleetReachE2eFileScopePrivateConstantPattern = RegExp(
  r'^const\s+(?:final\s+)?[A-Za-z_<>?,\s\.]+?\s+_k[A-Za-z0-9_]+\s*=',
  multiLine: true,
);

List<File> fleetReachE2eIntegrationTestSourceCandidates(String relativePath) {
  final repoRoot = Directory.current.path;
  return <File>[
    File('$repoRoot/$relativePath'),
    File('$repoRoot/app/$relativePath'),
    File('$repoRoot/../$relativePath'),
  ];
}

String readFleetReachE2eIntegrationTestSource(String relativePath) {
  for (final file in fleetReachE2eIntegrationTestSourceCandidates(relativePath)) {
    if (file.existsSync()) {
      return file.readAsStringSync();
    }
  }
  throw StateError(
    'Could not locate integration test source at any of: '
    '${fleetReachE2eIntegrationTestSourceCandidates(relativePath).map((f) => f.path).join(', ')}.',
  );
}

String stripDartComments(String source) {
  return source
      .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
      .replaceAll(RegExp(r'//[^\n]*'), '');
}
