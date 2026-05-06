import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

typedef ProcessRunner =
    ProcessResult Function(
      String executable,
      List<String> arguments, {
      String? workingDirectory,
    });

final class WorkspaceOutdatedViolation {
  const WorkspaceOutdatedViolation({
    required this.packageRoot,
    required this.packageName,
    required this.currentVersion,
    required this.resolvableVersion,
  });

  final String packageRoot;
  final String packageName;
  final String currentVersion;
  final String resolvableVersion;
}

/// Enforces #2073 policy: no package may remain below the `Resolvable` column
/// in workspace outdated audits.
///
/// SPEC: SPEC/program/pub-workspace-toolchain.md
int runCheckWorkspaceOutdatedResolvable(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
  ProcessRunner? processRunner,
  Set<String>? excludedPackages,
}) {
  final void Function(String) logI = info ?? stdout.writeln;
  final void Function(String) logE = err ?? stderr.writeln;
  final run = processRunner ?? _defaultRunner;
  final exclusions = excludedPackages ?? _readExcludedPackages();

  final auditTargets = _buildAuditTargets(repoRoot, logI);

  final violations = <WorkspaceOutdatedViolation>[];
  for (final target in auditTargets) {
    final targetRoot = p.normalize(p.join(repoRoot, target.relativePath));
    if (!Directory(targetRoot).existsSync()) {
      logI(
        'check_workspace_outdated_resolvable: skipping missing ${target.relativePath}',
      );
      continue;
    }

    final result = run(target.executable, const [
      'pub',
      'outdated',
      '--json',
    ], workingDirectory: targetRoot);
    if (result.exitCode != 0) {
      logE(
        'check_workspace_outdated_resolvable: `${target.executable} pub outdated --json` failed in ${target.relativePath == '.' ? 'repo root' : target.relativePath}',
      );
      if (result.stderr.toString().trim().isNotEmpty) {
        logE(result.stderr.toString().trim());
      }
      return 1;
    }

    final decoded = _decodePackages(result.stdout.toString());
    if (decoded == null) {
      logE(
        'check_workspace_outdated_resolvable: invalid JSON from `${target.executable} pub outdated --json` in ${target.relativePath}',
      );
      return 1;
    }

    final packageRoot = target.relativePath;
    for (final pkg in decoded) {
      final packageName = pkg['package'];
      final current = _extractVersion(pkg['current']);
      final resolvable = _extractVersion(pkg['resolvable']);
      if (packageName is! String || current == null || resolvable == null) {
        continue;
      }
      if (exclusions.contains(packageName)) {
        continue;
      }
      if (current == resolvable) {
        continue;
      }
      violations.add(
        WorkspaceOutdatedViolation(
          packageRoot: packageRoot,
          packageName: packageName,
          currentVersion: current,
          resolvableVersion: resolvable,
        ),
      );
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_workspace_outdated_resolvable: all audited packages are at Resolvable.',
    );
    return 0;
  }

  logE(
    'check_workspace_outdated_resolvable: found ${violations.length} package(s) below Resolvable:',
  );
  for (final violation in violations) {
    final scope = violation.packageRoot == '.'
        ? 'repo root'
        : violation.packageRoot;
    logE(
      ' - [$scope] ${violation.packageName}: current=${violation.currentVersion} resolvable=${violation.resolvableVersion}',
    );
  }
  return 1;
}

List<({String relativePath, String executable})> _buildAuditTargets(
  String repoRoot,
  void Function(String line) logI,
) {
  final targets = <({String relativePath, String executable})>[
    (relativePath: '.', executable: 'dart'),
  ];

  for (final member in _readWorkspaceMembers(repoRoot, logI)) {
    if (member == '.') {
      continue;
    }
    final memberRoot = p.normalize(p.join(repoRoot, member));
    if (!Directory(memberRoot).existsSync()) {
      continue;
    }
    final pubspecPath = p.join(memberRoot, 'pubspec.yaml');
    final pubspecFile = File(pubspecPath);
    if (!pubspecFile.existsSync()) {
      continue;
    }
    final pubspecText = pubspecFile.readAsStringSync();
    final executable = _usesFlutterSdk(pubspecText) ? 'flutter' : 'dart';
    targets.add((relativePath: member, executable: executable));
  }

  return targets;
}

List<String> _readWorkspaceMembers(String repoRoot, void Function(String line) logI) {
  final rootPubspec = File(p.join(repoRoot, 'pubspec.yaml'));
  if (!rootPubspec.existsSync()) {
    logI(
      'check_workspace_outdated_resolvable: root pubspec.yaml missing; only auditing repo root.',
    );
    return const <String>[];
  }

  final lines = rootPubspec.readAsLinesSync();
  final members = <String>[];
  var inWorkspace = false;
  for (final rawLine in lines) {
    final trimmedRight = rawLine.trimRight();
    final trimmedLeft = trimmedRight.trimLeft();
    if (!inWorkspace) {
      if (trimmedRight == 'workspace:') {
        inWorkspace = true;
      }
      continue;
    }

    final startsWithTopLevelKey =
        trimmedLeft.isNotEmpty && !rawLine.startsWith(' ') && trimmedLeft.endsWith(':');
    if (startsWithTopLevelKey) {
      break;
    }

    if (trimmedLeft.startsWith('- ')) {
      final value = trimmedLeft.substring(2).trim();
      if (value.isNotEmpty) {
        members.add(value);
      }
    }
  }

  return members;
}

bool _usesFlutterSdk(String pubspecText) {
  return RegExp(r'^\s*sdk\s*:\s*flutter\s*$', multiLine: true).hasMatch(pubspecText);
}

ProcessResult _defaultRunner(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
}) {
  return Process.runSync(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    runInShell: false,
  );
}

List<Map<String, Object?>>? _decodePackages(String text) {
  final decoded = jsonDecode(text);
  if (decoded is! Map<String, Object?>) {
    return null;
  }
  final packages = decoded['packages'];
  if (packages is! List<Object?>) {
    return null;
  }

  final out = <Map<String, Object?>>[];
  for (final entry in packages) {
    if (entry is Map<String, Object?>) {
      out.add(entry);
    }
  }
  return out;
}

String? _extractVersion(Object? node) {
  if (node is! Map<String, Object?>) {
    return null;
  }
  final version = node['version'];
  if (version is! String || version.trim().isEmpty) {
    return null;
  }
  return version.trim();
}

Set<String> _readExcludedPackages() {
  final raw = Platform.environment['CT_WORKSPACE_OUTDATED_EXCLUDE'];
  if (raw == null || raw.trim().isEmpty) {
    return const <String>{};
  }
  return raw
      .split(',')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toSet();
}

void main() {
  exit(runCheckWorkspaceOutdatedResolvable(Directory.current.path));
}
