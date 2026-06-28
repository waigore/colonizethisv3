// Keeps the observe-mode shell guard centralized in one canonical helper
// (Refs #3546 target state #1 / AC1). The full-screen feature bodies
// (trade / technology / production / diplomacy) and the military/naval
// unit-panel sheets previously each re-derived the same
// `shellPanelsNotDefined(...)` branch + `ObserveModeNotDefinedPanel`
// construction. That duplication was collapsed into
// `app/lib/features/game/widgets/shell_player_guarded_body.dart`
// (`observeNotDefinedSentinel`), so every screen/panel now consumes the guard
// through that helper instead of calling `shellPanelsNotDefined` directly.
//
// This gate forbids any `app/lib/**` file other than the guard's declaration
// site and the canonical helper from calling `shellPanelsNotDefined(...)`,
// preventing the duplicated guard from creeping back into individual surfaces.
//
// SPEC: SPEC/program/repo-lint.md
import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Declaration site of `bool shellPanelsNotDefined(ShellPlayerContext)`.
const String shellPanelDedupDefinitionPath =
    'app/lib/features/game/shell_player_context.dart';

/// The single canonical helper (`observeNotDefinedSentinel`) that wraps the
/// guard branch; every screen/panel must route through it.
const String shellPanelDedupHelperPath =
    'app/lib/features/game/widgets/shell_player_guarded_body.dart';

/// Files allowed to reference `shellPanelsNotDefined` directly.
const Set<String> shellPanelDedupAllowlist = <String>{
  shellPanelDedupDefinitionPath,
  shellPanelDedupHelperPath,
};

final RegExp _shellPanelGuardCall = RegExp(r'\bshellPanelsNotDefined\s*\(');

/// True when [slashPath] (POSIX-style, repo-relative) is an `app/lib/**` source
/// that must route the observe-mode guard through the canonical helper.
bool appShellPanelDedupPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith('app/lib/')) {
    return false;
  }
  if (shellPanelDedupAllowlist.contains(normalized)) {
    return false;
  }
  return true;
}

/// Returns the 1-based line numbers in [content] that call
/// `shellPanelsNotDefined(` (blank and line-comment lines excluded).
List<int> appShellPanelDedupViolationLineNumbers(String content) {
  final out = <int>[];
  final lines = content.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trimLeft();
    if (line.isEmpty || line.startsWith('//')) {
      continue;
    }
    if (_shellPanelGuardCall.hasMatch(line)) {
      out.add(i + 1);
    }
  }
  return out;
}

int runCheckAppShellPanelDedup(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintAppLibDartFilesSorted(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (repoLintAppLibHardcodedUiVisitorShouldSkip(rel)) {
      continue;
    }
    if (!appShellPanelDedupPathInScope(rel)) {
      continue;
    }
    for (final lineNumber in appShellPanelDedupViolationLineNumbers(
      file.readAsStringSync(),
    )) {
      violations.add(
        '$rel:$lineNumber: direct `shellPanelsNotDefined(...)` call is '
        'disallowed — route the observe-mode guard through '
        '`observeNotDefinedSentinel` in $shellPanelDedupHelperPath so the '
        'guard lives in one canonical place (Refs #3546)',
      );
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_app_shell_panel_dedup: observe-mode shell guard stays centralized '
      'in $shellPanelDedupHelperPath.',
    );
    return 0;
  }
  logE('check_app_shell_panel_dedup: ${violations.length} violation(s):');
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAppShellPanelDedup(Directory.current.path));
}
