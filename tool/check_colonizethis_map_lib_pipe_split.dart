import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

/// Map tile keys and other pipe-delimited map strings: `.split('|')` must live
/// only in [tile_key_util.dart] (tile keys) or [map_pipe_string_util.dart]
/// (ports/seaboard keys, topology pairs, sea-zone scope segments). GitHub #2087.
const _allowedSplitPipeLiteralPaths = <String>{
  'packages/colonizethis_map/lib/src/tile_key_util.dart',
  'packages/colonizethis_map/lib/src/map_pipe_string_util.dart',
};

const _mapLibRoot = 'packages/colonizethis_map/lib';

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckColonizethisMapLibPipeSplit(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final libDir = Directory(p.join(root, _mapLibRoot));
  if (!libDir.existsSync()) {
    logE('check_colonizethis_map_lib_pipe_split: missing $libDir');
    return 1;
  }

  final violations = <ColonizethisMapLibPipeSplitViolation>[];
  for (final file in libDir.listSync(recursive: true, followLinks: false)) {
    if (file is! File || !file.path.endsWith('.dart')) {
      continue;
    }
    final relPath = p.normalize(p.relative(file.path, from: root));
    if (_allowedSplitPipeLiteralPaths.contains(relPath)) {
      continue;
    }
    final source = file.readAsStringSync();
    violations.addAll(
      findColonizethisMapLibPipeSplitViolations(
        relativePath: relPath,
        source: source,
      ),
    );
  }

  if (violations.isEmpty) {
    logI('colonizethis_map lib pipe-split check passed.');
    return 0;
  }

  logE(
    'ERROR: `.split(\'|\')` must only appear in ${_allowedSplitPipeLiteralPaths.join(", ")}.',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line}:${v.column} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckColonizethisMapLibPipeSplit(Directory.current.path));
}

List<ColonizethisMapLibPipeSplitViolation>
findColonizethisMapLibPipeSplitViolations({
  required String relativePath,
  required String source,
}) {
  final parsed = parseString(
    content: source,
    path: relativePath,
    throwIfDiagnostics: false,
  );
  final visitor = _SplitPipeLiteralVisitor(
    path: relativePath,
    unit: parsed.unit,
  );
  parsed.unit.accept(visitor);
  return visitor.violations;
}

class ColonizethisMapLibPipeSplitViolation {
  const ColonizethisMapLibPipeSplitViolation({
    required this.path,
    required this.line,
    required this.column,
    required this.message,
  });

  final String path;
  final int line;
  final int column;
  final String message;
}

class _SplitPipeLiteralVisitor extends RecursiveAstVisitor<void> {
  _SplitPipeLiteralVisitor({required this.path, required this.unit});

  final String path;
  final CompilationUnit unit;
  final List<ColonizethisMapLibPipeSplitViolation> violations = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'split' && _firstArgIsPipeStringLiteral(node)) {
      final loc = unit.lineInfo.getLocation(node.offset);
      violations.add(
        ColonizethisMapLibPipeSplitViolation(
          path: path,
          line: loc.lineNumber,
          column: loc.columnNumber,
          message:
              'Disallowed `.split(\'|\')`; use tile_key_util or map_pipe_string_util.',
        ),
      );
    }
    super.visitMethodInvocation(node);
  }

  bool _firstArgIsPipeStringLiteral(MethodInvocation node) {
    final args = node.argumentList.arguments;
    if (args.isEmpty) {
      return false;
    }
    final first = args.first;
    if (first is SimpleStringLiteral) {
      return first.value == '|';
    }
    return false;
  }
}
