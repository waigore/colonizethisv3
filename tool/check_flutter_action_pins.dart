import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Enforces Flutter CI pinning: every `subosito/flutter-action@...` workflow
/// step must define a non-empty `with.flutter-version`.
///
/// SPEC: SPEC/program/pub-workspace-toolchain.md
int runCheckFlutterActionPins(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final workflowsDir = Directory(p.join(repoRoot, '.github', 'workflows'));
  if (!workflowsDir.existsSync()) {
    logE('check_flutter_action_pins: .github/workflows not found.');
    return 1;
  }

  final violations = <String>[];
  for (final entity in workflowsDir.listSync(
    recursive: false,
    followLinks: false,
  )) {
    if (entity is! File) {
      continue;
    }
    final ext = p.extension(entity.path);
    if (ext != '.yml' && ext != '.yaml') {
      continue;
    }
    final relPath = p.relative(entity.path, from: repoRoot);
    final raw = entity.readAsStringSync();
    final parsed = loadYaml(raw);
    if (parsed is! YamlMap) {
      violations.add('$relPath: file is not a YAML map at root');
      continue;
    }
    _collectViolations(parsed, relPath, violations);
  }

  if (violations.isEmpty) {
    logI('check_flutter_action_pins: all flutter-action steps are pinned.');
    return 0;
  }

  logE(
    'check_flutter_action_pins: found ${violations.length} workflow step(s) without with.flutter-version pin:',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void _collectViolations(YamlMap map, String relPath, List<String> violations) {
  for (final entry in map.entries) {
    final value = entry.value;
    if (value is YamlMap) {
      _collectViolations(value, relPath, violations);
      continue;
    }
    if (value is YamlList) {
      for (var i = 0; i < value.length; i++) {
        final item = value[i];
        if (item is YamlMap) {
          _checkStepMap(item, relPath, violations, i);
          _collectViolations(item, relPath, violations);
        }
      }
    }
  }
}

void _checkStepMap(
  YamlMap step,
  String relPath,
  List<String> violations,
  int index,
) {
  final uses = step['uses'];
  if (uses is! String || !uses.startsWith('subosito/flutter-action@')) {
    return;
  }
  final withMap = step['with'];
  final flutterVersion = withMap is YamlMap ? withMap['flutter-version'] : null;
  if (flutterVersion is String && flutterVersion.trim().isNotEmpty) {
    return;
  }
  final name = step['name'];
  final stepLabel = name is String && name.trim().isNotEmpty
      ? '"${name.trim()}"'
      : 'index $index';
  violations.add(
    '$relPath step $stepLabel uses $uses without flutter-version pin',
  );
}

void main() {
  exit(runCheckFlutterActionPins(Directory.current.path));
}
