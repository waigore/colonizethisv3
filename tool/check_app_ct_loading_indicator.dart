import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// PR-blocking structural check: CircularProgressIndicator usage in app/lib.
///
/// Enforces that runtime code in `app/lib/` uses the shared CtLoadingIndicator
/// widget instead of ad-hoc CircularProgressIndicator instances.
///
/// Allowed:
/// - Direct CircularProgressIndicator usage in `app/lib/widgets/ct_loading_indicator.dart`
///
/// Disallowed:
/// - Any other `CircularProgressIndicator` constructor calls under `app/lib/`
int runCheckAppCtLoadingIndicator(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final appLibDir = Directory(p.join(repoRoot, 'app', 'lib'));
  if (!appLibDir.existsSync()) {
    logE('check_app_ct_loading_indicator: app/lib not found.');
    return 1;
  }

  const allowedRelativePath = 'app/lib/widgets/ct_loading_indicator.dart';
  final violations = <String>[];

  for (final entity in appLibDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }

    final relativePath = p.relative(entity.path, from: repoRoot);
    if (relativePath == allowedRelativePath) {
      continue;
    }

    final lines = const LineSplitter().convert(entity.readAsStringSync());
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('//')) {
        continue;
      }
      if (!line.contains('CircularProgressIndicator')) {
        continue;
      }
      violations.add('$relativePath:${i + 1}: ${line.trim()}');
    }
  }

  if (violations.isEmpty) {
    logI('check_app_ct_loading_indicator: no violations found.');
    return 0;
  }

  logE(
    'check_app_ct_loading_indicator: found ${violations.length} violation(s) '
    'in app/lib (CircularProgressIndicator outside ct_loading_indicator.dart):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }

  return 1;
}

void main() {
  exit(runCheckAppCtLoadingIndicator(Directory.current.path));
}

