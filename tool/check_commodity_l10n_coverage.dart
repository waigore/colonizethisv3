import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/localization.md, SPEC/program/repo-lint.md (Refs #3987).
///
/// Fails when any commodity id declared in
/// `packages/colonizethis_data/lib/src/commodities.dart` lacks a matching
/// `commodity_<catalogId>` key in `app_en.arb` (raw camelCase catalog id).

const _arbRelative = 'packages/colonizethis_app_l10n/lib/l10n/arb/app_en.arb';
const _catalogRelative =
    'packages/colonizethis_data/lib/src/commodities.dart';

final _commodityIdLiteral = RegExp(r"id:\s*'([^']+)'");

void main() {
  exit(runCheckCommodityL10nCoverage(Directory.current.path));
}

List<String> catalogCommodityIdsFromSource(String source) {
  return _commodityIdLiteral
      .allMatches(source)
      .map((m) => m.group(1)!)
      .toList(growable: false);
}

int runCheckCommodityL10nCoverage(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final catalogPath = p.join(repoRoot, _catalogRelative);
  final catalogFile = File(catalogPath);
  if (!catalogFile.existsSync()) {
    logE('check_commodity_l10n_coverage: missing catalog at $_catalogRelative');
    return 1;
  }

  final arbPath = p.join(repoRoot, _arbRelative);
  final arbFile = File(arbPath);
  if (!arbFile.existsSync()) {
    logE('check_commodity_l10n_coverage: missing ARB at $_arbRelative');
    return 1;
  }

  final decoded = jsonDecode(arbFile.readAsStringSync());
  if (decoded is! Map) {
    logE('check_commodity_l10n_coverage: ARB root is not a JSON object');
    return 1;
  }
  final keys = decoded.keys.whereType<String>().toSet();
  final catalogIds = catalogCommodityIdsFromSource(catalogFile.readAsStringSync());
  if (catalogIds.isEmpty) {
    logE(
      'check_commodity_l10n_coverage: no commodity ids parsed from '
      '$_catalogRelative',
    );
    return 1;
  }

  final missing = <String>[];
  for (final id in catalogIds) {
    final key = 'commodity_$id';
    if (!keys.contains(key)) {
      missing.add(key);
    }
  }

  if (missing.isEmpty) {
    logI(
      'check_commodity_l10n_coverage: all ${catalogIds.length} catalog '
      'commodities have ARB keys.',
    );
    return 0;
  }

  logE(
    'check_commodity_l10n_coverage: ${missing.length} missing '
    'commodity_<catalogId> key(s) in $_arbRelative:',
  );
  for (final key in missing) {
    logE(' - $key');
  }
  return 1;
}
