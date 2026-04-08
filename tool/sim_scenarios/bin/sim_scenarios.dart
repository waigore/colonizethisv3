// sim_scenarios - Batch scenario test driver for game integration testing.
//
// Usage:
//   dart run sim_scenarios                          # Run all scenarios in default directory
//   dart run sim_scenarios --scenario=path.json     # Run specific scenario
//   dart run sim_scenarios --directory=path/to/scenarios  # Run all in directory

import 'dart:io';

import 'package:args/args.dart';
import 'package:sim_scenarios/package_logger.dart';
import 'package:path/path.dart' as path;

import 'package:sim_scenarios/scenario.dart';
import 'package:sim_scenarios/scenario_runner.dart';

final _log = packageLogger('sim_scenarios');

void main(List<String> args) async {
  final parser = ArgParser();
  parser.addOption(
    'scenario',
    abbr: 's',
    help: 'Path to a specific scenario JSON file',
  );
  parser.addOption(
    'directory',
    abbr: 'd',
    help: 'Directory containing scenario JSON files',
  );
  parser.addFlag(
    'verbose',
    abbr: 'v',
    help: 'Enable verbose output',
  );
  parser.addFlag(
    'generate-assertions',
    abbr: 'g',
    help: 'Generate assertions from current state (for writing new scenarios)',
  );
  parser.addFlag(
    'help',
    abbr: 'h',
    help: 'Show this help message',
  );

  final results = parser.parse(args);

  if (results['help'] == true) {
    _log.i('sim_scenarios - Batch scenario test driver');
    _log.i('');
    _log.i('Usage:');
    _log.i('  dart run sim_scenarios                          # Run all scenarios');
    _log.i('  dart run sim_scenarios --scenario=path.json     # Run specific scenario');
    _log.i('  dart run sim_scenarios --directory=path         # Run from directory');
    _log.i('  dart run sim_scenarios --verbose                # Verbose output');
    _log.i('');
    _log.i(parser.usage);
    return;
  }

  final verbose = results['verbose'] == true;
  final scenarioPath = results['scenario'] as String?;
  
  // Default to tool/sim_scenarios/scenarios/ relative to current working directory
  // or use explicit --directory flag
  String directory;
  if (results['directory'] != null) {
    directory = results['directory'] as String;
  } else if (scenarioPath == null) {
    // Default scenarios directory - check if we're already in the tool directory
    final cwd = Directory.current.path;
    if (cwd.endsWith('tool/sim_scenarios') || cwd.endsWith('tool\\sim_scenarios')) {
      directory = path.join(cwd, 'scenarios');
    } else if (cwd.endsWith('sim_scenarios')) {
      directory = path.join(cwd, 'scenarios');
    } else {
      // Default scenarios directory relative to project root
      directory = path.join(cwd, 'tool', 'sim_scenarios', 'scenarios');
    }
  } else {
    directory = '';
  }

  final runner = ScenarioRunner();

  if (scenarioPath != null) {
    // Run single scenario
    final file = File(scenarioPath);
    if (!file.existsSync()) {
      _log.e('Error: Scenario file not found: $scenarioPath');
      exit(1);
    }
    if (verbose) {
      _log.i('Running scenario: $scenarioPath');
    }
    final result = await runner.runFile(file);
    final report = formatScenarioReport(result);
    _log.i('run report\n$report');
    print(report);
    exit(result.passed ? 0 : 1);
  } else {
    // Run all scenarios in directory
    final dir = Directory(directory);
    if (!dir.existsSync()) {
      _log.e('Error: Directory not found: $directory');
      exit(1);
    }
    if (verbose) {
      _log.i('Running all scenarios in: $directory');
    }
    final batchResult = await runner.runAll(dir);
    final report = formatBatchReport(batchResult);
    _log.i('run report\n$report');
    print(report);
    exit(batchResult.failed > 0 ? 1 : 0);
  }
}

/// Formats a batch result as markdown.
String formatBatchReport(BatchResult batch) {
  final buffer = StringBuffer();
  
  buffer.writeln('# Scenario Test Results');
  buffer.writeln();
  buffer.writeln('**Run:** ${batch.runTime.toIso8601String()}');
  buffer.writeln('**Total:** ${batch.total} scenarios');
  buffer.writeln('**Passed:** ${batch.passed}');
  buffer.writeln('**Failed:** ${batch.failed}');
  buffer.writeln();
  buffer.writeln('---');
  buffer.writeln();
  
  for (final result in batch.results) {
    buffer.write(formatScenarioReport(result));
    buffer.writeln();
  }
  
  // Summary table
  buffer.writeln('## Summary');
  buffer.writeln();
  buffer.writeln('| Scenario | Status |');
  buffer.writeln('|----------|--------|');
  for (final result in batch.results) {
    final status = result.passed ? '✅ PASSED' : '❌ FAILED';
    buffer.writeln('| ${result.scenarioName} | $status |');
  }
  
  return buffer.toString();
}

