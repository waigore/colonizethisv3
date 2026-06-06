// Refs #3288 — guards `repo.ai_no_repeated_production_recipes_catalog_scan`.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_no_repeated_production_recipes_catalog_scan.dart';

const _treasuryPlannerRelative =
    'packages/colonizethis_ai/lib/src/planning/treasury_planner.dart';

File _writeTreasuryPlanner(Directory root, String body) {
  final dir = Directory(
    p.join(root.path, 'packages/colonizethis_ai/lib/src/planning'),
  )..createSync(recursive: true);
  final file = File(p.join(dir.path, 'treasury_planner.dart'))
    ..writeAsStringSync(body);
  return file;
}

void main() {
  group('repo.ai_no_repeated_production_recipes_catalog_scan', () {
    test('passes on real repo workspace', () {
      final repoRoot = Directory.current.path;
      final logs = <String>[];
      final code = runCheckAiNoRepeatedProductionRecipesCatalogScan(
        repoRoot,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
      expect(
        logs.join('\n'),
        contains(
          'check_ai_no_repeated_production_recipes_catalog_scan: '
          'no violations found.',
        ),
      );
    });

    test('fails when treasury_planner iterates ProductionRecipesCatalog.all',
        () {
      final temp = Directory.systemTemp.createTempSync('ai_recipe_scan_fail_');
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeTreasuryPlanner(
        temp,
        'void f(String commodityId) {\n'
        '  for (final recipe in ProductionRecipesCatalog.all) {\n'
        '    if (recipe.outputCommodityId != commodityId) continue;\n'
        '  }\n'
        '}\n',
      );

      final errLogs = <String>[];
      final code = runCheckAiNoRepeatedProductionRecipesCatalogScan(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );

      expect(code, 1);
      expect(errLogs.join('\n'), contains(_treasuryPlannerRelative));
      expect(
        errLogs.join('\n'),
        contains('ProductionRecipesCatalog.producing'),
      );
    });

    test('passes when treasury_planner uses ProductionRecipesCatalog.producing',
        () {
      final temp = Directory.systemTemp.createTempSync('ai_recipe_scan_pass_');
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeTreasuryPlanner(
        temp,
        'void f(String commodityId) {\n'
        '  for (final recipe in ProductionRecipesCatalog.producing(\n'
        '    commodityId,\n'
        '  )) {}\n'
        '}\n',
      );

      final code = runCheckAiNoRepeatedProductionRecipesCatalogScan(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });

    test('ignores ProductionRecipesCatalog.all outside treasury_planner', () {
      final temp = Directory.systemTemp.createTempSync('ai_recipe_scan_scope_');
      addTearDown(() => temp.deleteSync(recursive: true));

      // treasury_planner clean; another planning file uses .all legitimately.
      _writeTreasuryPlanner(temp, 'void f() {}\n');
      final planningDir = Directory(
        p.join(temp.path, 'packages/colonizethis_ai/lib/src/planning'),
      );
      File(p.join(planningDir.path, 'economy_planner.dart')).writeAsStringSync(
        'void g() {\n'
        '  final recipes = ProductionRecipesCatalog.all;\n'
        '}\n',
      );

      final code = runCheckAiNoRepeatedProductionRecipesCatalogScan(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });

    test('errors when treasury_planner source is missing', () {
      final temp = Directory.systemTemp.createTempSync('ai_recipe_scan_miss_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final errLogs = <String>[];
      final code = runCheckAiNoRepeatedProductionRecipesCatalogScan(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );
      expect(code, 1);
      expect(errLogs.join('\n'), contains(_treasuryPlannerRelative));
    });
  });
}
