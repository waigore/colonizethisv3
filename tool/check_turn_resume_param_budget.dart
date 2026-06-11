import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix whose `lib/` Dart sources host the Diplomacy-phase
/// resume entry points (`resumeTurnResolutionWith*Decisions`). Refs #3416.
const String _turnLibPathPrefix = 'packages/colonizethis_turn/lib/';

/// Maximum number of named parameters a `resumeTurnResolution*` entry point or
/// its shared dispatch may declare. The resume wrappers must forward a single
/// [TurnResolverConfig] (plus the resume-specific `game`, decision list, and
/// `pendingOvertures`) instead of re-threading every resolver parameter
/// individually. The widest legitimate declaration is the private shared
/// dispatch `_resumeTurnResolutionWithDiplomacyDecisions`, which carries `game`,
/// `config`, and the four optional decision lists (6). Re-threading the full
/// individual resolver parameter list (~14) stays well above this budget.
/// Raising this budget requires a SPEC update in
/// `SPEC/program/turn-resume-config-dispatch.md` and a maintainer-reviewed PR.
const int turnResumeMaxNamedParams = 6;

/// Matches the opening of a `resumeTurnResolution*` declaration whose named
/// parameter block (`({`) follows the function name. Call sites pass named
/// arguments (`(\n game: ...`) and therefore never match this `(` + `{` form,
/// so only declarations are evaluated. The leading `_` of the private dispatch
/// is outside the captured name but still produces a match.
final RegExp _resumeDeclPattern = RegExp(
  r'(resumeTurnResolution\w*)\s*\(\s*\{',
);

/// True when the repo-relative [slashPath] is under the turn package `lib/`.
bool turnResumeParamBudgetPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_turnLibPathPrefix);
}

/// Counts the top-level named parameters declared in the parameter block that
/// begins at [openBraceIndex] (the `{` of a `({ ... })` named parameter list).
///
/// Commas nested inside generic type arguments (`<...>`), function-type
/// parameter lists (`(...)`), collection literals (`[...]`), or nested record
/// `{...}` groups are ignored; only separators at the block's top level are
/// counted. A trailing comma does not inflate the count.
int turnResumeCountNamedParams(String source, int openBraceIndex) {
  var braceDepth = 0;
  var parenDepth = 0;
  var bracketDepth = 0;
  var angleDepth = 0;
  var topLevelCommas = 0;
  final buffer = StringBuffer();
  var closed = false;
  for (var i = openBraceIndex; i < source.length; i++) {
    final c = source[i];
    if (c == '{') {
      braceDepth++;
      continue;
    }
    if (c == '}') {
      braceDepth--;
      if (braceDepth == 0) {
        closed = true;
        break;
      }
      buffer.write(c);
      continue;
    }
    if (c == '(') {
      parenDepth++;
      buffer.write(c);
      continue;
    }
    if (c == ')') {
      parenDepth--;
      buffer.write(c);
      continue;
    }
    if (c == '[') {
      bracketDepth++;
      buffer.write(c);
      continue;
    }
    if (c == ']') {
      bracketDepth--;
      buffer.write(c);
      continue;
    }
    if (c == '<') {
      angleDepth++;
      buffer.write(c);
      continue;
    }
    if (c == '>') {
      if (angleDepth > 0) angleDepth--;
      buffer.write(c);
      continue;
    }
    final atTopLevel =
        braceDepth == 1 &&
        parenDepth == 0 &&
        bracketDepth == 0 &&
        angleDepth == 0;
    if (c == ',' && atTopLevel) {
      topLevelCommas++;
    }
    buffer.write(c);
  }
  if (!closed) {
    return -1;
  }
  final content = buffer.toString().trim();
  if (content.isEmpty) {
    return 0;
  }
  final trailingComma = content.endsWith(',');
  return topLevelCommas + (trailingComma ? 0 : 1);
}

/// Returns the violations in [content]: each `resumeTurnResolution*` declaration
/// whose named-parameter count exceeds [turnResumeMaxNamedParams].
List<TurnResumeParamHit> turnResumeParamBudgetViolations(
  String relPath,
  String content,
) {
  final hits = <TurnResumeParamHit>[];
  for (final match in _resumeDeclPattern.allMatches(content)) {
    final braceIndex = content.indexOf('{', match.start);
    if (braceIndex < 0) continue;
    final count = turnResumeCountNamedParams(content, braceIndex);
    if (count <= turnResumeMaxNamedParams) {
      continue;
    }
    final line = '\n'.allMatches(content.substring(0, match.start)).length + 1;
    hits.add(
      TurnResumeParamHit(
        path: relPath,
        line: line,
        functionName: match.group(1)!,
        paramCount: count,
      ),
    );
  }
  return hits;
}

int runCheckTurnResumeParamBudget(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <TurnResumeParamHit>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!turnResumeParamBudgetPathInScope(rel)) {
      continue;
    }
    violations.addAll(
      turnResumeParamBudgetViolations(rel, file.readAsStringSync()),
    );
  }

  if (violations.isEmpty) {
    logI(
      'check_turn_resume_param_budget: no resume entry point exceeds '
      '$turnResumeMaxNamedParams named parameters.',
    );
    return 0;
  }
  logE(
    'check_turn_resume_param_budget: ${violations.length} resume entry '
    'point(s) exceed the $turnResumeMaxNamedParams named-parameter budget. '
    'Forward a single TurnResolverConfig instead of re-threading individual '
    'resolver parameters (Refs #3416; '
    'SPEC/program/turn-resume-config-dispatch.md):',
  );
  for (final v in violations) {
    logE(
      ' - ${v.path}:${v.line}: ${v.functionName} declares ${v.paramCount} '
      'named parameters (> $turnResumeMaxNamedParams)',
    );
  }
  return 1;
}

void main() {
  exit(runCheckTurnResumeParamBudget(Directory.current.path));
}

final class TurnResumeParamHit {
  const TurnResumeParamHit({
    required this.path,
    required this.line,
    required this.functionName,
    required this.paramCount,
  });

  final String path;
  final int line;
  final String functionName;
  final int paramCount;
}
