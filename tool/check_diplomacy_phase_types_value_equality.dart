import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix for the Diplomacy-phase value-type files whose
/// equality must derive from the shared `ValueEquality` mixin rather than
/// hand-written `operator ==` / `hashCode` pairs (Refs #3715).
const String _phaseTypesPathPrefix =
    'packages/colonizethis_diplomacy/lib/src/diplomacy/phase_types/';

/// The canonical mixin file that legitimately declares `operator ==`; it is the
/// single source of truth the value types delegate to and is exempt from the
/// no-hand-written-equality rule.
const String diplomacyValueEqualityMixinFileName = 'value_equality.dart';

/// Canonical mixin the value types must mix in instead of re-implementing
/// `operator ==` / `hashCode`.
const String diplomacyValueEqualityMixinName = 'ValueEquality';

/// Matches a hand-written `operator ==` declaration (any spacing).
final RegExp _operatorEqualsDeclaration = RegExp(r'operator\s*==\s*\(');

/// True when the repo-relative [slashPath] is a phase-types value-type file
/// subject to this gate (under the phase_types dir, a `.dart` source, and not
/// the canonical `value_equality.dart` mixin itself).
bool diplomacyPhaseTypesValueEqualityPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith(_phaseTypesPathPrefix)) {
    return false;
  }
  if (!normalized.endsWith('.dart')) {
    return false;
  }
  return p.basename(normalized) != diplomacyValueEqualityMixinFileName;
}

/// Returns a violation reason when a phase-types value-type file [content]
/// re-implements `operator ==` instead of mixing in [ValueEquality], or `null`
/// when compliant.
String? diplomacyPhaseTypesValueEqualityViolationReason(String content) {
  if (_operatorEqualsDeclaration.hasMatch(content)) {
    return 'hand-writes `operator ==`; mix in '
        '`$diplomacyValueEqualityMixinName` and expose `equalityFields` '
        'instead (Refs #3715)';
  }
  return null;
}

int runCheckDiplomacyPhaseTypesValueEquality(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!diplomacyPhaseTypesValueEqualityPathInScope(rel)) {
      continue;
    }
    final reason = diplomacyPhaseTypesValueEqualityViolationReason(
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_diplomacy_phase_types_value_equality: no hand-written '
      'value-type equality violations.',
    );
    return 0;
  }
  logE(
    'check_diplomacy_phase_types_value_equality: ${violations.length} '
    'violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckDiplomacyPhaseTypesValueEquality(Directory.current.path));
}
