import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// PR-blocking structural check: `app/lib/widgets/**` must not directly import Flame.
///
/// SPEC: SPEC/program/repo-lint.md
int runCheckNoFlameInWidgets(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final widgetsDir = Directory(p.join(repoRoot, 'app', 'lib', 'widgets'));
  if (!widgetsDir.existsSync()) {
    logE('check_no_flame_in_widgets: app/lib/widgets not found.');
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
    final lines = const LineSplitter().convert(entity.readAsStringSync());
    for (var i = 0; i < lines.length; i++) {
      if (!lines[i].contains("import 'package:flame/")) {
        continue;
      }
      violations.add('$relativePath:${i + 1}: ${lines[i].trim()}');
    }
  }

  if (violations.isEmpty) {
    logI('check_no_flame_in_widgets: no violations found.');
    return 0;
  }

  logE(
    'check_no_flame_in_widgets: found ${violations.length} violation(s) under app/lib/widgets:',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckNoFlameInWidgets(Directory.current.path));
}
