import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const Set<String> _allowedFeatureBridgeWidgetFiles = {
  'app/lib/widgets/ct_region_map.dart',
};

/// PR-blocking structural check: `app/lib/widgets/**` must not import/export
/// `app/lib/features/**` paths (except temporary bridge wrappers).
///
/// SPEC: SPEC/program/repo-lint.md
int runCheckAppWidgetImports(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final widgetsDir = Directory(p.join(repoRoot, 'app', 'lib', 'widgets'));
  if (!widgetsDir.existsSync()) {
    logE('check_app_widget_imports: app/lib/widgets not found.');
    return 1;
  }

  final featureImportLine = RegExp(
    r'''^\s*(import|export)\s+(['"])(?:\.\./features/|package:colonizethis_app/features/)''',
  );
  final violations = <String>[];
  for (final entity in widgetsDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final relativePath = p.relative(entity.path, from: repoRoot);
    if (_allowedFeatureBridgeWidgetFiles.contains(relativePath)) {
      continue;
    }
    final lines = const LineSplitter().convert(entity.readAsStringSync());
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmedLeft = line.trimLeft();
      if (trimmedLeft.startsWith('//')) {
        continue;
      }
      if (!featureImportLine.hasMatch(line)) {
        continue;
      }
      violations.add('$relativePath:${i + 1}: ${line.trim()}');
    }
  }

  if (violations.isEmpty) {
    logI('check_app_widget_imports: no violations found.');
    return 0;
  }

  logE(
    'check_app_widget_imports: found ${violations.length} violation(s) under app/lib/widgets:',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAppWidgetImports(Directory.current.path));
}
