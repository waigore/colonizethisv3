import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/logic-package-barrel-contracts.md (Refs #3393 Phase 3 —
/// AI API narrowing). Rule `repo.ai_api_narrow_surface`.
///
/// Enforces that the narrow AI contract
/// `packages/colonizethis_logic/lib/ai_api.dart` re-exports sibling-domain
/// symbols through the **domain barrel**
/// (`package:colonizethis_<domain>/colonizethis_<domain>.dart`) instead of
/// reaching around the barrel into a deep `package:colonizethis_<domain>/src/...`
/// path whenever that barrel already re-exports the owning file.
///
/// A deep `src/` export is a **violation** only when the owning domain barrel
/// already publishes that file (transitively, via its `export` graph). Deep
/// exports of files the barrel does not publish are allowed — they are the only
/// available contract surface, and this rule's predicate is derived purely from
/// the live barrel contents (no keyed waiver / allowlist data, per
/// `SPEC/program/repo-lint.md` § Policy: no violation allowlists).
const List<String> _domainPackages = <String>[
  'colonizethis_world',
  'colonizethis_orders',
  'colonizethis_economy',
  'colonizethis_diplomacy',
  'colonizethis_turn',
  'colonizethis_combat',
  'colonizethis_setup',
];

/// Matches the URI in any `export '<uri>'` directive (single or double quoted).
final RegExp _exportUri = RegExp('''export\\s+['"]([^'"]+)['"]''');

void main(List<String> args) {
  exit(runCheckAiApiNarrowSurface(Directory.current.path));
}

int runCheckAiApiNarrowSurface(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final root = p.normalize(repoRoot);
  final aiApiFile = File(
    p.join(root, 'packages', 'colonizethis_logic', 'lib', 'ai_api.dart'),
  );
  if (!aiApiFile.existsSync()) {
    logE(
      'ERROR: Missing AI contract file: '
      'packages/colonizethis_logic/lib/ai_api.dart',
    );
    return 1;
  }

  final content = aiApiFile.readAsStringSync();
  final lines = content.split('\n');
  final violations = <String>[];

  // Resolve each referenced domain barrel lazily and memoize it: only packages
  // actually deep-exported by ai_api.dart need a barrel reachability set.
  final barrelReachableByPackage = <String, Set<String>>{};

  for (var i = 0; i < lines.length; i++) {
    final match = _exportUri.firstMatch(lines[i]);
    if (match == null) continue;
    final uri = match.group(1)!;
    final parsed = _parseSiblingDeepSrcUri(uri);
    if (parsed == null) continue;

    final reachable = barrelReachableByPackage.putIfAbsent(
      parsed.package,
      () => _barrelReachableFiles(root, parsed.package) ?? const <String>{},
    );
    if (!File(
      p.join(root, 'packages', parsed.package, 'lib', '${parsed.package}.dart'),
    ).existsSync()) {
      logE(
        'ERROR: Missing barrel for ${parsed.package} '
        '(expected lib/${parsed.package}.dart).',
      );
      return 1;
    }

    final targetFile = p.normalize(
      p.join(root, 'packages', parsed.package, 'lib', parsed.srcRelative),
    );
    if (reachable.contains(targetFile)) {
      violations.add(
        'packages/colonizethis_logic/lib/ai_api.dart:${i + 1}: '
        "export '$uri' bypasses the ${parsed.package} barrel "
        '(barrel already re-exports ${parsed.srcRelative}); use '
        "export 'package:${parsed.package}/${parsed.package}.dart' show ...",
      );
    }
  }

  if (violations.isEmpty) {
    logI('check_ai_api_narrow_surface: no barrel-bypass exports found.');
    return 0;
  }

  logE(
    'check_ai_api_narrow_surface: found ${violations.length} deep `src/` '
    'export(s) in ai_api.dart that the domain barrel already publishes. '
    'Re-export through the domain barrel '
    '(package:colonizethis_<domain>/colonizethis_<domain>.dart) instead.',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  return 1;
}

/// A `package:colonizethis_<domain>/src/...` URI split into package + src path.
class _SiblingDeepSrcUri {
  const _SiblingDeepSrcUri(this.package, this.srcRelative);

  /// e.g. `colonizethis_world`.
  final String package;

  /// e.g. `src/world/ai_control.dart` (relative to the package `lib/`).
  final String srcRelative;
}

_SiblingDeepSrcUri? _parseSiblingDeepSrcUri(String uri) {
  if (!uri.startsWith('package:')) return null;
  final withoutScheme = uri.substring('package:'.length);
  final slash = withoutScheme.indexOf('/');
  if (slash < 0) return null;
  final package = withoutScheme.substring(0, slash);
  final rest = withoutScheme.substring(slash + 1);
  if (!_domainPackages.contains(package)) return null;
  if (!rest.startsWith('src/')) return null;
  return _SiblingDeepSrcUri(package, rest);
}

/// Resolves the transitive set of `lib/**` files reachable from a domain
/// package barrel through `export` directives. Returns `null` when the barrel
/// file does not exist.
Set<String>? _barrelReachableFiles(String root, String pkg) {
  final libDir = p.join(root, 'packages', pkg, 'lib');
  final barrel = p.normalize(p.join(libDir, '$pkg.dart'));
  if (!File(barrel).existsSync()) return null;

  final reachable = <String>{};
  final queue = <String>[barrel];
  while (queue.isNotEmpty) {
    final current = queue.removeLast();
    if (!reachable.add(current)) continue;
    final file = File(current);
    if (!file.existsSync()) continue;
    final currentDir = p.dirname(current);
    for (final line in file.readAsLinesSync()) {
      final match = _exportUri.firstMatch(line);
      if (match == null) continue;
      final resolved = _resolveExportTarget(
        uri: match.group(1)!,
        currentDir: currentDir,
        libDir: libDir,
        pkg: pkg,
      );
      if (resolved != null) {
        queue.add(resolved);
      }
    }
  }
  // The barrel file itself is not a re-exportable src target.
  reachable.remove(barrel);
  return reachable;
}

/// Resolves an `export` URI to an absolute file path **inside the same package
/// `lib/`**, or `null` for cross-package / external exports (which cannot make a
/// `package:<pkg>/src/...` file reachable for the matching-package predicate).
String? _resolveExportTarget({
  required String uri,
  required String currentDir,
  required String libDir,
  required String pkg,
}) {
  if (uri.startsWith('package:')) {
    final withoutScheme = uri.substring('package:'.length);
    final slash = withoutScheme.indexOf('/');
    if (slash < 0) return null;
    final uriPkg = withoutScheme.substring(0, slash);
    if (uriPkg != pkg) return null;
    final rest = withoutScheme.substring(slash + 1);
    return p.normalize(p.join(libDir, rest));
  }
  if (uri.startsWith('dart:')) return null;
  // Relative export resolved against the current file's directory.
  return p.normalize(p.join(currentDir, uri));
}
