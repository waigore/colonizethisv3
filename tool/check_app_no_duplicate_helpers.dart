import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Canonical location for a tracked helper symbol.
class _CanonicalHelper {
  const _CanonicalHelper({
    required this.symbol,
    required this.canonicalRelativePath,
    required this.kind,
  });

  /// Top-level function name (e.g. `eraRoman`).
  final String symbol;

  /// Repo-relative POSIX path of the **only** file in `app/lib/**` that may
  /// declare this symbol as a top-level function.
  final String canonicalRelativePath;

  /// Human-readable description for the failure message.
  final String kind;
}

/// Removed-helper symbol that must no longer be declared anywhere under
/// `app/lib/**`. Covers both the private duplicates eliminated in #2185 /
/// #2187 and public wrapper helpers replaced by a canonical helper (#3279).
class _RemovedHelper {
  const _RemovedHelper({required this.symbol, required this.replacement});

  /// Helper name that previously lived in its own file or as a duplicate.
  final String symbol;

  /// Canonical replacement to suggest in the violation message.
  final String replacement;
}

/// Tracked canonical helpers from #2180. Each symbol must be declared in
/// **exactly one** file under `app/lib/**` (the canonical path) and nowhere
/// else as a top-level function.
const List<_CanonicalHelper> _trackedCanonicalHelpers = <_CanonicalHelper>[
  _CanonicalHelper(
    symbol: 'eraRoman',
    canonicalRelativePath: 'app/lib/features/game/utils/tech_ui_helpers.dart',
    kind: 'tech UI helper',
  ),
  _CanonicalHelper(
    symbol: 'techCategoryLabelL10n',
    canonicalRelativePath: 'app/lib/features/game/utils/tech_ui_helpers.dart',
    kind: 'tech UI helper',
  ),
  _CanonicalHelper(
    symbol: 'commodityDisplayName',
    canonicalRelativePath:
        'app/lib/features/game/utils/commodity_ui_helpers.dart',
    kind: 'commodity UI helper',
  ),
  _CanonicalHelper(
    symbol: 'trainDialogPlayerById',
    canonicalRelativePath:
        'app/lib/features/game/widgets/train_unit_dialog_helper.dart',
    kind: 'train dialog helper',
  ),
  _CanonicalHelper(
    symbol: 'trainDialogHasCapital',
    canonicalRelativePath:
        'app/lib/features/game/widgets/train_unit_dialog_helper.dart',
    kind: 'train dialog helper',
  ),
  _CanonicalHelper(
    symbol: 'trainDialogTreasury',
    canonicalRelativePath:
        'app/lib/features/game/widgets/train_unit_dialog_helper.dart',
    kind: 'train dialog helper',
  ),
  _CanonicalHelper(
    symbol: 'trainDialogTechUnlocked',
    canonicalRelativePath:
        'app/lib/features/game/widgets/train_unit_dialog_helper.dart',
    kind: 'train dialog helper',
  ),
  _CanonicalHelper(
    symbol: 'trainDialogIsLocked',
    canonicalRelativePath:
        'app/lib/features/game/widgets/train_unit_dialog_helper.dart',
    kind: 'train dialog helper',
  ),
  _CanonicalHelper(
    symbol: 'initialTrainDialogCountsFromOrders',
    canonicalRelativePath:
        'app/lib/features/game/widgets/train_unit_dialog_helper.dart',
    kind: 'train dialog helper',
  ),
  _CanonicalHelper(
    symbol: 'materializeTrainDialogOrdersFromCounts',
    canonicalRelativePath:
        'app/lib/features/game/widgets/train_unit_dialog_helper.dart',
    kind: 'train dialog helper',
  ),
  _CanonicalHelper(
    symbol: 'incrementTrainDialogCount',
    canonicalRelativePath:
        'app/lib/features/game/widgets/train_unit_dialog_helper.dart',
    kind: 'train dialog helper',
  ),
  _CanonicalHelper(
    symbol: 'decrementTrainDialogCount',
    canonicalRelativePath:
        'app/lib/features/game/widgets/train_unit_dialog_helper.dart',
    kind: 'train dialog helper',
  ),
  _CanonicalHelper(
    symbol: 'resetTrainDialogCounts',
    canonicalRelativePath:
        'app/lib/features/game/widgets/train_unit_dialog_helper.dart',
    kind: 'train dialog helper',
  ),
];

