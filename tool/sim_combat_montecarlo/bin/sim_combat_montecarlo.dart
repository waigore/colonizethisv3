// ignore_for_file: avoid_print
/// CLI: Monte Carlo combat simulation. Runs many trials, aggregates results.
/// SPEC/program/sim-combat-montecarlo.md.
import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main(List<String> arguments) {
  String? scriptPath;
  int trials = 1000;
  int? seed;
  String? outputPath;
  String? jsonOutputPath;

  for (var i = 0; i < arguments.length; i++) {
    final arg = arguments[i];
    if (arg == '--help' || arg == '-h') {
      _printUsage();
      exit(0);
    } else if (arg == '--script' && i + 1 < arguments.length) {
      scriptPath = arguments[++i];
    } else if (arg.startsWith('--script=')) {
      scriptPath = arg.substring('--script='.length).trim();
    } else if (arg == '--trials' && i + 1 < arguments.length) {
      final v = int.tryParse(arguments[++i]);
      if (v == null || v < 1) {
        print('Error: --trials must be a positive integer');
        exit(1);
      }
      trials = v;
    } else if (arg.startsWith('--trials=')) {
      final v = int.tryParse(arg.substring('--trials='.length).trim());
      if (v == null || v < 1) {
        print('Error: --trials must be a positive integer');
        exit(1);
      }
      trials = v;
    } else if (arg == '--seed' && i + 1 < arguments.length) {
      final v = int.tryParse(arguments[++i]);
      if (v == null) {
        print('Error: --seed requires an integer');
        exit(1);
      }
      seed = v;
    } else if (arg.startsWith('--seed=')) {
      final v = int.tryParse(arg.substring('--seed='.length).trim());
      if (v == null) {
        print('Error: --seed requires an integer');
        exit(1);
      }
      seed = v;
    } else if (arg == '--output' && i + 1 < arguments.length) {
      outputPath = arguments[++i];
    } else if (arg.startsWith('--output=')) {
      outputPath = arg.substring('--output='.length).trim();
    } else if (arg == '--json-output' && i + 1 < arguments.length) {
      jsonOutputPath = arguments[++i];
    } else if (arg.startsWith('--json-output=')) {
      jsonOutputPath = arg.substring('--json-output='.length).trim();
    }
  }

  if (scriptPath == null || scriptPath.isEmpty) {
    print('Error: --script <path> is required');
    _printUsage();
    exit(1);
  }

  final file = File(scriptPath);
  if (!file.existsSync()) {
    print('Error: script file not found: $scriptPath');
    exit(1);
  }

  final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final metadata = decoded['metadata'] as String? ?? 'sim_combat_montecarlo';
  final battlesRaw = decoded['battles'] as List<dynamic>? ?? [];
  final baseSeed = seed ?? DateTime.now().millisecondsSinceEpoch;

  final aggregatedResults = <Map<String, dynamic>>[];

  for (var idx = 0; idx < battlesRaw.length; idx++) {
    final b = Map<String, dynamic>.from(battlesRaw[idx] as Map);
    final id = b['id'] as String? ?? 'battle_$idx';
    final attackerRaw = b['attacker'] as Map<String, dynamic>? ?? {};
    final defenderRaw = b['defender'] as Map<String, dynamic>? ?? {};
    final provinceRaw = b['province'] as Map<String, dynamic>? ?? {};
    final defenderFaction = b['defenderFaction'] as String? ?? 'greatPower';

    final attackerUnits = _parseUnits(attackerRaw, 'attacker', id);
    final defenderUnits = _parseUnits(defenderRaw, 'defender', id);
    final fortLevel = (provinceRaw['fortLevel'] as int?) ?? 0;
    final terrain = provinceRaw['terrain'] as String? ?? 'plains';

    if (fortLevel < 0 || fortLevel > 3) {
      print('Error: battle $id: fortLevel must be 0-3, got $fortLevel');
      exit(1);
    }

    final defenderEffectiveLevel =
        defenderFaction == 'greatPower' ? 4 : 4;

    var attWins = 0;
    var defWins = 0;
    var stalemates = 0;
    var mutualAnn = 0;
    var totalAttCas = 0;
    var totalDefCas = 0;
    double attStr = 0;
    double defStr = 0;

    for (var t = 0; t < trials; t++) {
      final outcome = resolveEngagementProbabilistic(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        fortLevel: fortLevel,
        terrain: terrain,
        defenderEffectiveMilitaryLevel: defenderEffectiveLevel,
        seed: baseSeed + t,
      );

      attStr = outcome.attackerStrength;
      defStr = outcome.defenderStrength;

      switch (outcome.result) {
        case EngagementResult.attackerVictory:
          attWins++;
          break;
        case EngagementResult.defenderVictory:
          defWins++;
          break;
        case EngagementResult.stalemate:
          stalemates++;
          break;
        case EngagementResult.mutualAnnihilation:
          mutualAnn++;
          break;
      }

      totalAttCas += outcome.attackerCasualties.length;
      totalDefCas += outcome.defenderCasualties.length;
    }

    aggregatedResults.add({
      'id': id,
      'attackerStrength': attStr,
      'defenderStrength': defStr,
      'trials': trials,
      'attackerWins': attWins,
      'defenderWins': defWins,
      'stalemates': stalemates,
      'mutualAnnihilation': mutualAnn,
      'attackerWinPct': 100.0 * attWins / trials,
      'defenderWinPct': 100.0 * defWins / trials,
      'stalematePct': 100.0 * stalemates / trials,
      'mutualAnnPct': 100.0 * mutualAnn / trials,
      'meanAttackerCasualties': totalAttCas / trials,
      'meanDefenderCasualties': totalDefCas / trials,
    });
  }

  final markdown = _buildMarkdownReport(
    metadata: metadata,
    results: aggregatedResults,
    scriptPath: scriptPath,
    trials: trials,
    seed: seed,
  );

  final outPath = outputPath ?? 'sim_combat_montecarlo.md';
  File(outPath).writeAsStringSync(markdown);
  print('Wrote Markdown report to ${File(outPath).absolute.path}');

  if (jsonOutputPath != null && jsonOutputPath.isNotEmpty) {
    File(jsonOutputPath).writeAsStringSync(jsonEncode(aggregatedResults));
    print('Wrote JSON log to ${File(jsonOutputPath).absolute.path}');
  }
}

