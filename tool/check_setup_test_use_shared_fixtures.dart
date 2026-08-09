import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

/// Setup package tests must use shared [TestFixtures] / [configWithOverrides]
/// instead of re-inlining empty [Game]/[WorldState] shells or full
/// [GameSetupConfig] rebuilds (Refs #4029), and assert-only tests sharing an
/// identical `(config, defaultInitOptions)` pair must reuse one memoized
/// `sharedInitGameResult` pipeline run instead of repeated `runInitGame`
/// calls (Refs #4054). Determinism-comparison double runs live inside a
/// single test body and are structurally exempt (only cross-body duplicates
/// are flagged).
const String _setupTestPathPrefix = 'packages/colonizethis_setup/test/';

const String _configSupportRelativePath =
    'packages/colonizethis_setup/test/setup/'
    'init_game_orchestrator_test_support.dart';

final RegExp _inlineGameConstructor = RegExp(r'\bGame\s*\(');
final RegExp _inlineWorldStateConstructor = RegExp(r'\bWorldState\s*\(');
final RegExp _inlineGameSetupConfigConstructor = RegExp(
  r'\bGameSetupConfig\s*\(',
);

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckSetupTestUseSharedFixtures(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final dir = Directory(p.join(root, 'packages/colonizethis_setup/test'));
  if (!dir.existsSync()) {
    logI('Setup test shared-fixtures check skipped (test dir absent).');
    return 0;
  }

  final violations = <SetupTestSharedFixturesViolation>[];
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final slashPath = p.relative(entity.path, from: root).replaceAll('\\', '/');
    final content = entity.readAsStringSync();
    final reason = setupTestSharedFixturesViolationReason(slashPath, content);
    if (reason != null) {
      violations.add(
        SetupTestSharedFixturesViolation(path: slashPath, message: reason),
      );
    }
    violations.addAll(
      findSetupTestDuplicateInitRunViolations(slashPath, content),
    );
  }

  if (violations.isEmpty) {
    logI('Setup test shared-fixtures check passed.');
    return 0;
  }

  logE(
    'ERROR: Setup tests must use TestFixtures / configWithOverrides '
    '(or lockedFullInitConfig) instead of inlining empty Game/WorldState '
    'shells or GameSetupConfig rebuilds (Refs #4029).',
  );
  for (final v in violations) {
    logE('${v.path} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckSetupTestUseSharedFixtures(Directory.current.path));
}

/// True when repo-relative [slashPath] is under the setup package `test/` tree.
bool setupTestUseSharedFixturesPathInScope(String slashPath) =>
    slashPath.replaceAll('\\', '/').startsWith(_setupTestPathPrefix);

/// Returns a violation reason when [content] of an in-scope setup test file
/// re-inlines empty game/world shells or full [GameSetupConfig] constructors,
/// or `null` when compliant.
String? setupTestSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!setupTestUseSharedFixturesPathInScope(normalized)) return null;
  final code = _stripLineComments(content);

  if (normalized != _configSupportRelativePath &&
      _inlineGameSetupConfigConstructor.hasMatch(code)) {
    return 're-inlines GameSetupConfig(...); use configWithOverrides / '
        'lockedFullInitConfig from init_game_orchestrator_test_support.dart '
        '(Refs #4029)';
  }

  final inlineGame = _inlineGameConstructor.hasMatch(code);
  final inlineWorldState = _inlineWorldStateConstructor.hasMatch(code);
  if (!inlineGame && !inlineWorldState) return null;

  final parts = <String>[
    if (inlineGame) 'Game(...)',
    if (inlineWorldState) 'WorldState(...)',
  ];
  return 're-inlines ${parts.join(' + ')}; use TestFixtures '
      '(package:colonizethis_test/game_test_fixtures.dart) or a thin support '
      'delegate (Refs #4029)';
}

/// Flags `runInitGame(config: <expr>, options: defaultInitOptions)` calls in
/// an in-scope setup test file when the **same config expression** is run in
/// **two or more distinct function bodies** (Refs #4054). Such assert-only
/// repeats must reuse the memoized `sharedInitGameResult(config)` harness in
/// `init_game_orchestrator_test_support.dart`.
///
/// Structural exemptions (no allowlist needed):
/// - Determinism double runs (two calls in the **same** test body) are not
///   flagged.
/// - Calls with custom [InitGameOptions] or extra arguments (for example
///   `generateRegion:`) are skipped — the harness only memoizes
///   `defaultInitOptions` runs.
/// - A `config:` identifier declared more than once in the file resolves to
///   its body-scoped occurrence, so unrelated locals sharing a name never
///   group together.
/// - The support file defining the harness is exempt.
List<SetupTestSharedFixturesViolation> findSetupTestDuplicateInitRunViolations(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!setupTestUseSharedFixturesPathInScope(normalized)) return const [];
  if (normalized == _configSupportRelativePath) return const [];
  if (!content.contains('runInitGame(')) return const [];

  final parsed = parseString(
    content: content,
    featureSet: FeatureSet.latestLanguageVersion(),
    throwIfDiagnostics: false,
  );
  final collector = _InitRunCallCollector();
  parsed.unit.accept(collector);

  final singleDeclInitializers = _singleDeclarationInitializers(parsed.unit);
  final lineInfo = parsed.unit.lineInfo;

  final callsByConfigKey = <String, List<_InitRunCall>>{};
  for (final call in collector.calls) {
    final key = _configKeyForCall(call, singleDeclInitializers);
    if (key == null) continue;
    callsByConfigKey.putIfAbsent(key, () => []).add(call);
  }

  final violations = <SetupTestSharedFixturesViolation>[];
  final keys = callsByConfigKey.keys.toList()..sort();
  for (final key in keys) {
    final calls = callsByConfigKey[key]!;
    final bodies = calls.map((c) => c.enclosingBodyOffset).toSet();
    if (calls.length < 2 || bodies.length < 2) continue;
    final lines = calls
        .map((c) => lineInfo.getLocation(c.offset).lineNumber)
        .toList();
    violations.add(
      SetupTestSharedFixturesViolation(
        path: normalized,
        message:
            'runs runInitGame with the identical config `$key` in '
            '${bodies.length} test bodies (lines ${lines.join(', ')}); '
            'reuse sharedInitGameResult(config) from '
            'init_game_orchestrator_test_support.dart (Refs #4054)',
      ),
    );
  }
  return violations;
}

