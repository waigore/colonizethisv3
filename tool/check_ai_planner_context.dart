import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #2521).
///
/// Flags top-level planner functions under `colonizethis_ai/lib/src/planning/`
/// that still take more than six parameters instead of [PlannerContext].

const _aiPlanningRelative = 'packages/colonizethis_ai/lib/src/planning';

const _plannerFunctionNames = <String>{
  'runMovePlanner',
  'runArmyMovePlanner',
  'runNavalPlanner',
  'runResearchPlanner',
  'runDiplomacyPlanner',
  'runDiplomacyPlannerWithResult',
  'runConquestArmyMovePlanner',
  '_runEconomyDomainPlanners',
  'pickBuildOrder',
};

void main(List<String> args) {
  exit(runCheckAiPlannerContext(Directory.current.path));
}

int runCheckAiPlannerContext(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final root = p.normalize(repoRoot);
  final planningDir = Directory(p.join(root, _aiPlanningRelative));
  if (!planningDir.existsSync()) {
    logE('ERROR: Missing AI planning directory: $_aiPlanningRelative');
    return 1;
  }

  final violations = <String>[];
  for (final entity in planningDir.listSync(recursive: false, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final relative = p.relative(entity.path, from: root);
    final content = entity.readAsStringSync();
    final parseResult = parseString(path: relative, content: content);
    final lineInfo = parseResult.lineInfo;
    for (final decl in parseResult.unit.declarations) {
      if (decl is! FunctionDeclaration) continue;
      final name = decl.name.lexeme;
      if (!_plannerFunctionNames.contains(name)) continue;
      final params = decl.functionExpression.parameters;
      if (params == null) continue;
      final count = params.parameters.length;
      if (count > 6) {
        final line = lineInfo?.getLocation(decl.name.offset).lineNumber ?? 0;
        violations.add('$relative:$line:$name has $count parameters');
      }
    }
  }

  if (violations.isEmpty) {
    logI('check_ai_planner_context: no violations found.');
    return 0;
  }

  logE(
    'check_ai_planner_context: found ${violations.length} planner function(s) '
    'with >6 parameters. Use PlannerContext instead.',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  return 1;
}
