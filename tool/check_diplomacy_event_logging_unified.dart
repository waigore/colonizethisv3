import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3825).
///
/// Resolver modules must route diplomatic history events through
/// [logDiplomaticEvent]; raw [appendDiplomaticEvent] is confined to the
/// canonical definition in `diplomacy_event_logging.dart`.
const _diplomacyLibRelative = 'packages/colonizethis_diplomacy/lib';

const _canonicalRelative =
    'packages/colonizethis_diplomacy/lib/src/diplomacy/diplomacy_event_logging.dart';

const _forbiddenToken = 'appendDiplomaticEvent(';

class DiplomacyEventLoggingViolation {
  const DiplomacyEventLoggingViolation(this.path, this.line);
  final String path;
  final int line;
}

List<DiplomacyEventLoggingViolation> findDiplomacyEventLoggingViolations({
  required String relativePath,
  required String source,
}) {
  if (relativePath == _canonicalRelative) return const [];
  if (!relativePath.contains('/diplomacy/')) return const [];
  if (!relativePath.contains('resolver')) return const [];

  final violations = <DiplomacyEventLoggingViolation>[];
  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.trimLeft().startsWith('//')) continue;
    if (line.contains(_forbiddenToken)) {
      violations.add(DiplomacyEventLoggingViolation(relativePath, i + 1));
    }
  }
  return violations;
}

int runCheckDiplomacyEventLoggingUnified(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final libDir = Directory(p.join(root, _diplomacyLibRelative));
  if (!libDir.existsSync()) {
    logI('Diplomacy event-logging unified check skipped (lib dir absent).');
    return 0;
  }

  final violations = <DiplomacyEventLoggingViolation>[];
  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final relativePath = p.relative(entity.path, from: root);
    violations.addAll(
      findDiplomacyEventLoggingViolations(
        relativePath: relativePath,
        source: entity.readAsStringSync(),
      ),
    );
  }

  if (violations.isEmpty) {
    logI('Diplomacy event-logging unified check passed.');
    return 0;
  }

  logE(
    'ERROR: Found raw appendDiplomaticEvent call sites outside the canonical '
    'diplomacy_event_logging.dart module. Use logDiplomaticEvent in resolvers.',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line}');
  }
  return 1;
}

void main() {
  exit(runCheckDiplomacyEventLoggingUnified(Directory.current.path));
}
