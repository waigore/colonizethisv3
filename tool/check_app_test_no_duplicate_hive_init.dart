import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

/// PR-blocking gate: `Hive.init` in `app/test/**` must live only in the
/// approved harness module (Refs #4680).
const _kApprovedHarnessRelativePath = 'app/test/app_test_hive_harness.dart';

int runCheckAppTestNoDuplicateHiveInit(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final appTestDir = Directory(p.join(repoRoot, 'app', 'test'));
  if (!appTestDir.existsSync()) {
    logI(
      'check_app_test_no_duplicate_hive_init: app/test not found; nothing to scan.',
    );
    return 0;
  }

  final violations = <String>[];

  for (final entity in appTestDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final relativePath = p
        .relative(entity.path, from: repoRoot)
        .replaceAll('\\', '/');
    if (relativePath == _kApprovedHarnessRelativePath) {
      continue;
    }
    if (relativePath.endsWith('.g.dart') ||
        relativePath.endsWith('.mocks.dart')) {
      continue;
    }
    final content = entity.readAsStringSync();
    final parsed = parseString(content: content, path: relativePath);
    final visitor = _HiveInitVisitor(
      relativePath: relativePath,
      lineInfo: parsed.unit.lineInfo,
      violations: violations,
    );
    parsed.unit.accept(visitor);
  }

  if (violations.isEmpty) {
    logI(
      'check_app_test_no_duplicate_hive_init: no duplicate Hive.init call sites '
      'found outside $_kApprovedHarnessRelativePath.',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_app_test_no_duplicate_hive_init: found ${violations.length} '
    'violation(s):',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  logE(
    '   Use openAppTestHiveBox from $_kApprovedHarnessRelativePath.',
  );
  return 1;
}

class _HiveInitVisitor extends RecursiveAstVisitor<void> {
  _HiveInitVisitor({
    required this.relativePath,
    required this.lineInfo,
    required this.violations,
  });

  final String relativePath;
  final LineInfo lineInfo;
  final List<String> violations;

  void _report(int offset, String detail) {
    final line = lineInfo.getLocation(offset).lineNumber;
    violations.add('$relativePath:$line: $detail');
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    if (target is SimpleIdentifier && target.name == 'Hive') {
      final method = node.methodName.name;
      if (method == 'init') {
        _report(
          node.offset,
          'Hive.init duplicates the approved app test harness',
        );
      }
    }
    super.visitMethodInvocation(node);
  }
}

void main(List<String> args) {
  final repoRoot = args.isNotEmpty ? args.first : Directory.current.path;
  exit(runCheckAppTestNoDuplicateHiveInit(repoRoot));
}
