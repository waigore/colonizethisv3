// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

const _appLibPrefix = 'app/lib/';
const _appTestPrefix = 'app/test/';

// Irreducible fallback set: see SPEC/program/ci-app-selective-tests.md.
// Any change to these emits `selective` with the full sorted app-test list.
const _irreducibleFallbackExact = <String>{
  'pubspec.yaml',
  'analysis_options.yaml',
  'tool/compute_app_test_plan.dart',
  '.github/workflows/quality.yml',
};

/// Result of [computeAppTestPlan].
class AppTestPlan {
  const AppTestPlan({required this.mode, required this.tests});

  final String mode;
  final List<String> tests;

  Map<String, Object> toJson() => {
        'mode': mode,
        'tests': tests,
      };
}

class _WorkspaceLayout {
  _WorkspaceLayout({required this.packageRoots, required this.walkRoots});

  /// `packageName -> packageRoot` (relative to repo root, forward slashes).
  /// Spans every workspace member with a parseable `name:` (so all
  /// `package:<name>/...` URIs imported by walked code can be resolved).
  final Map<String, String> packageRoots;

  /// Subset of [packageRoots] values whose `lib/` is walked into the import
  /// graph. Per SPEC D2, this is `packages/<name>` only — tool packages and
  /// shells (`app`, `widgetbook_host`, `ctdev`) outside `packages/` are not
  /// walked. `app/lib` and `app/test` are walked separately.
  final Set<String> walkRoots;
}

/// Computes which app tests CI should run for [changedFiles] under [repoRoot].
///
/// The selector is a pure function of [changedFiles] and on-disk workspace
/// state. It does not read environment variables, PR labels, or workflow
/// context (SPEC D1). Output schema is `selective | skip`; the legacy
/// `full` mode is never emitted — fallback cases produce `selective` with
/// the full sorted list of `app/test/**/*_test.dart`.
AppTestPlan computeAppTestPlan({
  required String repoRoot,
  required Iterable<String> changedFiles,
}) {
  final normalized = changedFiles
      .map(_normalizePath)
      .where((path) => path.isNotEmpty)
      .toSet();

  if (normalized.isEmpty) {
    return const AppTestPlan(mode: 'skip', tests: []);
  }

  final appLibDir = p.join(repoRoot, 'app', 'lib');
  final appTestDir = p.join(repoRoot, 'app', 'test');
  if (!Directory(appLibDir).existsSync() ||
      !Directory(appTestDir).existsSync()) {
    return const AppTestPlan(mode: 'skip', tests: []);
  }

  final layout = _readWorkspaceLayout(repoRoot);
  final graph = _buildImportGraph(repoRoot, layout);
  final testClosures = _buildTestClosures(graph);
  final allTests = testClosures.keys.toList()..sort();

  AppTestPlan fullFallback() => AppTestPlan(mode: 'selective', tests: allTests);

  if (_triggersIrreducibleFallback(normalized)) {
    return fullFallback();
  }

  final changedTests = <String>{};
  final seedFiles = <String>{};
  var relevantDartChange = false;

  for (final path in normalized) {
    if (_isAppTestFile(path)) {
      changedTests.add(path);
      relevantDartChange = true;
      continue;
    }
    if (_isAppLibFile(path)) {
      seedFiles.add(path);
      relevantDartChange = true;
      continue;
    }
    if (_isAppTestHelper(path)) {
      seedFiles.add(path);
      relevantDartChange = true;
      continue;
    }
    if (_isWalkedPackageLibDart(path, layout)) {
      seedFiles.add(path);
      relevantDartChange = true;
      continue;
    }
    if (path.startsWith('app/')) {
      // Non-Dart asset/config under app/: irreducible fallback.
      return fullFallback();
    }
    // Other paths (tool/**, ctdev/**, packages/<name>/test/**,
    // packages/<name>/pubspec.yaml, SPEC/**, .cursor/**, etc.) are not seeds
    // and do not select tests.
  }

  if (!relevantDartChange) {
    return const AppTestPlan(mode: 'skip', tests: []);
  }

  final selected = <String>{...changedTests};
  for (final testPath in allTests) {
    final closure = testClosures[testPath] ?? const <String>{};
    if (closure.intersection(seedFiles).isNotEmpty) {
      selected.add(testPath);
    }
  }

  final tests = selected.toList()..sort();
  if (tests.isEmpty) {
    // A relevant Dart change touched no test closure (e.g. an unreachable
    // lib file). Be conservative: emit the full fallback rather than an
    // empty selective.
    return fullFallback();
  }
  return AppTestPlan(mode: 'selective', tests: tests);
}

