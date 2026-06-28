// Physical line limit for colonizethis_logic lib/src (Refs #3290 Phase 0).
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const _logicSrcRelative = 'packages/colonizethis_logic/lib/src';
const _baselineRelative = 'tool/logic_source_file_size_baseline.json';
const _maxPhysicalLines = 500;

void main() {
  exit(runCheckLogicSourceFileSize(Directory.current.path));
}

int runCheckLogicSourceFileSize(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final srcDir = Directory(p.join(repoRoot, _logicSrcRelative));
  if (!srcDir.existsSync()) {
    logE('check_logic_source_file_size: missing $_logicSrcRelative');
    return 1;
  }

  final baseline = _loadBaseline(p.join(repoRoot, _baselineRelative));
  final violations = <String>[];

  for (final entity in srcDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final relative =
        'packages/colonizethis_logic/lib/src/${p.relative(entity.path, from: srcDir.path)}';
    if (baseline.contains(relative)) continue;

    final physicalLines = const LineSplitter()
        .convert(entity.readAsStringSync())
        .length;
    if (physicalLines > _maxPhysicalLines) {
      violations.add(
        '$relative ($physicalLines physical lines > $_maxPhysicalLines)',
      );
    }
  }

  if (violations.isEmpty) {
    logI('check_logic_source_file_size: no violations outside baseline.');
    return 0;
  }

  logE(
    'check_logic_source_file_size: found ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

Set<String> _loadBaseline(String baselinePath) {
  final file = File(baselinePath);
  if (!file.existsSync()) return <String>{};
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! List) return <String>{};
  return decoded.map((e) => e.toString()).toSet();
}

int maxLogicSourcePhysicalLinesForTests() => _maxPhysicalLines;
