// Victory-config scalar ↔ `victoryConfigParams` registry parity
// (`repo.data_victory_config_registry_parity`).
//
// SPEC: SPEC/ai/ai-parameter-registry.md; SPEC/program/repo-lint.md.
// Refs #4072.
//
// Every `const int` / `const double` `k*` in `ai_victory_config*.dart` must
// appear as a `victoryConfig(Int|Double)Param('k…', …)` entry across the
// topic-split param libraries. Structured Maps / strings stay out of scope.
import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

const String _dataSrcRelDir = 'packages/colonizethis_data/lib/src';

final RegExp _scalarConstPattern = RegExp(r'^const (?:int|double) (k\w+)\s*=');

final RegExp _paramNamePattern = RegExp(
  r"victoryConfig(?:Int|Double)Param\(\s*'(\w+)'",
);

/// Collects in-scope victory-config scalar constant names from source files.
Set<String> victoryConfigScalarConstNamesFromSources(
  Iterable<String> fileContents,
) {
  final names = <String>{};
  for (final content in fileContents) {
    for (final line in content.split('\n')) {
      final match = _scalarConstPattern.firstMatch(line.trimLeft());
      if (match != null) {
        names.add(match.group(1)!);
      }
    }
  }
  return names;
}

/// Collects registered victory-config param names from param library sources.
Set<String> victoryConfigParamNamesFromSources(Iterable<String> fileContents) {
  final names = <String>{};
  for (final content in fileContents) {
    for (final match in _paramNamePattern.allMatches(content)) {
      names.add(match.group(1)!);
    }
  }
  return names;
}

/// Victory-config constant modules that must not register params in the work
/// topic library (`ai_parameter_victory_config_params_work.dart`).
const Set<String> victoryConfigWorkModuleForbiddenSourceFiles = {
  'ai_victory_config_declare_war.dart',
  'ai_victory_config_colonial.dart',
  'ai_victory_config_stalled_ow.dart',
  'ai_victory_config_offer_peace.dart',
};

/// Maps each in-scope victory-config scalar const name to its defining source
/// file basename (e.g. `ai_victory_config_work.dart`).
Map<String, String> victoryConfigScalarConstSourceFiles(
  Map<String, String> fileNameToContent,
) {
  final byName = <String, String>{};
  for (final entry in fileNameToContent.entries) {
    for (final line in entry.value.split('\n')) {
      final match = _scalarConstPattern.firstMatch(line.trimLeft());
      if (match != null) {
        byName[match.group(1)!] = entry.key;
      }
    }
  }
  return byName;
}

/// Returns violations when the work param library registers constants whose
/// defining module is outside civilian work-order scoring.
List<String> victoryConfigWorkModuleConcernViolations({
  required Set<String> workModuleParamNames,
  required Map<String, String> constNameToSourceFile,
}) {
  final violations = <String>[];
  for (final name in workModuleParamNames.toList()..sort()) {
    final sourceFile = constNameToSourceFile[name];
    if (sourceFile == null) {
      continue;
    }
    if (victoryConfigWorkModuleForbiddenSourceFiles.contains(sourceFile)) {
      violations.add(
        'victoryConfigParamsWork registers $name but its const is defined in '
        '$sourceFile (re-home to the matching military / stall-colonial topic '
        'param library)',
      );
    }
  }
  return violations;
}

/// Returns human-readable violation lines, or empty when sets match exactly.
List<String> victoryConfigRegistryParityViolations({
  required Set<String> sourceConsts,
  required Set<String> registeredParams,
}) {
  final missingFromRegistry = sourceConsts.difference(registeredParams).toList()
    ..sort();
  final orphanParams = registeredParams.difference(sourceConsts).toList()
    ..sort();
  final violations = <String>[];
  for (final name in missingFromRegistry) {
    violations.add(
      'const $name has no victoryConfigParams entry '
      '(register via victoryConfigIntParam / victoryConfigDoubleParam)',
    );
  }
  for (final name in orphanParams) {
    violations.add(
      'victoryConfigParams entry $name has no matching '
      'const int/double k* in ai_victory_config*.dart',
    );
  }
  return violations;
}

bool _isVictoryConfigSourceFile(String fileName) =>
    fileName == 'ai_victory_config.dart' ||
    (fileName.startsWith('ai_victory_config_') && fileName.endsWith('.dart'));

bool _isVictoryConfigParamsFile(String fileName) =>
    fileName == 'ai_parameter_victory_config_params.dart' ||
    (fileName.startsWith('ai_parameter_victory_config_params_') &&
        fileName.endsWith('.dart'));

List<File> _listMatchingSrcFiles(
  String repoRoot,
  bool Function(String fileName) predicate,
) {
  final dir = Directory(p.join(repoRoot, _dataSrcRelDir));
  if (!dir.existsSync()) {
    return const <File>[];
  }
  final files =
      dir
          .listSync(followLinks: false)
          .whereType<File>()
          .where((f) => predicate(p.basename(f.path)))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  return files;
}

int runCheckDataVictoryConfigRegistryParity(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final srcDir = Directory(p.join(repoRoot, _dataSrcRelDir));
  if (!srcDir.existsSync()) {
    logE(
      'check_data_victory_config_registry_parity: $_dataSrcRelDir not found.',
    );
    return 1;
  }

  final configFiles = _listMatchingSrcFiles(
    repoRoot,
    _isVictoryConfigSourceFile,
  );
  final paramFiles = _listMatchingSrcFiles(
    repoRoot,
    _isVictoryConfigParamsFile,
  );
  if (configFiles.isEmpty) {
    logE(
      'check_data_victory_config_registry_parity: no ai_victory_config*.dart '
      'files under $_dataSrcRelDir.',
    );
    return 1;
  }
  if (paramFiles.isEmpty) {
    logE(
      'check_data_victory_config_registry_parity: no '
      'ai_parameter_victory_config_params*.dart files under $_dataSrcRelDir.',
    );
    return 1;
  }

  final configContents = <String, String>{
    for (final f in configFiles) p.basename(f.path): f.readAsStringSync(),
  };
  final paramContents = <String, String>{
    for (final f in paramFiles) p.basename(f.path): f.readAsStringSync(),
  };

  final sourceConsts = victoryConfigScalarConstNamesFromSources(
    configContents.values,
  );
  final registeredParams = victoryConfigParamNamesFromSources(
    paramContents.values,
  );
  final constNameToSourceFile = victoryConfigScalarConstSourceFiles(
    configContents,
  );
  final workModuleParamNames = victoryConfigParamNamesFromSources([
    paramContents['ai_parameter_victory_config_params_work.dart'] ?? '',
  ]);

  final violations = <String>[
    ...victoryConfigRegistryParityViolations(
      sourceConsts: sourceConsts,
      registeredParams: registeredParams,
    ),
    ...victoryConfigWorkModuleConcernViolations(
      workModuleParamNames: workModuleParamNames,
      constNameToSourceFile: constNameToSourceFile,
    ),
  ];

  if (violations.isEmpty) {
    logI(
      'check_data_victory_config_registry_parity: '
      '${sourceConsts.length} scalars match victoryConfigParams.',
    );
    return 0;
  }

  logE(
    'check_data_victory_config_registry_parity: found '
    '${violations.length} parity violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main(List<String> args) {
  // Full-tree rule: incremental file args do not narrow the scan (parity is
  // set-wide across all victory-config modules).
  repoLintStrictIncrementalFilesArgListOrExit(args);
  exit(runCheckDataVictoryConfigRegistryParity(Directory.current.path));
}
