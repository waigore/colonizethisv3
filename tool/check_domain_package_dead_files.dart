// Dead-file detection for the eight split logic-domain packages (Refs #3290).
//
// Mirrors the intent of `repo.logic_dead_files`
// (`tool/check_logic_dead_files.dart`) for the extracted domain packages, but
// resolves liveness across the whole workspace. After the split, a domain
// `lib/src` file is frequently consumed by a *different* package (for example
// `colonizethis_turn` re-exporting `package:colonizethis_world/src/...`, or the
// thin `colonizethis_logic` barrel re-exporting domain src), so intra-package
// reachability alone would mislabel public files as dead.
//
// Liveness model: every non-test `.dart` file under the scanned consumer roots
// (`packages/*/lib`, `app/lib`, `ctdev/lib`, `tool`) that lives OUTSIDE the
// eight domain `lib/src` trees is an anchor root. Reachability follows
// `import` / `export` / `part` directives (resolving workspace `package:`
// URIs and relative paths) transitively. A domain `lib/src` file is dead when
// no anchor root reaches it through that directive graph.
import 'dart:collection';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Split domain packages whose `lib/src` trees must stay free of orphans.
const List<String> domainPackageDeadFilesDomainsForTests = [
  'world',
  'combat',
  'economy',
  'diplomacy',
  'setup',
  'orders',
  'turn',
  'ai_contracts',
];

final RegExp _directivePattern = RegExp(
  "^\\s*(import|export|part)\\s+['\\\"]([^'\\\"]+)['\\\"]",
  multiLine: true,
);

void main() {
  exit(runCheckDomainPackageDeadFiles(Directory.current.path));
}

/// Runs the workspace-wide dead-file scan for every split domain package,
/// returning `0` when all domain `lib/src` files are reachable and `1` when a
/// domain `lib/src` tree is missing or contains an unreferenced file.
int runCheckDomainPackageDeadFiles(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final void Function(String line) logI = info ?? stdout.writeln;
  final void Function(String line) logE = err ?? stderr.writeln;

  final root = p.normalize(repoRoot);

  // Domain src directories (the trees we audit for orphans).
  final domainSrcDirs = <String, String>{};
  for (final domain in domainPackageDeadFilesDomainsForTests) {
    final srcRelative = p.join('packages', 'colonizethis_$domain', 'lib', 'src');
    final srcDir = Directory(p.join(root, srcRelative));
    if (!srcDir.existsSync()) {
      logE('ERROR: Missing domain src tree: $srcRelative');
      return 1;
    }
    domainSrcDirs['colonizethis_$domain'] = srcRelative;
  }

  // Collect every non-test consumer `.dart` file under the scan roots.
  final scanRoots = <String>[
    ...Directory(p.join(root, 'packages'))
        .listSync(followLinks: false)
        .whereType<Directory>()
        .map((dir) => p.join(dir.path, 'lib'))
        .where((libPath) => Directory(libPath).existsSync()),
    p.join(root, 'app', 'lib'),
    p.join(root, 'ctdev', 'lib'),
    p.join(root, 'tool'),
  ];

  final allFiles = <String>{};
  for (final scanRoot in scanRoots) {
    final dir = Directory(scanRoot);
    if (!dir.existsSync()) {
      continue;
    }
    for (final filePath in _listDartFiles(dir.path)) {
      if (_isUnderTestDir(filePath)) {
        continue;
      }
      allFiles.add(p.normalize(filePath));
    }
  }

  // Build the directive graph and identify domain src files.
  final edges = <String, Set<String>>{};
  final domainSrcFiles = <String>{};
  for (final domainSrc in domainSrcDirs.values) {
    final absDomainSrc = p.join(root, domainSrc);
    for (final filePath in _listDartFiles(absDomainSrc)) {
      final normalized = p.normalize(filePath);
      domainSrcFiles.add(normalized);
      allFiles.add(normalized);
    }
  }

  for (final filePath in allFiles) {
    final targets = <String>{};
    for (final directive in _parseDirectives(filePath)) {
      final targetPath = _resolveTargetPath(
        sourcePath: filePath,
        target: directive.target,
        repoRoot: root,
      );
      if (targetPath == null || !targetPath.endsWith('.dart')) {
        continue;
      }
      if (!allFiles.contains(targetPath) && !File(targetPath).existsSync()) {
        continue;
      }
      targets.add(targetPath);
    }
    if (targets.isNotEmpty) {
      edges[filePath] = targets;
    }
  }

  // Anchor roots: every consumer file outside the domain src trees.
  final roots = allFiles.difference(domainSrcFiles);
  final reachable = _collectReachable(roots, edges);

  final deadByPackage = <String, List<String>>{};
  for (final srcFile in domainSrcFiles) {
    if (reachable.contains(srcFile)) {
      continue;
    }
    final relative = _relativeToRoot(srcFile, root);
    final pkg = _owningPackage(relative);
    deadByPackage.putIfAbsent(pkg, () => <String>[]).add(relative);
  }

  if (deadByPackage.isEmpty) {
    logI('Domain-package dead-file check passed for all split packages.');
    return 0;
  }

  final packages = deadByPackage.keys.toList()..sort();
  for (final pkg in packages) {
    final files = deadByPackage[pkg]!..sort();
    logE(
      'ERROR: Found ${files.length} dead file(s) under packages/$pkg/lib/src.\n'
      'A file is dead when it is not reachable (via import/export/part '
      'directives) from any non-test consumer outside the eight domain '
      'lib/src trees.',
    );
    for (final file in files) {
      logE('  $file');
    }
  }
  return 1;
}

