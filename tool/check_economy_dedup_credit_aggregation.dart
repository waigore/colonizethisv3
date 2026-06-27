import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3731).
///
/// Guards the deduplicated per-owning-Great-Power treasury-credit aggregation
/// in the economy package. The shared
/// `GpTreasuryCreditAccumulator<T extends num>`
/// (`world_market/gp_treasury_credit_accumulator.dart`) is the single canonical
/// home of the insertion-ordered `byGp` roll-up; it was extracted to remove the
/// two independent inline `byGp[gp] = (byGp[gp] ?? 0) + delta` loops that
/// `first_right_credits.dart` (`double` credits) and `purchased_tile_riches.dart`
/// (`int` credits) previously re-implemented.
///
/// This rule fails when either of those two files:
///   1. re-introduces the inline per-GP accumulation
///      (`<map>[<key>] = (<map>[<key>] ?? 0) + ...`, `?? 0.0` variant included),
///      tolerant of whitespace and a single line break so reformatting cannot
///      defeat the gate, or
///   2. no longer references the shared `GpTreasuryCreditAccumulator` (which
///      would mean the helper was abandoned for a bespoke roll-up).
///
/// Detection is path-scoped to exactly the two files (one concern, fast). The
/// Theme A `(map[..] ?? 0) +` micro-idiom is deliberately **not** gated here:
/// a blanket ban is false-positive-prone and low-value, so `dart analyze`, the
/// `commodity_totals.dart` unit tests, and code review cover it instead.
const _economyLibDir = 'packages/colonizethis_economy/lib';

/// The two world-market result helpers required to delegate to the shared
/// accumulator, relative to the repo root.
const _targetRelativePaths = <String>[
  'packages/colonizethis_economy/lib/src/economy/world_market/first_right_credits.dart',
  'packages/colonizethis_economy/lib/src/economy/world_market/purchased_tile_riches.dart',
];

/// Symbol every target file must reference (the shared accumulator type).
const _requiredSymbol = 'GpTreasuryCreditAccumulator';

/// Matches the inline per-GP accumulation `<x>[<k>] = (<x>[<k>] ?? 0) + …`,
/// tolerant of whitespace and a single newline (`[\s\S]{0,40}?`) so the
/// original two-line split form is still detected. The `0` / `0.0` zero literal
/// keeps the pattern specific to a zero-seeded running-total loop.
final RegExp _bannedInlineAccumulation = RegExp(
  r'\[[^\]]+\]\s*=\s*\([\s\S]{0,40}?\[[^\]]+\]\s*\?\?\s*0(?:\.0)?\s*\)\s*\+',
);

void main() {
  exit(runCheckEconomyDedupCreditAggregation(Directory.current.path));
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckEconomyDedupCreditAggregation(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final dir = Directory(p.join(root, _economyLibDir));
  if (!dir.existsSync()) {
    logI('Economy dedup credit-aggregation check skipped (economy lib absent).');
    return 0;
  }

  final sourcesByPath = <String, String>{};
  for (final relative in _targetRelativePaths) {
    final file = File(p.join(root, relative));
    if (file.existsSync()) {
      sourcesByPath[relative] = file.readAsStringSync();
    }
  }

  final violations = findEconomyDedupCreditAggregationViolations(
    sourcesByPath: sourcesByPath,
  );

  if (violations.isEmpty) {
    logI('Economy dedup credit-aggregation check passed.');
    return 0;
  }

  logE(
    'ERROR: economy per-GP treasury-credit aggregation must use the shared '
    'GpTreasuryCreditAccumulator from '
    'world_market/gp_treasury_credit_accumulator.dart instead of an inline '
    'byGp[gp] = (byGp[gp] ?? 0) + delta loop (Refs #3731).',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

/// Scans [sourcesByPath] (relative path -> source) for the two violation
/// classes: a re-inlined per-GP accumulation loop, or a missing reference to
/// the shared [_requiredSymbol]. Only the [_targetRelativePaths] entries that
/// are present in [sourcesByPath] are checked.
List<EconomyDedupCreditAggregationViolation>
findEconomyDedupCreditAggregationViolations({
  required Map<String, String> sourcesByPath,
}) {
  final violations = <EconomyDedupCreditAggregationViolation>[];
  for (final relative in _targetRelativePaths) {
    final content = sourcesByPath[relative];
    if (content == null) continue;

    final match = _bannedInlineAccumulation.firstMatch(content);
    if (match != null) {
      final lineNumber =
          '\n'.allMatches(content.substring(0, match.start)).length + 1;
      violations.add(
        EconomyDedupCreditAggregationViolation(
          path: relative,
          line: lineNumber,
          message:
              'Re-inlined per-GP accumulation; use '
              'GpTreasuryCreditAccumulator.add/ensure instead.',
        ),
      );
    }

    if (!content.contains(_requiredSymbol)) {
      violations.add(
        EconomyDedupCreditAggregationViolation(
          path: relative,
          line: 1,
          message:
              'Missing reference to shared $_requiredSymbol; the per-GP '
              'treasury roll-up must delegate to it.',
        ),
      );
    }
  }
  return violations;
}

class EconomyDedupCreditAggregationViolation {
  const EconomyDedupCreditAggregationViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
