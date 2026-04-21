import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'ct_repo_lint_scan_contract.dart';

const _logicScopePrefix = 'packages/colonizethis_logic/lib/src/';
int runCheckPartUnitSize(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final allowlist = _loadAllowlist(repoRoot);
  final filesByRelativePath = <String, File>{};
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot);
    if (!rel.startsWith(_logicScopePrefix)) {
      continue;
    }
    filesByRelativePath[rel] = file;
  }

  final violations = <String>[];
  for (final entry in filesByRelativePath.entries) {
    final relPath = entry.key;
    final content = entry.value.readAsStringSync();
    final lineCount = _countPhysicalLines(content);
    final allowedPartMax = allowlist.partFileMaxLinesByPath[relPath];
    if (allowedPartMax != null && lineCount > allowedPartMax) {
      violations.add(
        '$relPath: part file has $lineCount lines '
        '(allowlisted max=$allowedPartMax)',
      );
    }

    final allowedParentMax = allowlist.parentUnitMaxLinesByPath[relPath];
    if (allowedParentMax == null) {
      continue;
    }
    final partTargets = _extractPartTargets(content);
    var total = lineCount;
    for (final target in partTargets) {
      final targetPath = p.normalize(p.join(p.dirname(relPath), target));
      final partFile = filesByRelativePath[targetPath];
      if (partFile == null) {
        if (_isGeneratedDartPath(targetPath)) {
          continue;
        }
        violations.add(
          '$relPath: missing part target "$targetPath" declared via part "$target"',
        );
        continue;
      }
      total += _countPhysicalLines(partFile.readAsStringSync());
    }
    if (total > allowedParentMax) {
      violations.add(
        '$relPath: parent + parts compilation unit has $total lines '
        '(allowlisted max=$allowedParentMax)',
      );
    }
  }

  if (violations.isEmpty) {
    logI('check_part_unit_size: no part-unit size violations.');
    return 0;
  }
  logE('check_part_unit_size: ${violations.length} violation(s):');
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

int _countPhysicalLines(String content) => content.split('\n').length;

bool _isGeneratedDartPath(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.endsWith('.mocks.dart');

List<String> _extractPartTargets(String content) {
  final matches = RegExp(
    r'''^\s*part\s+['"]([^'"]+)['"]\s*;''',
    multiLine: true,
  ).allMatches(content);
  return matches.map((m) => m.group(1)!).toList();
}

_PartUnitSizeAllowlist _loadAllowlist(String repoRoot) {
  final file = File(p.join(repoRoot, 'tool', 'part_unit_size_allowlist.yaml'));
  if (!file.existsSync()) {
    return const _PartUnitSizeAllowlist(
      parentUnitMaxLinesByPath: {},
      partFileMaxLinesByPath: {},
    );
  }
  final dynamic doc = loadYaml(file.readAsStringSync());
  if (doc is! YamlMap) {
    return const _PartUnitSizeAllowlist(
      parentUnitMaxLinesByPath: {},
      partFileMaxLinesByPath: {},
    );
  }
  final parentUnitMaxLinesByPath = _parseAllowlistRows(
    doc['allowed_parent_units'],
  );
  final partFileMaxLinesByPath = _parseAllowlistRows(doc['allowed_part_files']);
  return _PartUnitSizeAllowlist(
    parentUnitMaxLinesByPath: parentUnitMaxLinesByPath,
    partFileMaxLinesByPath: partFileMaxLinesByPath,
  );
}

Map<String, int> _parseAllowlistRows(Object? node) {
  if (node is! YamlList) {
    return const {};
  }
  final out = <String, int>{};
  for (final entry in node) {
    if (entry is! YamlMap) {
      continue;
    }
    final file = entry['file']?.toString();
    final maxLines = entry['max_lines'];
    if (file == null || maxLines is! int) {
      continue;
    }
    out[file] = maxLines;
  }
  return out;
}

final class _PartUnitSizeAllowlist {
  const _PartUnitSizeAllowlist({
    required this.parentUnitMaxLinesByPath,
    required this.partFileMaxLinesByPath,
  });

  final Map<String, int> parentUnitMaxLinesByPath;
  final Map<String, int> partFileMaxLinesByPath;
}

void main() {
  exit(runCheckPartUnitSize(Directory.current.path));
}