List<Unit> _parseUnits(
  Map<String, dynamic> side,
  String prefix,
  String battleId,
) {
  final unitsRaw = side['units'] as List<dynamic>? ?? [];
  final units = <Unit>[];
  for (var i = 0; i < unitsRaw.length; i++) {
    final u = Map<String, dynamic>.from(unitsRaw[i] as Map);
    final type = u['type'] as String? ?? 'peasant_levies';
    if (regimentStatsById(type) == null) {
      print('Error: battle $battleId: unknown unit type "$type"');
      exit(1);
    }
    final medals = (u['medals'] as int?) ?? 0;
    units.add(Unit(
      id: '${prefix}_${battleId}_$i',
      type: type,
      ownerId: prefix,
      provinceId: 'prov',
      medals: medals.clamp(0, 4),
    ));
  }
  return units;
}

String _buildMarkdownReport({
  required String metadata,
  required List<Map<String, dynamic>> results,
  String? scriptPath,
  required int trials,
  int? seed,
}) {
  final buffer = StringBuffer();
  buffer.writeln('# sim_combat_montecarlo run');
  buffer.writeln();
  buffer.writeln('## Run metadata');
  buffer.writeln();
  buffer.writeln('| Key | Value |');
  buffer.writeln('| --- | ----- |');
  buffer.writeln('| Scenario | $metadata |');
  buffer.writeln('| Script | ${scriptPath ?? '-'} |');
  buffer.writeln('| Trials | $trials |');
  buffer.writeln('| Base seed | ${seed ?? 'random'} |');
  buffer.writeln();
  buffer.writeln('## Per-battle aggregate');
  buffer.writeln();
  buffer.writeln(
    '| Battle Id | Attacker Str | Defender Str | Attacker Win % | Defender Win % | Stalemate % | Mutual Ann % | Mean Cas (A/D) |',
  );
  buffer.writeln(
    '| --- | --- | --- | --- | --- | --- | --- | --- |',
  );

  for (final r in results) {
    final id = r['id'] as String;
    final attStr = (r['attackerStrength'] as num).toStringAsFixed(1);
    final defStr = (r['defenderStrength'] as num).toStringAsFixed(1);
    final attWinPct = (r['attackerWinPct'] as num).toStringAsFixed(1);
    final defWinPct = (r['defenderWinPct'] as num).toStringAsFixed(1);
    final stalePct = (r['stalematePct'] as num).toStringAsFixed(1);
    final mutPct = (r['mutualAnnPct'] as num).toStringAsFixed(1);
    final meanAtt = (r['meanAttackerCasualties'] as num).toStringAsFixed(2);
    final meanDef = (r['meanDefenderCasualties'] as num).toStringAsFixed(2);
    buffer.writeln('| $id | $attStr | $defStr | $attWinPct | $defWinPct | $stalePct | $mutPct | $meanAtt / $meanDef |');
  }

  buffer.writeln();
  return buffer.toString();
}

void _printUsage() {
  print('Usage:');
  print(
    '  melos run sim_combat_montecarlo -- --script <path> [--trials N] [--seed <int>] [--output <path>] [--json-output <path>]',
  );
  print('');
  print('Monte Carlo combat simulation. Runs many trials, aggregates results. SPEC/program/sim-combat-montecarlo.md.');
}