/// Formats a single scenario result as markdown.
String formatScenarioReport(ScenarioResult result) {
  final buffer = StringBuffer();
  
  final title = result.passed ? '✅ ${result.scenarioName}' : '❌ ${result.scenarioName}';
  buffer.writeln('## $title');
  buffer.writeln();
  
  if (result.turnResults.isNotEmpty) {
    buffer.writeln('| Turn | Check | Result |');
    buffer.writeln('|------|-------|--------|');
    
    for (final entry in result.turnResults.entries) {
      for (final ar in entry.value.assertionResults) {
        final check = _formatAssertion(ar.assertion);
        final resultIcon = ar.passed ? '✅' : '❌';
        buffer.writeln('| ${entry.key} | $check | $resultIcon |');
      }
    }
    buffer.writeln();
  }
  
  buffer.writeln('**Status:** ${result.passed ? "PASSED" : "FAILED"}');
  
  if (!result.passed && result.failures.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('**Failures:**');
    for (final failure in result.failures) {
      buffer.writeln('- $failure');
    }
  }
  
  return buffer.toString();
}

String _formatAssertion(Assertion assertion) {
  if (assertion.province != null) {
    if (assertion.owner != null) {
      return 'province.${assertion.province}.owner == ${assertion.owner}';
    }
    if (assertion.notOwner != null) {
      return 'province.${assertion.province}.owner != ${assertion.notOwner}';
    }
    if (assertion.unitCount != null) {
      final matchStr = assertion.matchType == MatchType.exact 
          ? '== ${assertion.unitCount}'
          : assertion.matchType == MatchType.atLeast
              ? '>= ${assertion.unitCount}'
              : assertion.matchType == MatchType.atMost
                  ? '<= ${assertion.unitCount}'
                  : '';
      return 'province.${assertion.province}.unitCount $matchStr';
    }
    if (assertion.hasPlayerUnits != null) {
      return 'province.${assertion.province}.hasPlayerUnits == ${assertion.hasPlayerUnits}';
    }
    return 'province.${assertion.province}';
  }
  if (assertion.stockpile != null) {
    return 'stockpile ${assertion.stockpile}';
  }
  if (assertion.workerPeasants != null) {
    return 'player.${assertion.player}.workerPeasants == ${assertion.workerPeasants}';
  }
  if (assertion.commodity != null && assertion.stockpileCommodity != null) {
    return 'player.${assertion.player}.stockpile.${assertion.commodity} == ${assertion.stockpileCommodity}';
  }
  if (assertion.treasury != null) {
    return 'treasury ${assertion.treasury}';
  }
  // Resource-placement assertions (SPEC/game/resource-terrain-region-rules.md)
  if (assertion.region != null && assertion.resource != null &&
      assertion.province == null && assertion.player == null) {
    return 'region.${assertion.region}.hasNoResource.${assertion.resource}';
  }
  if (assertion.everyTileResourceAllowedInRegion == true) {
    return assertion.region != null
        ? 'everyTileResourceAllowedInRegion(region=${assertion.region})'
        : 'everyTileResourceAllowedInRegion';
  }
  if (assertion.region != null && assertion.maxBothFraction != null) {
    return 'region.${assertion.region}.maxBothFraction <= ${assertion.maxBothFraction}';
  }
  // Fog/exploration (SPEC/game/fog-and-exploration.md)
  if (assertion.player != null && assertion.tileKey != null) {
    if (assertion.tileVisibility != null) {
      return 'player.${assertion.player}.tile.${assertion.tileKey}.visibility == ${assertion.tileVisibility}';
    }
    if (assertion.tileProspected != null) {
      return 'player.${assertion.player}.tile.${assertion.tileKey}.prospected == ${assertion.tileProspected}';
    }
  }
  // Leader (SPEC/game/leader-bonuses.md)
  if (assertion.player != null && assertion.leaderKey != null) {
    return 'player.${assertion.player}.leaderKey == ${assertion.leaderKey}';
  }
  // Research-state (SPEC/game/research-state.md)
  if (assertion.player != null &&
      assertion.techUnlocked != null &&
      assertion.techUnlocked!.isNotEmpty) {
    return 'player.${assertion.player}.techUnlocked == [${assertion.techUnlocked!.join(", ")}]';
  }
  return 'unknown';
}
