import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3825).
///
/// GP treasury debits in `colonizethis_diplomacy` lib code must route through
/// [debitPlayerTreasury] in `diplomacy_shared_helpers.dart`.
const _diplomacyLibRelative = 'packages/colonizethis_diplomacy/lib';

const _canonicalRelative =
    'packages/colonizethis_diplomacy/lib/src/diplomacy/diplomacy_shared_helpers.dart';

final RegExp _inlineTreasuryDebit = RegExp(r'\.treasury\s*-');

class DiplomacyTreasuryDebitViolation {
  const DiplomacyTreasuryDebitViolation(this.path, this.line);
  final String path;
  final int line;
}

List<DiplomacyTreasuryDebitViolation> findDiplomacyTreasuryDebitViolations({
  required String relativePath,
  required String source,
}) {
  if (relativePath == _canonicalRelative) return const [];

  final violations = <DiplomacyTreasuryDebitViolation>[];
  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.trimLeft().startsWith('//')) continue;
    if (_inlineTreasuryDebit.hasMatch(line)) {
      violations.add(DiplomacyTreasuryDebitViolation(relativePath, i + 1));
    }
  }
  return violations;
}

int runCheckDiplomacyTreasuryDebitShared(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final libDir = Directory(p.join(root, _diplomacyLibRelative));
  if (!libDir.existsSync()) {
    logI('Diplomacy treasury-debit shared check skipped (lib dir absent).');
    return 0;
  }

  final violations = <DiplomacyTreasuryDebitViolation>[];
  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final relativePath = p.relative(entity.path, from: root);
    violations.addAll(
      findDiplomacyTreasuryDebitViolations(
        relativePath: relativePath,
        source: entity.readAsStringSync(),
      ),
    );
  }

  if (violations.isEmpty) {
    logI('Diplomacy treasury-debit shared check passed.');
    return 0;
  }

  logE(
    'ERROR: Found inline `.treasury -` debits outside debitPlayerTreasury. '
    'Route GP treasury mutations through diplomacy_shared_helpers.dart.',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line}');
  }
  return 1;
}

void main() {
  exit(runCheckDiplomacyTreasuryDebitShared(Directory.current.path));
}
