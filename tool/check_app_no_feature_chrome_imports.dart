import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// PR-blocking structural gate: no production or test Dart may import the
/// deleted feature chrome shim path
/// `package:colonizethis_app/features/game/widgets/chrome/...` or a relative
/// `.../chrome/ct_*.dart` under that tree (Refs #4035 AC2).
///
/// Shared Ct-* chrome lives under `app/lib/widgets/`. Call sites must use
/// `package:colonizethis_app/widgets/...`.
///
/// SPEC: `SPEC/program/repo-lint.md`.
const _bannedPackagePrefix =
    'package:colonizethis_app/features/game/widgets/chrome/';
final RegExp _bannedRelativeImport = RegExp(
  r'''^\s*(import|export)\s+(['"])(?:\.\./)+(?:widgets/)?chrome/ct_[a-z0-9_]+\.dart\2''',
);
final RegExp _bannedPackageImport = RegExp(
  r'''^\s*(import|export)\s+(['"])'''
  '${RegExp.escape(_bannedPackagePrefix)}'
  r'''[^'"]+\2''',
);

void main(List<String> args) {
  exit(runCheckAppNoFeatureChromeImports(Directory.current.path));
}

int runCheckAppNoFeatureChromeImports(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final chromeDir = Directory(
    p.join(repoRoot, 'app/lib/features/game/widgets/chrome'),
  );
  final violations = <String>[];
  if (chromeDir.existsSync()) {
    violations.add(
      'app/lib/features/game/widgets/chrome/: directory must not exist '
      '(shared chrome lives under app/lib/widgets/).',
    );
  }

  final scanRoots = <Directory>[
    Directory(p.join(repoRoot, 'app')),
    Directory(p.join(repoRoot, 'packages')),
    Directory(p.join(repoRoot, 'widgetbook_host')),
    Directory(p.join(repoRoot, 'test')),
    Directory(p.join(repoRoot, 'tool')),
  ];

  for (final root in scanRoots) {
    if (!root.existsSync()) continue;
    for (final entity in root.listSync(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final relativePath = p
          .relative(entity.path, from: repoRoot)
          .replaceAll('\\', '/');
      if (_shouldSkipPath(relativePath)) continue;
      final lines = const LineSplitter().convert(entity.readAsStringSync());
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmedLeft = line.trimLeft();
        if (trimmedLeft.startsWith('//')) continue;
        if (_bannedPackageImport.hasMatch(line) ||
            _bannedRelativeImport.hasMatch(line)) {
          violations.add('$relativePath:${i + 1}: ${line.trim()}');
        }
      }
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_app_no_feature_chrome_imports: no feature chrome shim imports; '
      'chrome directory absent.',
    );
    return 0;
  }

  logE(
    'check_app_no_feature_chrome_imports: found ${violations.length} '
    'violation(s):',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  logE(
    'Fix: import/export from package:colonizethis_app/widgets/... and keep '
    'app/lib/features/game/widgets/chrome/ deleted.',
  );
  return 1;
}

bool _shouldSkipPath(String relativePath) {
  if (relativePath.contains('/.dart_tool/') ||
      relativePath.contains('/build/')) {
    return true;
  }
  for (final marker in repoLintFixtureDirPathMarkers) {
    if (('/$relativePath').contains(marker)) {
      return true;
    }
  }
  return false;
}
