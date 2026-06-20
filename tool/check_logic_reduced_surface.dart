// Guards the thin colonizethis_logic core surface after the domain-package
// split (Refs #3290 Phase 4). The epic AC requires colonizethis_logic to be
// reduced to a thin re-export core of <=15 source files (core + contract APIs
// + re-export barrel). This gate fails if the package's lib/ Dart surface grows
// back beyond that ceiling, preventing domain code from creeping back into the
// monolith.
import 'dart:io';

import 'package:path/path.dart' as p;

const _logicLibRelative = 'packages/colonizethis_logic/lib';
const _maxSourceFiles = 15;

bool _isGenerated(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.endsWith('.mocks.dart');

void main() {
  exit(runCheckLogicReducedSurface(Directory.current.path));
}

int runCheckLogicReducedSurface(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final libDir = Directory(p.join(repoRoot, _logicLibRelative));
  if (!libDir.existsSync()) {
    logE('check_logic_reduced_surface: missing $_logicLibRelative');
    return 1;
  }

  final sourceFiles = <String>[];
  for (final entity in libDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (_isGenerated(entity.path)) continue;
    sourceFiles.add(p.relative(entity.path, from: repoRoot));
  }
  sourceFiles.sort();

  if (sourceFiles.length <= _maxSourceFiles) {
    logI(
      'check_logic_reduced_surface: ${sourceFiles.length} source file(s) '
      '<= $_maxSourceFiles (thin core preserved).',
    );
    return 0;
  }

  logE(
    'check_logic_reduced_surface: colonizethis_logic must stay a thin '
    're-export core of <= $_maxSourceFiles source files, found '
    '${sourceFiles.length}:',
  );
  for (final path in sourceFiles) {
    logE(' - $path');
  }
  return 1;
}

int maxLogicReducedSurfaceFilesForTests() => _maxSourceFiles;
