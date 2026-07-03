import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3822).
///
/// Forbids direct `CommodityCatalog.fabric.id`, `CommodityCatalog.castIron.id`,
/// and `CommodityCatalog.lumber.id` references under
/// `packages/colonizethis_ai/lib/**` outside the canonical holder
/// `ai_commodity_ids.dart`. Planner code MUST use `kAiCommodityIds` instead.

const _aiLibRelative = 'packages/colonizethis_ai/lib';

const _allowedRelative =
    'packages/colonizethis_ai/lib/src/planning/ai_commodity_ids.dart';

const _forbiddenTokens = <String>[
  'CommodityCatalog.fabric.id',
  'CommodityCatalog.castIron.id',
  'CommodityCatalog.lumber.id',
];

void main(List<String> args) {
  exit(runCheckAiDedupCommodityIds(Directory.current.path));
}

int runCheckAiDedupCommodityIds(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final root = p.normalize(repoRoot);
  final libDir = Directory(p.join(root, _aiLibRelative));
  if (!libDir.existsSync()) {
    logE('ERROR: Missing colonizethis_ai lib directory: $_aiLibRelative');
    return 1;
  }

  final allowedPath = p.normalize(p.join(root, _allowedRelative));
  final violations = <String>[];
  for (final entity in libDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (p.normalize(entity.path) == allowedPath) continue;
    final relative = p.relative(entity.path, from: root);
    final content = entity.readAsStringSync();
    for (final token in _forbiddenTokens) {
      var searchFrom = 0;
      while (true) {
        final index = content.indexOf(token, searchFrom);
        if (index < 0) break;
        final lineNumber =
            '\n'.allMatches(content.substring(0, index)).length + 1;
        violations.add('$relative:$lineNumber ($token)');
        searchFrom = index + token.length;
      }
    }
  }

  if (violations.isEmpty) {
    logI('check_ai_dedup_commodity_ids: no violations found.');
    return 0;
  }

  logE(
    'check_ai_dedup_commodity_ids: found ${violations.length} direct '
    'CommodityCatalog fabric/castIron/lumber id reference(s) in '
    '$_aiLibRelative. Use kAiCommodityIds from ai_commodity_ids.dart instead.',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  return 1;
}