/// Removed private helpers that were extracted to shared canonical helpers.
/// Re-introducing them as top-level functions or methods anywhere under
/// `app/lib/**` is treated as a regression of the #2180 deduplication.
const List<_RemovedHelper> _removedPrivateHelpers = <_RemovedHelper>[
  _RemovedHelper(
    symbol: '_eraRoman',
    replacement:
        'eraRoman from app/lib/features/game/utils/tech_ui_helpers.dart',
  ),
  _RemovedHelper(
    symbol: '_categoryLabel',
    replacement:
        'techCategoryLabelL10n from app/lib/features/game/utils/tech_ui_helpers.dart',
  ),
  _RemovedHelper(
    symbol: '_categoryLabelL10n',
    replacement:
        'techCategoryLabelL10n from app/lib/features/game/utils/tech_ui_helpers.dart',
  ),
  _RemovedHelper(
    symbol: '_commodityDisplayName',
    replacement:
        'commodityDisplayName from app/lib/features/game/utils/commodity_ui_helpers.dart',
  ),
  // #3279: thin wrapper deleted; call `regionDisplayLabel` directly.
  _RemovedHelper(
    symbol: 'unitsPanelRegionLabel',
    replacement:
        'regionDisplayLabel from app/lib/features/game/utils/region_labels.dart',
  ),
];

