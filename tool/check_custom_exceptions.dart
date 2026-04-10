import 'dart:io';

import 'package:colonizethis_exception_lint/exception_enforcement.dart';
import 'package:path/path.dart' as p;

final _domainRoots = <String>[
  'packages',
  'app/lib',
  'ctdev/lib',
  'ctterm/lib',
  'tool',
];

/// PR-blocking check for generic exception throws in runtime domain code.
///
/// SPEC: SPEC/program/exception-enforcement.md
void main() {
  final repoRoot = Directory.current.path;
  final dartFiles = _collectDomainDartFiles(repoRoot);
  final violations = <CustomExceptionViolation>[];

  for (final file in dartFiles) {
    final relativePath = p.relative(file.path, from: repoRoot);
    final content = file.readAsStringSync();
    violations.addAll(findCustomExceptionViolations(relativePath, content));
  }

  if (violations.isEmpty) {
    stdout.writeln('check_custom_exceptions: no violations found.');
    return;
  }

  stderr.writeln(
    'check_custom_exceptions: found ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    stderr.writeln(
      ' - ${violation.path}:${violation.line}: '
      'throwing ${violation.exceptionType} is forbidden; use a domain-specific exception type',
    );
  }
  exitCode = 1;
}

List<File> _collectDomainDartFiles(String repoRoot) {
  final files = <File>[];
  for (final domainRoot in _domainRoots) {
    final base = Directory(p.join(repoRoot, domainRoot));
    if (!base.existsSync()) {
      continue;
    }
    for (final entity in base.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      if (!entity.path.endsWith('.dart')) {
        continue;
      }
      final rel = p.relative(entity.path, from: repoRoot);
      if (rel.contains('/test/') || rel.endsWith('_test.dart')) {
        continue;
      }
      if (!rel.contains('/lib/')) {
        continue;
      }
      if (rel.endsWith('.g.dart') ||
          rel.endsWith('.freezed.dart') ||
          rel.endsWith('.mocks.dart')) {
        continue;
      }
      files.add(entity);
    }
  }
  return files;
}
