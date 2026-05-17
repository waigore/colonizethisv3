// Workspace-wide `dart analyze` / `flutter analyze` with CI "errors only" semantics.
// SPEC/program/repo-lint.md (GitHub #2014); mirrors `.github/workflows/quality.yml` grep gate.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Counts analyzer `error` diagnostics (not `warning` or `info`) for parity with:
/// `grep -c '^[[:space:]]*error'` on `dart analyze` / `flutter analyze` output.
int countAnalyzerErrorLines(String combinedOutput) {
  var n = 0;
  for (final line in const LineSplitter().convert(combinedOutput)) {
    if (RegExp(r'^\s*error\s').hasMatch(line)) {
      n++;
    }
  }
  return n;
}

bool packageDeclaresFlutterSdk(String pubspecYaml) {
  final root = loadYaml(pubspecYaml);
  if (root is! YamlMap) {
    return false;
  }
  final deps = root['dependencies'];
  if (deps is! YamlMap) {
    return false;
  }
  final flutter = deps['flutter'];
  if (flutter is! YamlMap) {
    return false;
  }
  return flutter['sdk'] == 'flutter';
}

/// True when [packageRoot] has Flutter l10n config (`l10n.yaml`), so generated
/// `lib/l10n/gen/*.dart` must exist before `flutter analyze` (CI parity with
/// `app_tests_cache` / local clones without committed codegen).
bool packageHasL10nConfig(String packageRoot) {
  return File(p.join(packageRoot, 'l10n.yaml')).existsSync();
}

/// True when [packagePath] is the Pub workspace host root (repo root), which
/// must not be passed to `dart analyze` — it would traverse nested `app/`
/// without `app`'s package context.
bool workspacePackageIsHostRoot(String repoRoot, String packagePath) {
  return p.equals(p.normalize(packagePath), p.normalize(repoRoot));
}

Future<ProcessResult> _run(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
  Map<String, String>? environment,
}) {
  return Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
    runInShell: false,
  );
}

Future<int> main(List<String> args) async {
  final repoRoot = Directory.current.path;
  final rootGet = await _run('dart', ['pub', 'get'], workingDirectory: repoRoot);
  if (rootGet.exitCode != 0) {
    stderr.writeln('dart pub get at repo root failed (exit ${rootGet.exitCode}):');
    stderr.writeln(rootGet.stderr);
    stderr.writeln(rootGet.stdout);
    return 1;
  }

  final ws = await _run('dart', ['pub', 'workspace', 'list', '--json'], workingDirectory: repoRoot);
  if (ws.exitCode != 0) {
    stderr.writeln(ws.stderr);
    stderr.writeln(ws.stdout);
    return 1;
  }
  final decoded = jsonDecode(ws.stdout as String) as Map<String, dynamic>;
  final packages = (decoded['packages'] as List<dynamic>).cast<Map<String, dynamic>>();
  packages.sort((a, b) => (a['path'] as String).compareTo(b['path'] as String));

  var totalErrors = 0;
  for (final entry in packages) {
    final pkgPath = entry['path'] as String;
    final name = entry['name'] as String;
    if (workspacePackageIsHostRoot(repoRoot, pkgPath)) {
      stdout.writeln(
        '--- dart analyze: $name ($pkgPath) ---\n'
        'skipped (workspace host root; member packages are analyzed separately)',
      );
      continue;
    }
    final pubspecFile = File(p.join(pkgPath, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      continue;
    }
    final pubspecText = pubspecFile.readAsStringSync();
    final isFlutter = packageDeclaresFlutterSdk(pubspecText);

    if (isFlutter) {
      final get = await _run('flutter', ['pub', 'get'], workingDirectory: pkgPath);
      if (get.exitCode != 0) {
        stderr.writeln('flutter pub get failed in $pkgPath (exit ${get.exitCode}):');
        stderr.writeln(get.stderr);
        stderr.writeln(get.stdout);
        return 1;
      }
      if (packageHasL10nConfig(pkgPath)) {
        final gen = await _run('flutter', ['gen-l10n'], workingDirectory: pkgPath);
        if (gen.exitCode != 0) {
          stderr.writeln(
            'flutter gen-l10n failed in $name at $pkgPath (exit ${gen.exitCode}):',
          );
          stderr.writeln(gen.stderr);
          stderr.writeln(gen.stdout);
          return 1;
        }
      }
      final analyze = await _run('flutter', ['analyze'], workingDirectory: pkgPath);
      final out = '${analyze.stdout}${analyze.stderr}';
      stdout.writeln('--- flutter analyze: $name ($pkgPath) ---');
      stdout.writeln(out.trimRight());
      final errCount = countAnalyzerErrorLines(out);
      if (errCount > 0) {
        stderr.writeln('Errors in $name: $errCount');
      }
      totalErrors += errCount;
    } else {
      final analyze = await _run('dart', ['analyze'], workingDirectory: pkgPath);
      final out = '${analyze.stdout}${analyze.stderr}';
      stdout.writeln('--- dart analyze: $name ($pkgPath) ---');
      stdout.writeln(out.trimRight());
      final errCount = countAnalyzerErrorLines(out);
      if (errCount > 0) {
        stderr.writeln('Errors in $name: $errCount');
      }
      totalErrors += errCount;
    }
  }

  if (totalErrors > 0) {
    stderr.writeln('Workspace analyze failed: $totalErrors analyzer error(s) total.');
    return 1;
  }
  stdout.writeln('Workspace analyze: no analyzer errors (warnings/infos do not fail).');
  return 0;
}
