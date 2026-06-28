import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

/// PR-blocking gate for #3656: `app/test/**` files must not call the expensive
/// `getDebugInitGameResult()` debug map generator outside a documented
/// allowlist of suites that genuinely need generated map/topology data.
///
/// `getDebugInitGameResult()` runs the full procedural map generator
/// (`runInitGame(GameSetupConfig.defaultConfig)`, ~7-11s per call). Because
/// `flutter test` isolates each file, the cost is paid once per file. Panels
/// that only render from a `Game` should use the shared lightweight fixtures in
/// `app/test/support/panel_test_fixtures.dart` instead.
///
/// The allowlist below is the migration backlog: every `app/test/**` file that
/// still calls the helper. It must only ever **shrink** as families migrate to
/// lightweight or serialized fixtures; new entries require justification. The
/// check fails on a **stale** entry (file missing, or migrated so it no longer
/// invokes the helper) so the backlog cannot silently retain slack.
///
/// The backlog is now **empty**: every `app/test/**` suite has migrated to the
/// shared lightweight fixtures (`app/test/support/panel_test_fixtures.dart`) or
/// the committed seed-42 serialized fixtures (game / map-view topology /
/// per-region tile maps under `app/test/support/fixtures/`). No `app/test/**`
/// file may reintroduce `getDebugInitGameResult()`; add an entry here only with
/// a documented justification for data that cannot be serialized round-trip.
const Set<String> _kDebugInitAllowlist = <String>{};

/// Symbol whose invocation is gated.
const String _kDebugInitSymbol = 'getDebugInitGameResult';

/// Scans `app/test/**/*.dart` and fails when any non-allowlisted file invokes
/// [_kDebugInitSymbol]. Returns 0 on success, 1 on violations.
///
/// Also enforces that the allowlist only ever **shrinks**: an allowlist entry
/// whose file is missing or no longer invokes the helper (a migrated suite left
/// behind in the backlog) is reported as a **stale allowlist entry** so it must
/// be removed rather than silently retaining slack in the gate.
///
/// [allowlist] overrides the baked-in [_kDebugInitAllowlist] (used by tests).
int runCheckAppTestNoDebugInit(
  String repoRoot, {
  Set<String>? allowlist,
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final effectiveAllowlist = allowlist ?? _kDebugInitAllowlist;

  final appTestDir = Directory(p.join(repoRoot, 'app', 'test'));
  if (!appTestDir.existsSync()) {
    logI('check_app_test_no_debug_init: app/test not found; nothing to scan.');
    return 0;
  }

  final violations = <String>[];

  final files =
      appTestDir
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final relativePath = p
        .relative(file.path, from: repoRoot)
        .replaceAll('\\', '/');
    if (effectiveAllowlist.contains(relativePath)) {
      continue;
    }
    final content = file.readAsStringSync();
    if (!content.contains(_kDebugInitSymbol)) {
      continue;
    }
    violations.addAll(_invocationSites(content, relativePath));
  }

  final staleEntries = _staleAllowlistEntries(repoRoot, effectiveAllowlist);

  if (violations.isEmpty && staleEntries.isEmpty) {
    logI(
      'check_app_test_no_debug_init: no disallowed getDebugInitGameResult() '
      'usage found in app/test/**.',
    );
    return 0;
  }

  if (violations.isNotEmpty) {
    violations.sort();
    logE(
      'check_app_test_no_debug_init: found ${violations.length} disallowed '
      'getDebugInitGameResult() call site(s):',
    );
    for (final v in violations) {
      logE(' - $v');
    }
    logE(
      'Use the shared lightweight fixtures in '
      'app/test/support/panel_test_fixtures.dart, a committed serialized '
      'fixture, or add the file to the documented allowlist only when it '
      'genuinely needs generated map/topology data (Refs #3656).',
    );
  }

  if (staleEntries.isNotEmpty) {
    staleEntries.sort();
    logE(
      'check_app_test_no_debug_init: found ${staleEntries.length} stale '
      'allowlist entr${staleEntries.length == 1 ? 'y' : 'ies'} (the allowlist '
      'must only ever shrink):',
    );
    for (final e in staleEntries) {
      logE(' - $e');
    }
    logE(
      'Remove these entries from the allowlist: the file is missing or no '
      'longer invokes getDebugInitGameResult() (Refs #3656).',
    );
  }

  return 1;
}

/// Parses [content] and returns the formatted `path:line` invocation sites of
/// [_kDebugInitSymbol] (empty when the symbol only appears in comments/strings).
List<String> _invocationSites(String content, String relativePath) {
  final parsed = parseString(content: content, path: relativePath);
  final visitor = _DebugInitInvocationVisitor(
    relativePath: relativePath,
    lineInfo: parsed.unit.lineInfo,
  );
  parsed.unit.accept(visitor);
  return visitor.sites;
}

/// Returns allowlist entries that no longer justify their slot: the file is
/// missing, or it no longer invokes [_kDebugInitSymbol] (AST match, so a
/// comment-only mention does not keep an entry alive).
List<String> _staleAllowlistEntries(String repoRoot, Set<String> allowlist) {
  final stale = <String>[];
  for (final entry in allowlist) {
    final file = File(p.join(repoRoot, entry));
    if (!file.existsSync()) {
      stale.add('$entry: allowlisted file does not exist.');
      continue;
    }
    final content = file.readAsStringSync();
    final invokes =
        content.contains(_kDebugInitSymbol) &&
        _invocationSites(content, entry).isNotEmpty;
    if (!invokes) {
      stale.add(
        '$entry: allowlisted file no longer invokes $_kDebugInitSymbol().',
      );
    }
  }
  return stale;
}

class _DebugInitInvocationVisitor extends RecursiveAstVisitor<void> {
  _DebugInitInvocationVisitor({
    required this.relativePath,
    required this.lineInfo,
  });

  final String relativePath;
  final LineInfo lineInfo;
  final List<String> sites = <String>[];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == _kDebugInitSymbol) {
      final line = lineInfo.getLocation(node.offset).lineNumber;
      sites.add(
        '$relativePath:$line: calls $_kDebugInitSymbol() outside the '
        'documented allowlist.',
      );
    }
    super.visitMethodInvocation(node);
  }
}

void main() {
  exit(runCheckAppTestNoDebugInit(Directory.current.path));
}
