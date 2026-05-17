import 'dart:io';

import 'package:path/path.dart' as p;

const _targetRelativePath = 'app/lib/core/services/app_event_handler_scope.dart';
const _disallowedImportNeedle = 'package:colonizethis_app/features/game/logic/';

/// Enforces app-event scope boundary:
/// `app_event_handler_scope.dart` must not directly import
/// `features/game/logic/**`.
///
/// SPEC: SPEC/program/repo-lint.md
int runCheckAppEventHandlerScopeLogicBoundary(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final filePath = p.join(repoRoot, _targetRelativePath);
  final file = File(filePath);
  if (!file.existsSync()) {
    logE(
      'check_app_event_handler_scope_logic_boundary: target not found: $_targetRelativePath',
    );
    return 1;
  }

  final lines = file.readAsLinesSync();
  final violations = <String>[];
  for (var i = 0; i < lines.length; i++) {
    final trimmed = lines[i].trim();
    if (trimmed.startsWith('//')) {
      continue;
    }
    if (!trimmed.startsWith('import ')) {
      continue;
    }
    if (!trimmed.contains(_disallowedImportNeedle)) {
      continue;
    }
    violations.add(
      '$_targetRelativePath:${i + 1}: direct import from features/game/logic is disallowed',
    );
  }

  if (violations.isEmpty) {
    logI('check_app_event_handler_scope_logic_boundary: no violations found.');
    return 0;
  }

  logE(
    'check_app_event_handler_scope_logic_boundary: found ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAppEventHandlerScopeLogicBoundary(Directory.current.path));
}