Set<String> _collectReachable(
  Set<String> roots,
  Map<String, Set<String>> edges,
) {
  final visited = <String>{};
  final queue = Queue<String>()..addAll(roots);
  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    if (!visited.add(current)) {
      continue;
    }
    final targets = edges[current];
    if (targets == null) {
      continue;
    }
    for (final target in targets) {
      if (!visited.contains(target)) {
        queue.add(target);
      }
    }
  }
  return visited;
}

bool _isUnderTestDir(String filePath) {
  final segments = p.split(filePath);
  return segments.contains('test') || segments.contains('integration_test');
}

String _owningPackage(String relativePath) {
  final segments = p.split(relativePath);
  // relativePath looks like packages/<pkg>/lib/src/...
  if (segments.length >= 2 && segments.first == 'packages') {
    return segments[1];
  }
  return relativePath;
}

List<String> _listDartFiles(String dirPath) {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) {
    return const [];
  }
  return dir
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .map((file) => p.normalize(file.path))
      .where((filePath) => filePath.endsWith('.dart'))
      .toList();
}

String _relativeToRoot(String filePath, String repoRoot) {
  return p.normalize(p.relative(filePath, from: repoRoot));
}

List<_Directive> _parseDirectives(String filePath) {
  final file = File(filePath);
  if (!file.existsSync()) {
    return const [];
  }
  final content = file.readAsStringSync();
  final directives = <_Directive>[];
  for (final match in _directivePattern.allMatches(content)) {
    final kindText = match.group(1);
    final target = match.group(2);
    if (kindText == null || target == null) {
      continue;
    }
    directives.add(_Directive(target: target));
  }
  return directives;
}

String? _resolveTargetPath({
  required String sourcePath,
  required String target,
  required String repoRoot,
}) {
  if (target.startsWith('dart:')) {
    return null;
  }
  if (target.startsWith('package:')) {
    const prefix = 'package:';
    final withoutScheme = target.substring(prefix.length);
    final slash = withoutScheme.indexOf('/');
    if (slash <= 0) {
      return null;
    }
    final packageName = withoutScheme.substring(0, slash);
    final packageRelative = withoutScheme.substring(slash + 1);
    final packageLib = Directory(
      p.join(repoRoot, 'packages', packageName, 'lib'),
    );
    if (!packageLib.existsSync()) {
      return null;
    }
    return p.normalize(p.join(packageLib.path, packageRelative));
  }

  final sourceDir = p.dirname(sourcePath);
  return p.normalize(p.join(sourceDir, target));
}

final class _Directive {
  const _Directive({required this.target});

  final String target;
}
