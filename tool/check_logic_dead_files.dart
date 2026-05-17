import 'dart:collection';
import 'dart:io';

import 'package:path/path.dart' as p;

const _logicPackageRelative = 'packages/colonizethis_logic';
const _logicLibRelative = 'packages/colonizethis_logic/lib';
const _logicSrcRelative = 'packages/colonizethis_logic/lib/src';
const _knownDeferredDeadFiles = <String>{
  'packages/colonizethis_logic/lib/src/ai/ai_planner.dart',
  'packages/colonizethis_logic/lib/src/ai/sim_game_ai.dart',
};

final RegExp _directivePattern = RegExp(
  "^\\s*(import|export|part|part\\s+of)\\s+['\\\"]([^'\\\"]+)['\\\"]",
  multiLine: true,
);

void main() {
  exit(runCheckLogicDeadFiles(Directory.current.path));
}

int runCheckLogicDeadFiles(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final root = p.normalize(repoRoot);
  final logicPackageDir = Directory(p.join(root, _logicPackageRelative));
  final libDir = Directory(p.join(root, _logicLibRelative));
  final srcDir = Directory(p.join(root, _logicSrcRelative));

  if (!logicPackageDir.existsSync()) {
    logE('ERROR: Missing package directory: $_logicPackageRelative');
    return 1;
  }
  if (!libDir.existsSync()) {
    logE('ERROR: Missing logic lib directory: $_logicLibRelative');
    return 1;
  }
  if (!srcDir.existsSync()) {
    logE('ERROR: Missing logic src directory: $_logicSrcRelative');
    return 1;
  }

  final libFiles = _listDartFiles(libDir.path);
  final srcFiles = _listDartFiles(srcDir.path).toSet();
  final exportedEdges = <String, Set<String>>{};
  final importedSrcFiles = <String>{};
  final partOfFiles = <String>{};

  for (final filePath in libFiles) {
    final directives = _parseDirectives(filePath);
    final sourceRelative = _relativeToRoot(filePath, root);
    for (final directive in directives) {
      if (directive.kind == _DirectiveKind.partOf) {
        partOfFiles.add(sourceRelative);
        continue;
      }

      final targetPath = _resolveTargetPath(
        sourcePath: filePath,
        target: directive.target,
        repoRoot: root,
      );
      if (targetPath == null) {
        continue;
      }
      if (!targetPath.endsWith('.dart') || !File(targetPath).existsSync()) {
        continue;
      }

      final targetRelative = _relativeToRoot(targetPath, root);
      if (directive.kind == _DirectiveKind.import &&
          srcFiles.contains(targetPath)) {
        importedSrcFiles.add(targetRelative);
      }
      if (directive.kind == _DirectiveKind.export) {
        exportedEdges
            .putIfAbsent(sourceRelative, () => <String>{})
            .add(targetRelative);
      }
    }
  }

  final barrelRoots = _listDartFiles(libDir.path)
      .where((filePath) => p.dirname(filePath) == libDir.path)
      .map((filePath) => _relativeToRoot(filePath, root))
      .toSet();
  final exportReachabilityRoots = <String>{...barrelRoots, ...importedSrcFiles};
  final exportReachable = _collectReachableExports(
    exportReachabilityRoots,
    exportedEdges,
  );

  final deadFiles = <String>[];
  for (final srcPath in srcFiles) {
    final relative = _relativeToRoot(srcPath, root);
    if (partOfFiles.contains(relative)) {
      continue;
    }
    final isImportedByLib = importedSrcFiles.contains(relative);
    final isReachableByBarrelExport = exportReachable.contains(relative);
    if (!isImportedByLib && !isReachableByBarrelExport) {
      deadFiles.add(relative);
    }
  }

  deadFiles.sort();
  final actionableDeadFiles =
      deadFiles
          .where((file) => !_knownDeferredDeadFiles.contains(file))
          .toList()
        ..sort();

  if (actionableDeadFiles.isEmpty) {
    if (deadFiles.isNotEmpty) {
      logI(
        'Logic dead-file check found only deferred exceptions: '
        '${deadFiles.join(', ')}',
      );
    }
    logI(
      'Logic dead-file check passed: no unreferenced files under '
      '$_logicSrcRelative.',
    );
    return 0;
  }

  logE(
    'ERROR: Found ${actionableDeadFiles.length} dead files under '
    '$_logicSrcRelative.\n'
    'A file is dead when it is not a `part of` file, not imported by any '
    'file under `packages/colonizethis_logic/lib/**`, and not reachable from '
    'barrel exports rooted at `packages/colonizethis_logic/lib/*.dart`.',
  );
  for (final file in actionableDeadFiles) {
    logE(file);
  }
  return 1;
}

Set<String> _collectReachableExports(
  Set<String> roots,
  Map<String, Set<String>> exportedEdges,
) {
  final visited = <String>{};
  final queue = Queue<String>()..addAll(roots);

  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    if (!visited.add(current)) {
      continue;
    }
    final exports = exportedEdges[current];
    if (exports == null) {
      continue;
    }
    for (final target in exports) {
      queue.add(target);
    }
  }
  return visited;
}

List<String> _listDartFiles(String dirPath) {
  final dir = Directory(dirPath);
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
  final content = File(filePath).readAsStringSync();
  final directives = <_Directive>[];
  for (final match in _directivePattern.allMatches(content)) {
    final kindText = match.group(1);
    final target = match.group(2);
    if (kindText == null || target == null) {
      continue;
    }
    final kind = switch (kindText) {
      'import' => _DirectiveKind.import,
      'export' => _DirectiveKind.export,
      'part' => _DirectiveKind.part,
      'part of' => _DirectiveKind.partOf,
      _ => null,
    };
    if (kind == null) {
      continue;
    }
    directives.add(_Directive(kind: kind, target: target));
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
    const packagePrefix = 'package:colonizethis_logic/';
    if (!target.startsWith(packagePrefix)) {
      return null;
    }
    final packageRelative = target.substring(packagePrefix.length);
    return p.normalize(
      p.join(repoRoot, _logicPackageRelative, 'lib', packageRelative),
    );
  }

  final sourceDir = p.dirname(sourcePath);
  return p.normalize(p.join(sourceDir, target));
}

enum _DirectiveKind { import, export, part, partOf }

final class _Directive {
  const _Directive({required this.kind, required this.target});

  final _DirectiveKind kind;
  final String target;
}
