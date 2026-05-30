// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const _packageName = 'colonizethis_app';
const _appLibPrefix = 'app/lib/';
const _appTestPrefix = 'app/test/';

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

/// Computes which app tests CI should run for [changedFiles] under [repoRoot].
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

  if (_forcesFullRun(normalized)) {
    return const AppTestPlan(mode: 'full', tests: []);
  }

  final appLibDir = p.join(repoRoot, 'app', 'lib');
  final appTestDir = p.join(repoRoot, 'app', 'test');
  if (!Directory(appLibDir).existsSync() || !Directory(appTestDir).existsSync()) {
    return const AppTestPlan(mode: 'skip', tests: []);
  }

  final graph = _buildImportGraph(repoRoot);
  final testClosures = _buildTestClosures(graph);
  final allTests = testClosures.keys.toList()..sort();

  final changedTests = <String>{};
  final seedFiles = <String>{};
  var hasAppDartChange = false;

  for (final path in normalized) {
    if (_isAppTestFile(path)) {
      changedTests.add(path);
      hasAppDartChange = true;
      continue;
    }
    if (_isAppLibFile(path)) {
      seedFiles.add(path);
      hasAppDartChange = true;
      continue;
    }
    if (_isAppTestHelper(path)) {
      seedFiles.add(path);
      hasAppDartChange = true;
      continue;
    }
    if (path.startsWith('app/')) {
      return const AppTestPlan(mode: 'full', tests: []);
    }
  }

  if (!hasAppDartChange) {
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
    return const AppTestPlan(mode: 'full', tests: []);
  }
  return AppTestPlan(mode: 'selective', tests: tests);
}

bool _forcesFullRun(Set<String> changedFiles) {
  const forceFullPrefixes = <String>[
    'packages/',
  ];
  const forceFullExact = <String>{
    'pubspec.yaml',
    'analysis_options.yaml',
    'tool/compute_app_test_plan.dart',
    '.github/workflows/quality.yml',
  };

  for (final path in changedFiles) {
    if (forceFullExact.contains(path)) {
      return true;
    }
    for (final prefix in forceFullPrefixes) {
      if (path.startsWith(prefix)) {
        return true;
      }
    }
    if (path.startsWith('app/') &&
        !_isAppLibFile(path) &&
        !_isAppTestDart(path)) {
      return true;
    }
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

String _normalizePath(String path) =>
    p.normalize(path.replaceAll(r'\', '/')).replaceFirst(RegExp(r'^./'), '');

Set<String> _listDartFiles(String rootDir, String repoRoot) {
  final dir = Directory(rootDir);
  if (!dir.existsSync()) {
    return {};
  }
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .map((file) => p.normalize(p.relative(file.path, from: repoRoot)))
      .toSet();
}

Map<String, Set<String>> _buildImportGraph(String repoRoot) {
  final libRoot = p.join(repoRoot, 'app', 'lib');
  final testRoot = p.join(repoRoot, 'app', 'test');
  final nodes = <String>{
    ..._listDartFiles(libRoot, repoRoot),
    ..._listDartFiles(testRoot, repoRoot),
  };

  final graph = <String, Set<String>>{for (final node in nodes) node: {}};
  for (final relPath in nodes) {
    final filePath = p.join(repoRoot, relPath);
    final content = File(filePath).readAsStringSync();
    for (final uri in _parseImportUris(content)) {
      final resolved = _resolveImport(
        importingRelPath: relPath,
        importUri: uri,
        nodes: nodes,
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
}) {
  if (importUri.startsWith('dart:')) {
    return null;
  }

  String? candidate;
  final packagePrefix = 'package:$_packageName/';
  if (importUri.startsWith(packagePrefix)) {
    final rel = importUri.substring(packagePrefix.length);
    candidate = p.normalize(p.join('app', 'lib', rel));
  } else if (importUri.startsWith('package:')) {
    return null;
  } else {
    candidate = p.normalize(
      p.join(p.dirname(importingRelPath), importUri),
    );
  }

  if (!candidate.endsWith('.dart')) {
    candidate = '$candidate.dart';
  }

  if (nodes.contains(candidate)) {
    return candidate;
  }
  return null;
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
    if (cached != null) {
      return cached;
    }

    final visited = <String>{};
    final queue = <String>[start];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      if (!visited.add(current)) {
        continue;
      }
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
    if (trimmed.isNotEmpty) {
      yield trimmed;
    }
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
  final changedFiles = changedRaw == null ? <String>[] : _parseChangedFilesArg(changedRaw);
  final plan = computeAppTestPlan(repoRoot: repoRoot, changedFiles: changedFiles);
  stdout.writeln(jsonEncode(plan.toJson()));
}