/// Resolves the grouping key for a `runInitGame` call, or `null` when the
/// call is out of scope for the duplicate rule (custom options or extra
/// arguments).
String? _configKeyForCall(
  _InitRunCall call,
  Map<String, String> singleDeclInitializers,
) {
  if (!call.optionsIsDefault || call.hasExtraArguments) return null;
  final configSource = call.configSource;
  if (configSource == null) return null;
  if (call.configIsIdentifier) {
    final initializer = singleDeclInitializers[configSource];
    if (initializer != null) return _normalizeSource(initializer);
    // Ambiguous or undeclared identifier: keep it body-scoped so unrelated
    // locals sharing a name never group across bodies.
    return '$configSource@${call.enclosingBodyOffset}';
  }
  return _normalizeSource(configSource);
}

/// Maps variable names declared exactly once in [unit] to their initializer
/// source; names with multiple declarations are omitted.
Map<String, String> _singleDeclarationInitializers(CompilationUnit unit) {
  final visitor = _VariableDeclarationCollector();
  unit.accept(visitor);
  final result = <String, String>{};
  visitor.declarationsByName.forEach((name, initializers) {
    if (initializers.length == 1) {
      result[name] = initializers.single;
    }
  });
  return result;
}

String _normalizeSource(String source) =>
    source.replaceAll(RegExp(r'\s+'), ' ').trim();

class _InitRunCall {
  const _InitRunCall({
    required this.offset,
    required this.enclosingBodyOffset,
    required this.configSource,
    required this.configIsIdentifier,
    required this.optionsIsDefault,
    required this.hasExtraArguments,
  });

  final int offset;
  final int enclosingBodyOffset;
  final String? configSource;
  final bool configIsIdentifier;
  final bool optionsIsDefault;
  final bool hasExtraArguments;
}

class _InitRunCallCollector extends RecursiveAstVisitor<void> {
  final calls = <_InitRunCall>[];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);
    if (node.methodName.name != 'runInitGame') return;

    String? configSource;
    var configIsIdentifier = false;
    var optionsIsDefault = false;
    var extraArguments = false;
    for (final arg in node.argumentList.arguments) {
      if (arg is! NamedExpression) {
        extraArguments = true;
        continue;
      }
      final name = arg.name.label.name;
      final expression = arg.expression;
      switch (name) {
        case 'config':
          configSource = expression.toSource();
          configIsIdentifier = expression is SimpleIdentifier;
        case 'options':
          optionsIsDefault = expression.toSource() == 'defaultInitOptions';
        default:
          extraArguments = true;
      }
    }

    calls.add(
      _InitRunCall(
        offset: node.offset,
        enclosingBodyOffset: _enclosingBodyOffset(node),
        configSource: configSource,
        configIsIdentifier: configIsIdentifier,
        optionsIsDefault: optionsIsDefault,
        hasExtraArguments: extraArguments,
      ),
    );
  }

  int _enclosingBodyOffset(AstNode node) {
    for (
      AstNode? current = node.parent;
      current != null;
      current = current.parent
    ) {
      if (current is FunctionBody) return current.offset;
    }
    return 0;
  }
}

class _VariableDeclarationCollector extends RecursiveAstVisitor<void> {
  final declarationsByName = <String, List<String>>{};

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);
    final initializer = node.initializer;
    if (initializer == null) return;
    declarationsByName
        .putIfAbsent(node.name.lexeme, () => [])
        .add(initializer.toSource());
  }
}

String _stripLineComments(String content) {
  final out = StringBuffer();
  for (final line in content.split('\n')) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('//') || trimmed.startsWith('*')) {
      continue;
    }
    out.writeln(line);
  }
  return out.toString();
}

class SetupTestSharedFixturesViolation {
  const SetupTestSharedFixturesViolation({
    required this.path,
    required this.message,
  });

  final String path;
  final String message;
}
