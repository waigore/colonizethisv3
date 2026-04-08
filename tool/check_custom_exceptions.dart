import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

final _domainRoots = <String>[
  'packages',
  'app/lib',
  'ctdev/lib',
  'ctterm/lib',
  'tool',
];

final _forbiddenExceptionTypes = <String>{'ArgumentError', 'Exception'};

// Temporary rollout allowlist for known legacy generic throws outside the setup
// domain migration in issue #1615.
final _legacyAllowlist = <String>{
  'app/lib/features/game/flame/terrain_tileset.dart',
  'ctterm/lib/screens/pending_intervention_screen.dart',
  'packages/colonizethis_data/lib/src/map_topology.dart',
  'packages/colonizethis_map/lib/src/tile_map_generator.dart',
  'packages/colonizethis_models/lib/src/fleet.dart',
  'packages/colonizethis_models/lib/src/orders.dart',
  'tool/sim_scenarios/lib/game_factory.dart',
};

void main() {
  final repoRoot = Directory.current.path;
  final dartFiles = _collectDomainDartFiles(repoRoot);
  final violations = <_Violation>[];

  for (final file in dartFiles) {
    final relativePath = p.relative(file.path, from: repoRoot);
    if (_legacyAllowlist.contains(relativePath)) {
      continue;
    }
    final content = file.readAsStringSync();
    final parsed = parseString(
      content: content,
      path: file.path,
      throwIfDiagnostics: false,
    );
    final visitor = _ThrowVisitor(relativePath, parsed.lineInfo);
    parsed.unit.accept(visitor);
    violations.addAll(visitor.violations);
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

class _ThrowVisitor extends RecursiveAstVisitor<void> {
  _ThrowVisitor(this.path, this.lineInfo);

  final String path;
  final LineInfo lineInfo;
  final List<_Violation> violations = [];

  @override
  void visitThrowExpression(ThrowExpression node) {
    final expression = node.expression;
    if (expression is! InstanceCreationExpression) {
      return;
    }
    final rawTypeName = expression.constructorName.type.toSource();
    final typeName = rawTypeName.split('<').first;
    if (_forbiddenExceptionTypes.contains(typeName)) {
      final line = lineInfo.getLocation(node.offset).lineNumber;
      violations.add(
        _Violation(path: path, line: line, exceptionType: typeName),
      );
    }
  }
}

class _Violation {
  const _Violation({
    required this.path,
    required this.line,
    required this.exceptionType,
  });

  final String path;
  final int line;
  final String exceptionType;
}
