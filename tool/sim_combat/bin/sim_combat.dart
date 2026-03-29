/// CLI: simulate combat resolution on scripted scenarios (probabilistic).
/// SPEC/program/sim-combat.md.
import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

final _log = logicLogger('sim_combat');

void main(List<String> arguments) {
  String? scriptPath;
  String? outputPath;
  String? jsonOutputPath;
  int? seed;

  for (var i = 0; i < arguments.length; i++) {
    final arg = arguments[i];
    if (arg == '--help' || arg == '-h') {
      _printUsage();
      exit(0);
    } else if (arg == '--script' && i + 1 < arguments.length) {
      scriptPath = arguments[++i];
    } else if (arg.startsWith('--script=')) {
      scriptPath = arg.substring('--script='.length).trim();
    } else if (arg == '--output' && i + 1 < arguments.length) {
      outputPath = arguments[++i];
    } else if (arg.startsWith('--output=')) {
      outputPath = arg.substring('--output='.length).trim();
    } else if (arg == '--json-output' && i + 1 < arguments.length) {
      jsonOutputPath = arguments[++i];
    } else if (arg.startsWith('--json-output=')) {
      jsonOutputPath = arg.substring('--json-output='.length).trim();
    } else if (arg == '--seed' && i + 1 < arguments.length) {
      final v = int.tryParse(arguments[++i]);
      if (v == null) {
        _log.e('Error: --seed requires an integer');
        exit(1);
      }
      seed = v;
    } else if (arg.startsWith('--seed=')) {
      final v = int.tryParse(arg.substring('--seed='.length).trim());
      if (v == null) {
        _log.e('Error: --seed requires an integer');
        exit(1);
      }
      seed = v;
    }
  }

  if (scriptPath == null || scriptPath.isEmpty) {
    _log.e('Error: --script <path> is required');
    _printUsage();
    exit(1);
  }

  final file = File(scriptPath);
  if (!file.existsSync()) {
    _log.e('Error: script file not found: $scriptPath');
    exit(1);
  }

  final effectiveSeed = seed ?? DateTime.now().millisecondsSinceEpoch;

  final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final metadata = decoded['metadata'] as String? ?? 'sim_combat';
  final battlesRaw = decoded['battles'] as List<dynamic>? ?? [];

  final results = <Map<String, dynamic>>[];

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
      _log.e('Error: battle $id: fortLevel must be 0-3, got $fortLevel');
      exit(1);
    }

    final defenderEffectiveLevel =
        defenderFaction == 'greatPower' ? 4 : 4;

    final outcome = resolveEngagementProbabilistic(
      attackerUnits: attackerUnits,
      defenderUnits: defenderUnits,
      fortLevel: fortLevel,
      terrain: terrain,
      defenderEffectiveMilitaryLevel: defenderEffectiveLevel,
      seed: effectiveSeed,
    );

    String winner;
    switch (outcome.result) {
      case EngagementResult.attackerVictory:
        winner = 'attacker';
        break;
      case EngagementResult.defenderVictory:
        winner = 'defender';
        break;
      case EngagementResult.stalemate:
        winner = 'stalemate';
        break;
      case EngagementResult.mutualAnnihilation:
        winner = 'mutual_annihilation';
        break;
    }

    final provinceFlip = outcome.result == EngagementResult.attackerVictory;

    final terrainMod = terrainModifiers[terrain] ?? (1.0, 1.0);
    var effAtt = outcome.attackerStrength * terrainMod.$1;
    var effDef = outcome.defenderStrength * terrainMod.$2;
    if (fortLevel >= 1 && fortLevel <= 3) {
      effAtt *= (1.0 - fortDamageReduction[fortLevel]);
      effDef += fortGunCount[fortLevel] * fortEmplacedStrength[fortLevel];
    }

    results.add({
      'id': id,
      'attackerStrength': outcome.attackerStrength,
      'defenderStrength': outcome.defenderStrength,
      'winner': winner,
      'casualties': {
        'attacker': outcome.attackerCasualties,
        'defender': outcome.defenderCasualties,
      },
      'provinceFlip': provinceFlip,
      'outcome': outcome,
      'terrain': terrain,
      'fortLevel': fortLevel,
      'terrainMod': terrainMod,
      'effectiveAttackerStrength': effAtt,
      'effectiveDefenderStrength': effDef,
    });
  }

  final markdown = _buildMarkdownReport(
    metadata: metadata,
    results: results,
    scriptPath: scriptPath,
    seed: effectiveSeed,
  );

  final outPath = outputPath ?? 'sim_combat.md';
  File(outPath).writeAsStringSync(markdown);
  _log.i('Wrote Markdown report to ${File(outPath).absolute.path}');

  if (jsonOutputPath != null && jsonOutputPath.isNotEmpty) {
    final jsonResults = results.map((r) {
      final m = <String, dynamic>{
        'id': r['id'],
        'attackerStrength': r['attackerStrength'],
        'defenderStrength': r['defenderStrength'],
        'winner': r['winner'],
        'casualties': r['casualties'],
        'provinceFlip': r['provinceFlip'],
      };
      return m;
    }).toList();
    File(jsonOutputPath).writeAsStringSync(jsonEncode(jsonResults));
    _log.i('Wrote JSON log to ${File(jsonOutputPath).absolute.path}');
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
      _log.e('Error: battle $battleId: unknown unit type "$type"');
      exit(1);
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
  int? seed,
}) {
  final buffer = StringBuffer();
  buffer.writeln('# sim_combat run');
  buffer.writeln();
  buffer.writeln('## Run metadata');
  buffer.writeln();
  buffer.writeln('| Key | Value |');
  buffer.writeln('| --- | ----- |');
  buffer.writeln('| Scenario | $metadata |');
  buffer.writeln('| Script | ${scriptPath ?? '-'} |');
  buffer.writeln('| Seed | ${seed ?? 'N/A'} |');
  buffer.writeln('| Model | Probabilistic (up to $maxCombatRounds rounds, clamped hit odds, strength-weighted casualties) |');
  buffer.writeln();

  for (final r in results) {
    final id = r['id'] as String;
    final outcome = r['outcome'] as ProbabilisticEngagementOutcome;
    final terrain = r['terrain'] as String;
    final fortLevel = r['fortLevel'] as int;
    final terrainMod = r['terrainMod'] as (double, double);
    final effAtt = r['effectiveAttackerStrength'] as double;
    final effDef = r['effectiveDefenderStrength'] as double;

    buffer.writeln('### Battle: $id');
    buffer.writeln();
    buffer.writeln('#### Initial strengths');
    buffer.writeln('- Attacker raw: ${outcome.attackerStrength.toStringAsFixed(1)} | Defender raw: ${outcome.defenderStrength.toStringAsFixed(1)}');
    buffer.writeln('- Terrain: $terrain | Modifiers: attacker ×${terrainMod.$1}, defender ×${terrainMod.$2}');
    buffer.writeln('- Fort: level $fortLevel, damage reduction ${((fortDamageReduction[fortLevel]) * 100).toStringAsFixed(0)}%, emplaced +${fortGunCount[fortLevel] * fortEmplacedStrength[fortLevel]}');
    buffer.writeln('- Effective: E_a = ${effAtt.toStringAsFixed(1)}, E_d = ${effDef.toStringAsFixed(1)}');
    buffer.writeln();

    for (final round in outcome.rounds) {
      buffer.writeln('#### Round ${round.roundNumber}');
      buffer.writeln('- E_a = ${round.effectiveAttackerStrength.toStringAsFixed(1)}, E_d = ${round.effectiveDefenderStrength.toStringAsFixed(1)}');
      buffer.writeln('- P(attacker hits) = E_a/(E_a+E_d) = ${round.probabilityAttackerHits.toStringAsFixed(3)} (clamped to [$hitProbabilityMin, $hitProbabilityMax])');
      buffer.writeln('- P(defender hits) = E_d/(E_a+E_d) = ${round.probabilityDefenderHits.toStringAsFixed(3)} (clamped)');
      buffer.writeln('- λ_defender = k × P_a = ${round.lambdaDefender.toStringAsFixed(3)} | λ_attacker = k × P_d = ${round.lambdaAttacker.toStringAsFixed(3)}');
      buffer.writeln('- Sampled: defender casualties = ${round.defenderCasualties.length}, attacker casualties = ${round.attackerCasualties.length}');
      buffer.writeln('- Defenders lost: [${round.defenderCasualties.join(", ")}] | Attackers lost: [${round.attackerCasualties.join(", ")}]');
      buffer.writeln('- Remaining: ${round.attackersRemaining} attackers, ${round.defendersRemaining} defenders');
      buffer.writeln();
    }

    buffer.writeln('#### Outcome');
    buffer.writeln('Winner: ${r['winner']} | Province flip: ${(r['provinceFlip'] as bool) ? "yes" : "no"}');
    final cas = r['casualties'] as Map<String, dynamic>;
    buffer.writeln('Total casualties: attacker ${(cas['attacker'] as List).length}, defender ${(cas['defender'] as List).length}');
    buffer.writeln();
  }

  buffer.writeln('## Summary');
  buffer.writeln();
  buffer.writeln('| Id | Attacker Str | Defender Str | Winner | Province Flip | Casualties (A/D) |');
  buffer.writeln('| --- | --- | --- | --- | --- | --- |');

  for (final r in results) {
    final id = r['id'] as String;
    final attStr = (r['attackerStrength'] as num).toStringAsFixed(1);
    final defStr = (r['defenderStrength'] as num).toStringAsFixed(1);
    final winner = r['winner'] as String;
    final flip = r['provinceFlip'] as bool;
    final cas = r['casualties'] as Map<String, dynamic>;
    final attCas = (cas['attacker'] as List).length;
    final defCas = (cas['defender'] as List).length;
    buffer.writeln('| $id | $attStr | $defStr | $winner | ${flip ? "yes" : "no"} | $attCas / $defCas |');
  }

  buffer.writeln();
  return buffer.toString();
}

void _printUsage() {
  _log.i('Usage:');
  _log.i('  melos run sim_combat -- --script <path> [--output <path>] [--json-output <path>] [--seed <int>]');
  _log.i('');
  _log.i('Simulates probabilistic combat resolution on scripted scenarios. SPEC/program/sim-combat.md.');
}
