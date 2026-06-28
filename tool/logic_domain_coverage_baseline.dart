// Per-domain line coverage baseline for colonizethis_logic (Refs #3290 Phase 0).
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const _logicSrcRelative = 'packages/colonizethis_logic/lib/src';
const _lcovRelative = 'packages/colonizethis_logic/coverage/lcov.info';
const _outputRelative = 'tool/logic_domain_coverage_baseline.json';

const _trackedDomains = <String>[
  'ai',
  'combat',
  'debug_console',
  'diplomacy',
  'dossier',
  'economy',
  'event_bus',
  'orders',
  'setup',
  'turn',
  'utils',
  'world',
];

void main(List<String> args) {
  exit(runLogicDomainCoverageBaseline(Directory.current.path, args: args));
}

int runLogicDomainCoverageBaseline(
  String repoRoot, {
  List<String> args = const [],
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final lcovPath = p.join(repoRoot, _lcovRelative);
  if (!File(lcovPath).existsSync()) {
    logE(
      'logic_domain_coverage_baseline: missing $_lcovRelative — '
      'run tool/test_coverage.py for colonizethis_logic first.',
    );
    return 1;
  }

  final domainHits = <String, int>{
    for (final d in _trackedDomains) d: 0,
  };
  final domainLines = <String, int>{
    for (final d in _trackedDomains) d: 0,
  };
  var unclassifiedHits = 0;
  var unclassifiedLines = 0;

  String? currentFile;
  for (final rawLine in File(lcovPath).readAsLinesSync()) {
    if (rawLine.startsWith('SF:')) {
      currentFile = rawLine.substring(3);
      continue;
    }
    if (currentFile == null || !rawLine.startsWith('DA:')) continue;
    final payload = rawLine.substring(3);
    final comma = payload.lastIndexOf(',');
    if (comma < 0) continue;
    final lineNo = int.tryParse(payload.substring(0, comma));
    final hitCount = int.tryParse(payload.substring(comma + 1));
    if (lineNo == null || hitCount == null) continue;

    final domain = _domainForLcovFile(currentFile, repoRoot);
    if (domain == null) {
      unclassifiedLines++;
      if (hitCount > 0) unclassifiedHits++;
      continue;
    }
    domainLines[domain] = domainLines[domain]! + 1;
    if (hitCount > 0) domainHits[domain] = domainHits[domain]! + 1;
  }

  final domains = <Map<String, Object>>[];
  for (final domain in _trackedDomains) {
    final lines = domainLines[domain] ?? 0;
    final hits = domainHits[domain] ?? 0;
    final pct = lines == 0 ? 0.0 : (hits * 100.0 / lines);
    domains.add({
      'domain': domain,
      'lineHits': hits,
      'lineTotal': lines,
      'lineCoveragePercent': double.parse(pct.toStringAsFixed(2)),
      'belowNinetyPercent': pct < 90.0,
    });
  }

  final output = <String, Object>{
    'package': 'colonizethis_logic',
    'lcovSource': _lcovRelative,
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'unclassified': {
      'lineHits': unclassifiedHits,
      'lineTotal': unclassifiedLines,
    },
    'domains': domains,
  };

  final write = !args.contains('--check-only');
  if (write) {
    File(p.join(repoRoot, _outputRelative)).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(output),
    );
    logI('logic_domain_coverage_baseline: wrote $_outputRelative');
  }

  final below = domains.where((d) => d['belowNinetyPercent'] == true).toList();
  if (below.isNotEmpty) {
    logI(
      'logic_domain_coverage_baseline: ${below.length} domain(s) below 90% '
      '(recorded for Phase 1+ test planning).',
    );
  }
  return 0;
}

String? _domainForLcovFile(String lcovFile, String repoRoot) {
  final normalized = p.normalize(lcovFile);
  final marker = '${p.separator}lib${p.separator}src${p.separator}';
  final idx = normalized.indexOf(marker);
  if (idx < 0) return null;
  final remainder = normalized.substring(idx + marker.length);
  final domain = remainder.split(p.separator).first;
  if (_trackedDomains.contains(domain)) return domain;
  return null;
}