bool _triggersIrreducibleFallback(Set<String> changedFiles) {
  for (final path in changedFiles) {
    if (_irreducibleFallbackExact.contains(path)) return true;
  }
  return false;
}

bool _isAppLibFile(String path) =>
    path.startsWith(_appLibPrefix) && path.endsWith('.dart');

bool _isAppTestDart(String path) =>
    path.startsWith(_appTestPrefix) && path.endsWith('.dart');

bool _isAppTestFile(String path) =>
    _isAppTestDart(path) && path.endsWith('_test.dart');

bool _isAppTestHelper(String path) =>
    _isAppTestDart(path) && !path.endsWith('_test.dart');

bool _isWalkedPackageLibDart(String path, _WorkspaceLayout layout) {
  if (!path.endsWith('.dart')) return false;
  for (final root in layout.walkRoots) {
    if (path.startsWith('$root/lib/')) return true;
  }
  return false;
}

String _normalizePath(String path) =>
    p.normalize(path.replaceAll(r'\', '/')).replaceFirst(RegExp(r'^./'), '');

Set<String> _listDartFiles(String rootDir, String repoRoot) {
  final dir = Directory(rootDir);
  if (!dir.existsSync()) return {};
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .map((file) => p
          .normalize(p.relative(file.path, from: repoRoot))
          .replaceAll(r'\', '/'))
      .toSet();
}

_WorkspaceLayout _readWorkspaceLayout(String repoRoot) {
  final packageRoots = <String, String>{};
  final walkRoots = <String>{};

  final rootPubspec = File(p.join(repoRoot, 'pubspec.yaml'));
  if (!rootPubspec.existsSync()) {
    return _WorkspaceLayout(packageRoots: packageRoots, walkRoots: walkRoots);
  }
  final yaml = loadYaml(rootPubspec.readAsStringSync());
  if (yaml is! YamlMap) {
    return _WorkspaceLayout(packageRoots: packageRoots, walkRoots: walkRoots);
  }
  final workspace = yaml['workspace'];
  if (workspace is! YamlList) {
    return _WorkspaceLayout(packageRoots: packageRoots, walkRoots: walkRoots);
  }

  for (final entry in workspace) {
    if (entry is! String) continue;
    final memberRoot = entry.replaceAll(r'\', '/');
    final memberPubspec = File(p.join(repoRoot, memberRoot, 'pubspec.yaml'));
    if (!memberPubspec.existsSync()) continue;
    final memberYaml = loadYaml(memberPubspec.readAsStringSync());
    if (memberYaml is! YamlMap) continue;
    final name = memberYaml['name'];
    if (name is! String) continue;
    packageRoots[name] = memberRoot;
    if (memberRoot.startsWith('packages/')) {
      walkRoots.add(memberRoot);
    }
  }

  return _WorkspaceLayout(packageRoots: packageRoots, walkRoots: walkRoots);
}

Map<String, Set<String>> _buildImportGraph(
  String repoRoot,
  _WorkspaceLayout layout,
) {
  final libRoot = p.join(repoRoot, 'app', 'lib');
  final testRoot = p.join(repoRoot, 'app', 'test');
  final nodes = <String>{
    ..._listDartFiles(libRoot, repoRoot),
    ..._listDartFiles(testRoot, repoRoot),
  };
  for (final root in layout.walkRoots) {
    final libDir = p.join(repoRoot, root, 'lib');
    nodes.addAll(_listDartFiles(libDir, repoRoot));
  }

  final graph = <String, Set<String>>{for (final node in nodes) node: {}};
  for (final relPath in nodes) {
    final filePath = p.join(repoRoot, relPath);
    final content = File(filePath).readAsStringSync();
    for (final uri in _parseImportUris(content)) {
      final resolved = _resolveImport(
        importingRelPath: relPath,
        importUri: uri,
        nodes: nodes,
        layout: layout,
      );
      if (resolved != null) {
        graph[relPath]!.add(resolved);
      }
    }
  }
  return graph;
}

Iterable<String> _parseImportUris(String content) sync* {
  final importRe = RegExp(
    r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
    multiLine: true,
  );
  for (final match in importRe.allMatches(content)) {
    yield match.group(1)!;
  }
}

String? _resolveImport({
  required String importingRelPath,
  required String importUri,
  required Set<String> nodes,
  required _WorkspaceLayout layout,
}) {
  if (importUri.startsWith('dart:')) return null;

  String candidate;
  if (importUri.startsWith('package:')) {
    final rest = importUri.substring('package:'.length);
    final slash = rest.indexOf('/');
    if (slash <= 0) return null;
    final packageName = rest.substring(0, slash);
    final relPath = rest.substring(slash + 1);
    final packageRoot = layout.packageRoots[packageName];
    if (packageRoot == null) return null;
    candidate = p.normalize(p.join(packageRoot, 'lib', relPath));
  } else {
    candidate = p.normalize(p.join(p.dirname(importingRelPath), importUri));
  }

  candidate = candidate.replaceAll(r'\', '/');
  if (!candidate.endsWith('.dart')) {
    candidate = '$candidate.dart';
  }
  return nodes.contains(candidate) ? candidate : null;
}

Map<String, Set<String>> _buildTestClosures(Map<String, Set<String>> graph) {
  final memo = <String, Set<String>>{};
  final testFiles = graph.keys
      .where((path) => path.startsWith('app/test/'))
      .where((path) => path.endsWith('_test.dart'))
      .toList()
    ..sort();

  Set<String> closureFor(String start) {
    final cached = memo[start];
    if (cached != null) return cached;

    final visited = <String>{};
    final queue = <String>[start];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      if (!visited.add(current)) continue;
      for (final dep in graph[current] ?? const {}) {
        queue.add(dep);
      }
    }
    memo[start] = visited;
    return visited;
  }

  return {for (final test in testFiles) test: closureFor(test)};
}

Iterable<String> _parseChangedFilesArg(String raw) sync* {
  for (final part in raw.split(RegExp(r'[\n,]'))) {
    final trimmed = part.trim();
    if (trimmed.isNotEmpty) yield trimmed;
  }
}

String _findRepoRoot() {
  var dir = Directory.current;
  while (true) {
    final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      final text = pubspec.readAsStringSync();
      if (text.contains('name: colonizethis') && text.contains('workspace:')) {
        return p.normalize(dir.path);
      }
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return p.normalize(Directory.current.path);
    }
    dir = parent;
  }
}

void main(List<String> args) {
  String? changedRaw;
  for (final arg in args) {
    if (arg.startsWith('--changed-files=')) {
      changedRaw = arg.substring('--changed-files='.length);
    }
  }

  final repoRoot = _findRepoRoot();
  final changedFiles =
      changedRaw == null ? <String>[] : _parseChangedFilesArg(changedRaw);
  final plan =
      computeAppTestPlan(repoRoot: repoRoot, changedFiles: changedFiles);
  stdout.writeln(jsonEncode(plan.toJson()));
}