/// PR-blocking regression gate for `#2180` helper extractions.
///
/// Two checks per scanned `app/lib/**/*.dart` file:
///
/// 1. **Canonical helpers:** Each tracked helper from
///    [_trackedCanonicalHelpers] must be declared as a top-level function
///    only in its canonical file. Top-level redefinitions in any other file
///    are violations.
/// 2. **Removed private helpers:** None of [_removedPrivateHelpers] may be
///    declared anywhere as a top-level function or class method. Reintroducing
///    them indicates a copy-paste regression of the deduplication landed in
///    #2185 / #2187.
///
/// Excluded paths (whole-file scope skips per `SPEC/program/repo-lint.md`):
/// - Generated Dart suffixes (`.g.dart`, `.freezed.dart`, `.mocks.dart`,
///   `.gen.dart`).
/// - Generated app l10n under `app/lib/l10n/gen/`.
/// - Widgetbook entrypoint (`app/lib/widgetbook.dart`) and catalog stories
///   under `app/lib/widgetbook/` — these intentionally reproduce production
///   helpers for showcasing.
/// - E2E expected-line snapshots under `app/lib/test_support/` — these
///   intentionally mirror production code as golden fixtures.
/// - Test paths and fixture trees.
int runCheckAppNoDuplicateHelpers(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final appLibDir = Directory(p.join(repoRoot, 'app', 'lib'));
  if (!appLibDir.existsSync()) {
    logE('check_app_no_duplicate_helpers: app/lib not found.');
    return 1;
  }

  final trackedBySymbol = <String, _CanonicalHelper>{
    for (final h in _trackedCanonicalHelpers) h.symbol: h,
  };
  final removedBySymbol = <String, _RemovedHelper>{
    for (final r in _removedPrivateHelpers) r.symbol: r,
  };

  final canonicalSightings = <String, List<_DeclarationSite>>{};
  final removedSightings = <String, List<_DeclarationSite>>{};

  final candidates = collectRepoLintAppLibDartFilesSorted(repoRoot);

  for (final file in candidates) {
    final relativePath = p
        .relative(file.path, from: repoRoot)
        .replaceAll('\\', '/');
    if (_shouldSkipPath(relativePath)) {
      continue;
    }
    final content = file.readAsStringSync();
    final parsed = parseString(content: content, path: relativePath);
    final visitor = _HelperDeclarationVisitor(
      relativePath: relativePath,
      lineInfo: parsed.unit.lineInfo,
      trackedTopLevel: trackedBySymbol.keys.toSet(),
      removedAny: removedBySymbol.keys.toSet(),
      canonicalSightings: canonicalSightings,
      removedSightings: removedSightings,
    );
    parsed.unit.accept(visitor);
  }

  final violations = <String>[];

  for (final helper in _trackedCanonicalHelpers) {
    final sightings = canonicalSightings[helper.symbol] ?? const [];
    for (final site in sightings) {
      if (site.relativePath == helper.canonicalRelativePath) {
        continue;
      }
      violations.add(
        '${site.relativePath}:${site.startLine}: top-level function '
        '"${helper.symbol}" redefines a tracked ${helper.kind}; '
        'import the canonical declaration from '
        '${helper.canonicalRelativePath}.',
      );
    }
  }

  for (final removed in _removedPrivateHelpers) {
    final sightings = removedSightings[removed.symbol] ?? const [];
    for (final site in sightings) {
      violations.add(
        '${site.relativePath}:${site.startLine}: removed private helper '
        '"${removed.symbol}" reappears (use ${removed.replacement}).',
      );
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_app_no_duplicate_helpers: no canonical-helper or removed-helper '
      'regressions found.',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_app_no_duplicate_helpers: found ${violations.length} regression(s):',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  return 1;
}

/// Hand-written app/lib scope skip predicate: generated suffixes, generated
/// l10n, the Widgetbook entrypoint and catalog stories, the test_support
/// golden snapshots, fixture trees, and any test path.
///
/// `relativePath` must already be POSIX-style (forward slashes).
bool _shouldSkipPath(String relativePath) {
  if (!relativePath.endsWith('.dart')) {
    return true;
  }
  if (relativePath.endsWith('.g.dart') ||
      relativePath.endsWith('.freezed.dart') ||
      relativePath.endsWith('.mocks.dart') ||
      relativePath.endsWith('.gen.dart')) {
    return true;
  }
  if (relativePath.startsWith('app/lib/l10n/gen/')) {
    return true;
  }
  if (relativePath == 'app/lib/widgetbook.dart' ||
      relativePath.startsWith('app/lib/widgetbook/')) {
    return true;
  }
  if (relativePath.startsWith('app/lib/test_support/')) {
    return true;
  }
  if (relativePath.contains('/test/') || relativePath.endsWith('_test.dart')) {
    return true;
  }
  for (final marker in repoLintFixtureDirPathMarkers) {
    if (('/$relativePath').contains(marker)) {
      return true;
    }
  }
  return false;
}

class _DeclarationSite {
  const _DeclarationSite({required this.relativePath, required this.startLine});

  final String relativePath;
  final int startLine;
}

class _HelperDeclarationVisitor extends RecursiveAstVisitor<void> {
  _HelperDeclarationVisitor({
    required this.relativePath,
    required this.lineInfo,
    required this.trackedTopLevel,
    required this.removedAny,
    required this.canonicalSightings,
    required this.removedSightings,
  });

  final String relativePath;
  final LineInfo lineInfo;
  final Set<String> trackedTopLevel;
  final Set<String> removedAny;
  final Map<String, List<_DeclarationSite>> canonicalSightings;
  final Map<String, List<_DeclarationSite>> removedSightings;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final name = node.name.lexeme;
    final line = lineInfo.getLocation(node.offset).lineNumber;
    if (trackedTopLevel.contains(name)) {
      canonicalSightings
          .putIfAbsent(name, () => [])
          .add(_DeclarationSite(relativePath: relativePath, startLine: line));
    }
    if (removedAny.contains(name)) {
      removedSightings
          .putIfAbsent(name, () => [])
          .add(_DeclarationSite(relativePath: relativePath, startLine: line));
    }
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final name = node.name.lexeme;
    final line = lineInfo.getLocation(node.offset).lineNumber;
    if (removedAny.contains(name)) {
      removedSightings
          .putIfAbsent(name, () => [])
          .add(_DeclarationSite(relativePath: relativePath, startLine: line));
    }
    super.visitMethodDeclaration(node);
  }
}

void main() {
  exit(runCheckAppNoDuplicateHelpers(Directory.current.path));
}
