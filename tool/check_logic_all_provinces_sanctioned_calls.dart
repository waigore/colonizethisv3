import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Canonical dual-region province iteration; definitions live here only.
const _canonicalProvinceLookupRelativePath =
    'packages/colonizethis_world/lib/src/world/province_lookup.dart';

/// Production source trees scanned for broad `allProvinces(` call sites.
///
/// Includes the `colonizethis_orders` mid-layer package and the
/// `colonizethis_turn` orchestrator package: the sources that legitimately walk
/// all provinces (order suggestions, turn news digest) were extracted there from
/// the `colonizethis_logic` monolith (Refs #3290) and stay sanctioned via the
/// same allowlist.
const _scanDirsRelative = <String>[
  'packages/colonizethis_logic/lib/src',
  'packages/colonizethis_orders/lib/src',
  'packages/colonizethis_turn/lib/src',
];
const _sanctionsYamlRelative = 'tool/logic_all_provinces_sanctions.yaml';

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');

/// True when [line] contains a broad `allProvinces(` invocation (top-level helper
/// or [WorldState.allProvinces] extension call).
bool logicSourceLineContainsAllProvincesCall(String line) {
  return line.contains('allProvinces(');
}

typedef _SanctionKey = ({String path, int line});

({Set<_SanctionKey> keys, bool ok}) _loadSanctionKeys(
  String repoRoot,
  void Function(String) logE,
) {
  final yamlFile = File(p.join(repoRoot, _sanctionsYamlRelative));
  if (!yamlFile.existsSync()) {
    logE('ERROR: Missing sanctions file: $_sanctionsYamlRelative');
    return (keys: const {}, ok: false);
  }
  final dynamic root = loadYaml(yamlFile.readAsStringSync());
  if (root is! YamlMap) {
    logE('ERROR: $_sanctionsYamlRelative: expected top-level map');
    return (keys: const {}, ok: false);
  }
  final list = root['sanctions'];
  if (list is! YamlList) {
    logE('ERROR: $_sanctionsYamlRelative: missing sanctions: list');
    return (keys: const {}, ok: false);
  }
  final out = <_SanctionKey>{};
  final seenKeys = <String>{};
  var ok = true;
  for (var i = 0; i < list.length; i++) {
    final entry = list[i];
    if (entry is! YamlMap) {
      logE('ERROR: $_sanctionsYamlRelative: sanctions[$i] must be a map');
      ok = false;
      continue;
    }
    final pathRaw = entry['path']?.toString();
    final lineRaw = entry['line'];
    if (pathRaw == null || pathRaw.isEmpty) {
      logE('ERROR: $_sanctionsYamlRelative: sanctions[$i] missing path');
      ok = false;
      continue;
    }
    final normalizedPath = p.normalize(pathRaw.replaceAll('\\', '/'));
    final lineNum = lineRaw is int
        ? lineRaw
        : (lineRaw is String ? int.tryParse(lineRaw) : null);
    if (lineNum == null || lineNum < 1) {
      logE(
        'ERROR: $_sanctionsYamlRelative: sanctions[$i] invalid line for '
        '$normalizedPath',
      );
      ok = false;
      continue;
    }
    final keyStr = '$normalizedPath:$lineNum';
    if (!seenKeys.add(keyStr)) {
      logE('ERROR: $_sanctionsYamlRelative: duplicate sanction $keyStr');
      ok = false;
      continue;
    }
    out.add((path: normalizedPath, line: lineNum));
  }
  return (keys: out, ok: ok);
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckLogicAllProvincesSanctionedCalls(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  void logE(String line) {
    final sink = err;
    if (sink != null) {
      sink(line);
    } else {
      stderr.writeln(line);
    }
  }

  final root = p.normalize(repoRoot);
  final scanRoots = <Directory>[];
  for (final relative in _scanDirsRelative) {
    final dir = Directory(p.join(root, relative));
    if (!dir.existsSync()) {
      logE('ERROR: Expected lib tree missing: $relative');
      return 1;
    }
    scanRoots.add(dir);
  }

  final loaded = _loadSanctionKeys(root, logE);
  if (!loaded.ok) {
    return 1;
  }
  final sanctioned = loaded.keys;

  final hits = <_SanctionKey>{};
  for (final scanRoot in scanRoots) {
    for (final entity in scanRoot.listSync(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      final fullPath = p.normalize(entity.path);
      if (!fullPath.endsWith('.dart')) continue;
      if (_generatedSuffix.hasMatch(fullPath)) continue;
      final relative = p.normalize(p.relative(fullPath, from: root));
      if (relative == _canonicalProvinceLookupRelativePath) {
        continue;
      }

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (logicSourceLineContainsAllProvincesCall(lines[i])) {
          hits.add((path: relative, line: i + 1));
        }
      }
    }
  }

  final missingSanctions = hits.difference(sanctioned);
  final staleSanctions = sanctioned.difference(hits);

  if (missingSanctions.isEmpty && staleSanctions.isEmpty) {
    logI(
      'Logic allProvinces sanction check passed (${hits.length} call sites match '
      '$_sanctionsYamlRelative).',
    );
    return 0;
  }

  if (missingSanctions.isNotEmpty) {
    logE(
      'ERROR: Unsanctioned allProvinces( call site(s) under '
      '${_scanDirsRelative.join(', ')} '
      '(exclude $_canonicalProvinceLookupRelativePath). Add an entry to '
      '$_sanctionsYamlRelative in the same PR, per SPEC/program/logic-dual-region-province-access.md.',
    );
    final sorted = missingSanctions.toList()
      ..sort((a, b) {
        final c = a.path.compareTo(b.path);
        if (c != 0) return c;
        return a.line.compareTo(b.line);
      });
    for (final h in sorted) {
      logE('${h.path}:${h.line}');
    }
  }
  if (staleSanctions.isNotEmpty) {
    logE(
      'ERROR: Stale sanction(s) in $_sanctionsYamlRelative (no matching '
      'allProvinces( on that line). Remove or retarget the entry.',
    );
    final sorted = staleSanctions.toList()
      ..sort((a, b) {
        final c = a.path.compareTo(b.path);
        if (c != 0) return c;
        return a.line.compareTo(b.line);
      });
    for (final h in sorted) {
      logE('${h.path}:${h.line}');
    }
  }
  return 1;
}

void main() {
  exit(runCheckLogicAllProvincesSanctionedCalls(Directory.current.path));
}
