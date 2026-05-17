import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #2521, AC12).
///
/// Flags top-level domain planner entrypoints under
/// `packages/colonizethis_ai/lib/src/planning/` with more than six parameters,
/// signalling failure to bundle shared inputs in [PlannerContext].
const _planningSrcRelative = 'packages/colonizethis_ai/lib/src/planning';

const _plannerEntrypointNames = <String>{
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

const _maxParameters = 6;

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
  final planningDir = Directory(p.join(root, _planningSrcRelative));
  if (!planningDir.existsSync()) {
    logE('ERROR: Missing AI planning directory: $_planningSrcRelative');
    return 1;
  }

  final violations = <String>[];
  for (final entity in planningDir.listSync(recursive: false, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (p.basename(entity.path) == 'planning_imports.dart') continue;
    final relative = p.relative(entity.path, from: root);
    final content = entity.readAsStringSync();
    final parsed = parseString(content: content, path: relative);
    for (final decl in parsed.unit.declarations) {
      if (decl is! FunctionDeclaration) continue;
      final name = decl.name.lexeme;
      if (!_plannerEntrypointNames.contains(name)) continue;
      final paramCount = _parameterCount(decl.functionExpression.parameters);
      if (paramCount > _maxParameters) {
        final line = decl.name.offset;
        final lineNumber =
            '\n'.allMatches(content.substring(0, line)).length + 1;
        violations.add(
          '$relative:$lineNumber $name has $paramCount parameters '
          '(max $_maxParameters; use PlannerContext)',
        );
      }
    }
  }

  if (violations.isEmpty) {
    logI('check_ai_planner_context: no violations found.');
    return 0;
  }

  logE(
    'check_ai_planner_context: found ${violations.length} planner entrypoint(s) '
    'with more than $_maxParameters parameters. Bundle shared inputs in '
    'PlannerContext instead.',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  return 1;
}

int _parameterCount(FormalParameterList? parameters) {
  if (parameters == null) return 0;
  return parameters.parameters.length;
}
