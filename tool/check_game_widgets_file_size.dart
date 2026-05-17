// Physical line limit for game feature widgets (`repo.game_widgets_file_size`).
// SPEC: SPEC/program/game-widgets-file-size.md
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const _maxPhysicalLines = 700;

/// PR-blocking structural check: files under
/// `app/lib/features/game/widgets/**` must stay at or below 700 physical lines.
int runCheckGameWidgetsFileSize(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final widgetsDir = Directory(
    p.join(repoRoot, 'app', 'lib', 'features', 'game', 'widgets'),
  );
  if (!widgetsDir.existsSync()) {
    logE(
      'check_game_widgets_file_size: app/lib/features/game/widgets not found.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final entity in widgetsDir.listSync(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final relativePath = p.relative(entity.path, from: repoRoot);
    final physicalLines = const LineSplitter()
        .convert(entity.readAsStringSync())
        .length;
    if (physicalLines <= _maxPhysicalLines) {
      continue;
    }
    violations.add(
      '$relativePath ($physicalLines physical lines > $_maxPhysicalLines)',
    );
  }

  if (violations.isEmpty) {
    logI('check_game_widgets_file_size: no violations found.');
    return 0;
  }

  logE(
    'check_game_widgets_file_size: found ${violations.length} violation(s) under app/lib/features/game/widgets:',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckGameWidgetsFileSize(Directory.current.path));
}
