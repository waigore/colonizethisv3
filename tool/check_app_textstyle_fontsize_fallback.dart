import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// PR-blocking structural check: production UI surface under
/// `app/lib/features/` and `app/lib/widgets/` must size themed-text fallbacks
/// to the canonical editorial-monocle `TextTheme` slot, not an arbitrary magic
/// number.
///
/// Scope is intentionally narrow to the `?? const TextStyle(fontSize: N)`
/// fallback idiom paired with a `textTheme.<slot>` read, e.g.:
///
/// ```dart
/// final style = theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
/// ```
///
/// The `editorialMonocle` theme always supplies a non-null `TextTheme` (M3 dark
/// base), so the fallback never renders in practice — but when it differs from
/// the slot's canonical size it silently drifts the documented type ramp. This
/// check pins every such fallback to the canonical M3 dark slot size so the
/// ramp stays single-sourced.
///
/// SPEC:
/// - `SPEC/program/repo-lint.md` (rule `repo.app_textstyle_fontsize_fallback`)
/// - `SPEC/ui/pixel-art-ui-catalog.md` § Editorial-monocle palette / font stacks
///
/// Refs #2914 (Phase 1 §S7 — font-size normalization; enforces the slot→size
/// table in the issue body).
///
/// Scope (production UI surface, non-test, non-generated):
/// - `app/lib/features/**/*.dart`
/// - `app/lib/widgets/**/*.dart`
int runCheckAppTextStyleFontSizeFallback(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final featuresDir = Directory(
    p.join(repoRoot, 'app', 'lib', 'features'),
  );
  if (!featuresDir.existsSync()) {
    logE('check_app_textstyle_fontsize_fallback: app/lib/features not found.');
    return 1;
  }
  final widgetsDir = Directory(
    p.join(repoRoot, 'app', 'lib', 'widgets'),
  );

  final violations = <String>[];
  final scanRoots = <Directory>[
    featuresDir,
    if (widgetsDir.existsSync()) widgetsDir,
  ];
  for (final root in scanRoots) {
    for (final entity in root.listSync(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final relativePath = p
          .relative(entity.path, from: repoRoot)
          .replaceAll('\\', '/');
      if (shouldSkipAppTextStyleFontSizeFallbackFile(relativePath)) {
        continue;
      }
      violations.addAll(
        findTextStyleFontSizeFallbackViolations(
          relativePath,
          entity.readAsStringSync(),
        ),
      );
    }
  }

  if (violations.isEmpty) {
    logI('check_app_textstyle_fontsize_fallback: no violations found.');
    return 0;
  }

  logE(
    'check_app_textstyle_fontsize_fallback: found ${violations.length} '
    'violation(s) under app/lib/features/ and app/lib/widgets/ '
    '(themed-text fallback fontSize does not match the canonical TextTheme '
    'slot size; see SPEC/ui/pixel-art-ui-catalog.md and #2914 §S7):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

/// Canonical M3 dark (`useMaterial3: true`) `TextTheme` slot → font size in
/// logical pixels, as consumed by `AppThemes.editorialMonocle`. Mirrors the
/// slot→size table in the #2914 issue body. Slots not listed here are not
/// enforced (the checker skips fallbacks that read an out-of-table slot).
const Map<String, double> canonicalFontSizeBySlot = <String, double>{
  'headlineMedium': 28,
  'headlineSmall': 24,
  'titleLarge': 22,
  'titleMedium': 16,
  'titleSmall': 14,
  'bodyLarge': 16,
  'bodyMedium': 14,
  'bodySmall': 12,
  'labelLarge': 14,
  'labelMedium': 12,
  'labelSmall': 11,
};

/// Matches the `textTheme.<slot> ?? const TextStyle(fontSize: <number>` idiom,
/// tolerating whitespace and a line break between the slot read and the
/// `?? const TextStyle(...)` fallback. `fontSize` must be the first argument
/// of the `const TextStyle(...)` fallback (the only shape used in the codebase).
///
/// Exposed for unit tests.
final RegExp textStyleFontSizeFallbackPattern = RegExp(
  r'textTheme\.([A-Za-z]+)\s*\?\?\s*const\s+TextStyle\(\s*fontSize:\s*'
  r'([0-9]+(?:\.[0-9]+)?)',
  multiLine: true,
);

/// Returns the list of `relativePath:line: ...` violation strings for [content].
///
/// A match is a violation when its slot is present in
/// [canonicalFontSizeBySlot] and the literal fallback size differs from the
/// canonical slot size. Matches whose slot token line begins with `//`
/// (line comment or `///` dartdoc) are skipped so narrative references to the
/// idiom do not trip the check. Exposed for unit tests.
List<String> findTextStyleFontSizeFallbackViolations(
  String relativePath,
  String content,
) {
  final lines = const LineSplitter().convert(content);
  final results = <String>[];
  for (final match in textStyleFontSizeFallbackPattern.allMatches(content)) {
    final slot = match.group(1)!;
    final canonical = canonicalFontSizeBySlot[slot];
    if (canonical == null) {
      continue;
    }
    final lineIndex = '\n'.allMatches(content.substring(0, match.start)).length;
    if (lineIndex < lines.length &&
        lines[lineIndex].trimLeft().startsWith('//')) {
      continue;
    }
    final literal = double.parse(match.group(2)!);
    if (literal == canonical) {
      continue;
    }
    results.add(
      '$relativePath:${lineIndex + 1}: textTheme.$slot fallback '
      'fontSize ${match.group(2)!} -> expected ${_format(canonical)} '
      '(canonical M3 dark $slot slot; see #2914 §S7)',
    );
  }
  return results;
}

String _format(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

/// True when [relativePath] (POSIX, repo-rooted) should be skipped: generated
/// suffixes and test files (production UI surface only). Exposed for unit
/// tests.
bool shouldSkipAppTextStyleFontSizeFallbackFile(String relativePath) {
  if (relativePath.endsWith('.g.dart') ||
      relativePath.endsWith('.freezed.dart') ||
      relativePath.endsWith('.mocks.dart') ||
      relativePath.endsWith('.gen.dart')) {
    return true;
  }
  if (relativePath.endsWith('_test.dart') ||
      relativePath.contains('/test/')) {
    return true;
  }
  return false;
}

void main() {
  exit(runCheckAppTextStyleFontSizeFallback(Directory.current.path));
}
