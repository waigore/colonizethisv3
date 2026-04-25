import 'dart:io';

import 'package:path/path.dart' as p;

/// PR-blocking structural check: `app/lib/features/game/widgets/**` must not
/// contain `*_screen.dart` files.
///
/// SPEC: SPEC/program/repo-lint.md
int runCheckNoScreenInGameWidgets(
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
      'check_no_screen_in_game_widgets: app/lib/features/game/widgets not found.',
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
    final baseName = p.basename(entity.path);
    if (!baseName.endsWith('_screen.dart')) {
      continue;
    }
    violations.add(p.relative(entity.path, from: repoRoot));
  }

  if (violations.isEmpty) {
    logI('check_no_screen_in_game_widgets: no violations found.');
    return 0;
  }

  logE(
    'check_no_screen_in_game_widgets: found ${violations.length} violation(s) under app/lib/features/game/widgets:',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckNoScreenInGameWidgets(Directory.current.path));
}
