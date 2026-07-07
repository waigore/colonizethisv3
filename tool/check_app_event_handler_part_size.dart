// Caps each `app_event_handler_scope*.dart` part at 500 non-comment lines.
// Refs #3878 Phase 2 — session subscription decomposition.
import 'dart:io';

import 'package:path/path.dart' as p;

import 'check_dart_file_non_comment_line_size.dart'
    show countNonCommentLinesFromSource;

const _scopeServicesDir = 'app/lib/core/services/app_event_handler';
const _maxNonCommentLines = 500;

int runCheckAppEventHandlerPartSize(
  String repoRoot, {
  void Function(String line)? err,
}) {
  final logE = err ?? stderr.writeln;
  final dir = Directory(p.join(repoRoot, _scopeServicesDir));
  if (!dir.existsSync()) {
    logE('check_app_event_handler_part_size: missing $_scopeServicesDir');
    return 1;
  }

  final violations = <String>[];
  for (final entity in dir.listSync(followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final name = p.basename(entity.path);
    if (!name.startsWith('app_event_handler_scope')) continue;
    if (name == 'app_event_handler_scope.dart') continue;

    final source = entity.readAsStringSync();
    final lines = countNonCommentLinesFromSource(source);
    if (lines > _maxNonCommentLines) {
      violations.add(
        '${p.relative(entity.path, from: repoRoot)}: $lines non-comment lines '
        '(max $_maxNonCommentLines)',
      );
    }
  }

  if (violations.isEmpty) {
    return 0;
  }

  logE(
    'check_app_event_handler_part_size: '
    'app_event_handler_scope part files exceed $_maxNonCommentLines '
    'non-comment lines:',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  return 1;
}

void main() {
  exit(runCheckAppEventHandlerPartSize(Directory.current.path));
}
