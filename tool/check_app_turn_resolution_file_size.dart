// Physical line limit for turn-resolution Dart (`repo.app_turn_resolution_file_size`).
// SPEC: SPEC/program/app-turn-resolution-file-size.md (wave-17 #4512 Slice B).
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Ratchet ceiling for hand-written Dart under
/// `app/lib/features/game/turn_resolution/**`.
const int appTurnResolutionFileSizeCeiling = 260;

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');

/// PR-blocking structural check: files under
/// `app/lib/features/game/turn_resolution/**` must stay at or below 260
/// physical lines (Refs #4512 AC6 / AC8, #4582).
int runCheckAppTurnResolutionFileSize(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final turnResolutionDir = Directory(
    p.join(repoRoot, 'app', 'lib', 'features', 'game', 'turn_resolution'),
  );
  if (!turnResolutionDir.existsSync()) {
    logE(
      'check_app_turn_resolution_file_size: '
      'app/lib/features/game/turn_resolution not found.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final entity in turnResolutionDir.listSync(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final relativePath = p
        .relative(entity.path, from: repoRoot)
        .replaceAll('\\', '/');
    if (_generatedSuffix.hasMatch(relativePath)) {
      continue;
    }
    final physicalLines = const LineSplitter()
        .convert(entity.readAsStringSync())
        .length;
    if (physicalLines <= appTurnResolutionFileSizeCeiling) {
      continue;
    }
    violations.add(
      '$relativePath ($physicalLines physical lines > '
      '$appTurnResolutionFileSizeCeiling)',
    );
  }

  if (violations.isEmpty) {
    logI(
      'check_app_turn_resolution_file_size: no violations found '
      '(ceiling $appTurnResolutionFileSizeCeiling; Refs #4512).',
    );
    return 0;
  }

  logE(
    'check_app_turn_resolution_file_size: found ${violations.length} '
    'violation(s) under app/lib/features/game/turn_resolution:',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAppTurnResolutionFileSize(Directory.current.path));
}
