/// CLI: Monte Carlo combat simulation. Runs many trials, aggregates results.
/// SPEC/program/sim-combat-montecarlo.md.
library;

import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:sim_combat_montecarlo/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

final _log = packageLogger('sim_combat_montecarlo');

/// Fixed defender effective military level for sim (SPEC: same for all script types).
const int _simDefenderEffectiveLevel = 4;

void _errExit(String message) {
  _log.e(message);
  stderr.writeln(message);
  exit(1);
}

void main(List<String> arguments) {
  String? scriptPath;
  int trials = 1000;
  int? seed;
  String? outputPath;
  String? jsonOutputPath;

  for (var i = 0; i < arguments.length; i++) {
    final arg = arguments[i];
    if (arg == '--help' || arg == '-h') {
      _log.i(_usage);
      exit(0);
    } else if (arg == '--script' && i + 1 < arguments.length) {
      scriptPath = arguments[++i];
    } else if (arg.startsWith('--script=')) {
      scriptPath = arg.substring('--script='.length).trim();
    } else if (arg == '--trials' && i + 1 < arguments.length) {
      final v = int.tryParse(arguments[++i]);
      if (v == null || v < 1) {
        _errExit('--trials must be a positive integer');
      }
      trials = v!;
    } else if (arg.startsWith('--trials=')) {
      final v = int.tryParse(arg.substring('--trials='.length).trim());
      if (v == null || v < 1) {
        _errExit('--trials must be a positive integer');
      }
      trials = v!;
    } else if (arg == '--seed' && i + 1 < arguments.length) {
      final v = int.tryParse(arguments[++i]);
      if (v == null) {
        _errExit('--seed requires an integer');
      }
      seed = v;
    } else if (arg.startsWith('--seed=')) {
      final v = int.tryParse(arg.substring('--seed='.length).trim());
      if (v == null) {
        _errExit('--seed requires an integer');
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
    _log.e('--script <path> is required');
    _log.i(_usage);
    stderr.writeln('--script <path> is required');
    stderr.writeln(_usage);
    exit(1);
  }

  final file = File(scriptPath);
  if (!file.existsSync()) {
    _errExit('script file not found: $scriptPath');
  }

  Map<String, dynamic> decoded;
  try {
    decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  } catch (e, st) {
    _log.e('malformed script JSON', error: e, stackTrace: st);
    stderr.writeln('malformed script JSON: $e');
    exit(1);
  }
  final metadata = decoded['metadata'] as String? ?? 'sim_combat_montecarlo';
  final battlesRaw = decoded['battles'];
  if (battlesRaw is! List<dynamic>) {
    _errExit('script must have "battles" array');
  }
  final baseSeed = seed ?? DateTime.now().millisecondsSinceEpoch;

  final aggregatedResults = <Map<String, dynamic>>[];

  for (var idx = 0; idx < battlesRaw.length; idx++) {
    final entry = battlesRaw[idx];
    if (entry is! Map) {
      _errExit('battle $idx must be an object');
    }
    final b = Map<String, dynamic>.from(entry as Map);
    _validateBattleKeys(b, idx);
    final id = b['id'] as String;
    final attackerRaw = b['attacker'] as Map<String, dynamic>;
    final defenderRaw = b['defender'] as Map<String, dynamic>;
    final provinceRaw = b['province'] as Map<String, dynamic>;
    final attackerGeneralMedals = (attackerRaw['generalMedals'] as int?) ?? 0;
    // Defender generalMedals parsed for script format parity; resolver uses attacker's only.

    final attackerUnits = _parseUnits(attackerRaw, 'attacker', id);
    final defenderUnits = _parseUnits(defenderRaw, 'defender', id);
    final fortLevel = (provinceRaw['fortLevel'] as int?) ?? 0;
    final terrain = provinceRaw['terrain'] as String? ?? 'plains';

    if (fortLevel < 0 || fortLevel > 3) {
      _errExit('battle $id: fortLevel must be 0-3, got $fortLevel');
    }

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
        generalMedals: attackerGeneralMedals,
        fortLevel: fortLevel,
        terrain: terrain,
        defenderEffectiveMilitaryLevel: _simDefenderEffectiveLevel,
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
  _log.i('wrote Markdown report to ${File(outPath).absolute.path}');

  if (jsonOutputPath != null && jsonOutputPath.isNotEmpty) {
    File(jsonOutputPath).writeAsStringSync(jsonEncode(aggregatedResults));
    _log.i('wrote JSON log to ${File(jsonOutputPath).absolute.path}');
  }
}

/// Validates required battle keys per SPEC/program/sim-combat-montecarlo.md.
void _validateBattleKeys(Map<String, dynamic> b, int idx) {
  final idVal = b['id'];
  if (idVal == null || idVal is! String) {
    _errExit(
      'battle $idx: required key "id" missing or not a string',
    );
  }
  final att = b['attacker'];
  if (att == null || att is! Map) {
    _errExit(
      'battle $idx: required key "attacker" missing or not an object',
    );
  }
  final def = b['defender'];
  if (def == null || def is! Map) {
    _errExit(
      'battle $idx: required key "defender" missing or not an object',
    );
  }
  final prov = b['province'];
  if (prov == null || prov is! Map) {
    _errExit(
      'battle $idx: required key "province" missing or not an object',
    );
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
      _errExit('battle $battleId: unknown unit type "$type"');
    }
    final medals = (u['medals'] as int?) ?? 0;
    units.add(Unit(
      id: '${prefix}_${battleId}_$i',
      type: type,
      ownerId: prefix,
      locationProvinceId: 'oldWorld|prov',
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

const _usage = 'Usage: melos run sim_combat_montecarlo -- --script <path> [--trials N] [--seed <int>] [--output <path>] [--json-output <path>]. Monte Carlo combat simulation. SPEC/program/sim-combat-montecarlo.md.';
