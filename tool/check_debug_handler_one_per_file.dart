import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;

int runCheckDebugHandlerOnePerFile(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final servicesDir = Directory(
    p.join(repoRoot, 'app', 'lib', 'core', 'services', 'debug'),
  );
  if (!servicesDir.existsSync()) {
    logE('check_debug_handler_one_per_file: app/lib/core/services/debug not found.');
    return 1;
  }

  final handlerFiles =
      servicesDir
          .listSync(recursive: false, followLinks: false)
          .whereType<File>()
          .where(
            (file) =>
                p.basename(file.path).startsWith('app_event_handler_debug_') &&
                file.path.endsWith('.dart'),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final violations = <String>[];

  for (final file in handlerFiles) {
    final relativePath = p.relative(file.path, from: repoRoot);
    final content = file.readAsStringSync();
    if (_isDartPartFragmentFile(content)) {
      continue;
    }
    final parsed = parseString(
      content: content,
      path: relativePath,
    );
    final applyFns = parsed.unit.declarations
        .whereType<FunctionDeclaration>()
        .where((decl) => decl.name.lexeme.startsWith('applyDebug'))
        .toList();
    if (applyFns.length == 1) {
      continue;
    }
    violations.add(
      '$relativePath has ${applyFns.length} top-level applyDebug* function(s); expected exactly 1',
    );
  }

  if (violations.isEmpty) {
    logI('check_debug_handler_one_per_file: no violations found.');
    return 0;
  }
  logE('check_debug_handler_one_per_file: ${violations.length} violation(s):');
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

/// True when the first non-empty, non-line-comment line is a `part of` directive.
bool _isDartPartFragmentFile(String content) {
  for (final raw in content.split('\n')) {
    final line = raw.trimLeft();
    if (line.isEmpty) {
      continue;
    }
    if (line.startsWith('//')) {
      continue;
    }
    return line.startsWith('part of ');
  }
  return false;
}

void main() {
  exit(runCheckDebugHandlerOnePerFile(Directory.current.path));
}
