/// CLI: simulate a single player's economy over N turns.
/// SPEC/program/sim-economy.md
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:sim_economy/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

final _log = packageLogger('sim_economy');

void main(List<String> arguments) {
  String? scriptPath;
  int? turns;
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
    } else if (arg == '--turns' && i + 1 < arguments.length) {
      final value = arguments[++i];
      turns = int.tryParse(value);
      if (turns == null || turns < 1) {
        _log.e('Error: --turns must be a positive integer, got: $value');
        exit(1);
      }
    } else if (arg.startsWith('--turns=')) {
      final value = arg.substring('--turns='.length).trim();
      turns = int.tryParse(value);
      if (turns == null || turns < 1) {
        _log.e('Error: --turns must be a positive integer, got: $value');
        exit(1);
      }
    } else if (arg == '--seed' && i + 1 < arguments.length) {
      final value = arguments[++i];
      seed = int.tryParse(value);
      if (seed == null) {
        _log.e('Error: --seed requires an integer, got: $value');
        exit(1);
      }
    } else if (arg.startsWith('--seed=')) {
      final value = arg.substring('--seed='.length).trim();
      seed = int.tryParse(value);
      if (seed == null) {
        _log.e('Error: --seed requires an integer, got: $value');
        exit(1);
      }
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

  final useScript = scriptPath != null && scriptPath.isNotEmpty;
  if (!useScript && turns == null) {
    _log.e('Error: --turns is required when no --script is provided.');
    _printUsage();
    exit(1);
  }

  final rng = Random(seed ?? Random().nextInt(0x7FFFFFFF));
  final turnsLog = <Map<String, dynamic>>[];

  late Stockpile stockpile;
  late WorkerPool workers;
  var militaryUnits = 0;
  var treasury = 0;
  int totalTurns;
  List<_ScriptTurn> scriptTurns = const [];

  if (useScript) {
    final file = File(scriptPath);
    if (!file.existsSync()) {
      _log.e('Error: script file not found: $scriptPath');
      exit(1);
    }
    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final parsed = parseSimEconomyScript(decoded);
    stockpile = parsed.initialStockpile;
    workers = parsed.initialWorkers;
    militaryUnits = parsed.initialMilitaryUnits;
    treasury = parsed.initialTreasury;
    scriptTurns = parsed.turns;
    totalTurns = turns ?? scriptTurns.length;
  } else {
    final random = _randomInitialState(rng);
    stockpile = random.stockpile;
    workers = random.workers;
    militaryUnits = random.militaryUnits;
    treasury = random.treasury;
    totalTurns = turns!;
  }

  final initialStockpile = stockpile;
  final initialWorkers = workers;

  for (var turn = 1; turn <= totalTurns; turn++) {
    final scriptTurn =
        useScript && turn <= scriptTurns.length ? scriptTurns[turn - 1] : null;

    final stockpileStart = stockpile;
    final workersStart = workers;

    // 1. Actions (stubbed; treasury/military not yet modelled).
    // 2. Extraction
    final extractionVector =
        scriptTurn?.extraction ?? _defaultExtractionProfile(rng);
    stockpile = applyExtractionToStockpile(stockpile, extractionVector);
    final stockpileAfterExtraction = stockpile;

    // 3. Riches to treasury
    final richesResult = resolveRichesToTreasury(stockpile: stockpile);
    stockpile = richesResult.stockpile;
    treasury += richesResult.treasuryDelta;
    final stockpileAfterRiches = stockpile;

    // 4. Consumption (before production; workers are not removed on strike)
    final consumptionResult = resolveConsumption(
      stockpile: stockpile,
      workers: workers,
      militaryUnits: militaryUnits,
    );
    stockpile = consumptionResult.stockpile;
    workers = consumptionResult.workerPool;
    final stockpileAfterConsumption = stockpile;

    // 5. Production
    final assignments = scriptTurn?.assignments ??
        _defaultAssignments(workers, stockpile, rng);
    final productionResult = resolveProduction(
      stockpile: stockpile,
      workers: workers,
      idleLabour: consumptionResult.idleLabour,
      assignments: assignments,
    );
    stockpile = productionResult.stockpile;
    workers = productionResult.workerPool;
    final stockpileAfterProduction = stockpile;

    final stockpileEnd = stockpile;
    final workersEnd = workers;

    final entry = buildTurnLogEntry(
      turn: turn,
      stockpileStart: stockpileStart,
      stockpileAfterExtraction: stockpileAfterExtraction,
      stockpileAfterRiches: stockpileAfterRiches,
      stockpileAfterConsumption: stockpileAfterConsumption,
      stockpileAfterProduction: stockpileAfterProduction,
      stockpileEnd: stockpileEnd,
      workersStart: workersStart,
      workersEnd: workersEnd,
      extractionVector: extractionVector,
      assignments: assignments,
      treasuryDeltaFromRiches: richesResult.treasuryDelta,
      treasuryEndOfTurn: treasury,
    );
    turnsLog.add(entry);
  }

  final markdown = buildMarkdownReport(
    turns: turnsLog,
    totalTurns: totalTurns,
    initialStockpile: initialStockpile,
    initialWorkers: initialWorkers,
    seed: seed,
    scriptPath: scriptPath,
    militaryUnits: militaryUnits,
    treasury: treasury,
  );

  final outputConfig = resolveOutputConfig(
    outputPath: outputPath,
    jsonOutputPath: jsonOutputPath,
  );

  final markdownFile = File(outputConfig.markdownPath);
  markdownFile.writeAsStringSync(markdown);
  _log.i('Wrote Markdown report to ${markdownFile.absolute.path}');

  if (outputConfig.jsonPath != null) {
    final jsonFile = File(outputConfig.jsonPath!);
    jsonFile.writeAsStringSync(jsonEncode(turnsLog));
    _log.i('Wrote JSON log to ${jsonFile.absolute.path}');
  }
}

void _printUsage() {
  _log.i('Usage:');
  _log.i(
      '  melos run sim_economy -- [--script path] [--turns N] [--seed S] [--output path] [--json-output path]');
  _log.i('');
  _log.i('Simulates a single player economy using Phase 2 rules.');
}

Map<String, int> _quantitiesFromStockpile(Stockpile stockpile) {
  final json = stockpile.toJson();
  final quantities = json['quantities'] as Map<dynamic, dynamic>? ?? const {};
  return quantities.map(
    (key, value) => MapEntry('$key', value as int),
  );
}

Map<String, int> _deltaMap(
  Map<String, int> before,
  Map<String, int> after,
) {
  final result = <String, int>{};
  final keys = <String>{}
    ..addAll(before.keys)
    ..addAll(after.keys);
  for (final key in keys) {
    final b = before[key] ?? 0;
    final a = after[key] ?? 0;
    final delta = a - b;
    if (delta != 0) {
      result[key] = delta;
    }
  }
  return result;
}

String _signed(int value) {
  if (value == 0) return '0';
  if (value > 0) return '+$value';
  return '$value';
}

List<String> _sortedCommodityIds(Iterable<String> ids) {
  final order = <String, int>{
    for (var i = 0; i < CommodityCatalog.all.length; i++)
      CommodityCatalog.all[i].id: i,
  };
  final list = ids.toSet().toList();
  list.sort((a, b) {
    final ia = order[a] ?? 1 << 20;
    final ib = order[b] ?? 1 << 20;
    if (ia != ib) return ia.compareTo(ib);
    return a.compareTo(b);
  });
  return list;
}

Map<String, dynamic> buildTurnLogEntry({
  required int turn,
  required Stockpile stockpileStart,
  required Stockpile stockpileAfterExtraction,
  required Stockpile stockpileAfterRiches,
  required Stockpile stockpileAfterConsumption,
  required Stockpile stockpileAfterProduction,
  required Stockpile stockpileEnd,
  required WorkerPool workersStart,
  required WorkerPool workersEnd,
  required Map<CommodityId, int> extractionVector,
  required List<AssignedRecipe> assignments,
  required int treasuryDeltaFromRiches,
  required int treasuryEndOfTurn,
}) {
  final startMap = _quantitiesFromStockpile(stockpileStart);
  final afterExtractionMap = _quantitiesFromStockpile(stockpileAfterExtraction);
  final afterRichesMap = _quantitiesFromStockpile(stockpileAfterRiches);
  final afterConsumptionMap =
      _quantitiesFromStockpile(stockpileAfterConsumption);
  final afterProductionMap = _quantitiesFromStockpile(stockpileAfterProduction);
  final endMap = _quantitiesFromStockpile(stockpileEnd);

  final deltaExtraction = _deltaMap(startMap, afterExtractionMap);
  final deltaRiches = _deltaMap(afterExtractionMap, afterRichesMap);
  final deltaConsumption = _deltaMap(afterRichesMap, afterConsumptionMap);
  final deltaProduction = _deltaMap(afterConsumptionMap, afterProductionMap);

  final extractionJson = <String, int>{
    for (final entry in extractionVector.entries) entry.key: entry.value,
  };

  final workerAssignmentsJson = assignments
      .map(
        (a) => {
          'recipeId': a.recipeId,
          'assignedLabour': a.assignedLabour,
        },
      )
      .toList();

  return <String, dynamic>{
    'turn': turn,
    'stockpileStart': startMap,
    'stockpileAfterExtraction': afterExtractionMap,
    'stockpileAfterRiches': afterRichesMap,
    'stockpileAfterConsumption': afterConsumptionMap,
    'stockpileAfterProduction': afterProductionMap,
    'stockpileEnd': endMap,
    'workersStart': workersStart.toJson(),
    'workersEnd': workersEnd.toJson(),
    'deltaExtraction': deltaExtraction,
    'deltaRiches': deltaRiches,
    'deltaProduction': deltaProduction,
    'deltaConsumption': deltaConsumption,
    'treasuryDeltaFromRiches': treasuryDeltaFromRiches,
    'treasuryEndOfTurn': treasuryEndOfTurn,
    'extraction': extractionJson,
    'workerAssignments': workerAssignmentsJson,
  };
}

String buildMarkdownReport({
  required List<Map<String, dynamic>> turns,
  required int totalTurns,
  required Stockpile initialStockpile,
  required WorkerPool initialWorkers,
  int? seed,
  String? scriptPath,
  int? militaryUnits,
  int? treasury,
}) {
  final buffer = StringBuffer();
  final now = DateTime.now().toUtc().toIso8601String();

  buffer.writeln('# sim_economy run');
  buffer.writeln();
  buffer.writeln('## Run metadata');
  buffer.writeln();
  buffer.writeln('| Key | Value |');
  buffer.writeln('| --- | ----- |');
  buffer.writeln('| Seed | ${seed ?? 'random'} |');
  buffer.writeln('| Script | ${scriptPath?.isNotEmpty == true ? scriptPath : '-'} |');
  buffer.writeln('| Total turns | $totalTurns |');
  buffer.writeln('| Generated at | $now |');
  buffer.writeln();

  final initialQuantities = _quantitiesFromStockpile(initialStockpile);

  buffer.writeln('## Initial state');
  buffer.writeln();
  buffer.writeln('### Stockpile');
  buffer.writeln();
  buffer.writeln('| Commodity | Quantity |');
  buffer.writeln('| --------- | -------- |');
  for (final id in _sortedCommodityIds(initialQuantities.keys)) {
    final quantity = initialQuantities[id] ?? 0;
    if (quantity == 0) continue;
    buffer.writeln('| $id | $quantity |');
  }
  buffer.writeln();

  buffer.writeln('### Workers');
  buffer.writeln();
  buffer.writeln('| Class | Count |');
  buffer.writeln('| ----- | ----- |');
  buffer.writeln('| peasants | ${initialWorkers.peasants} |');
  buffer.writeln('| apprentices | ${initialWorkers.apprentices} |');
  buffer.writeln('| journeymen | ${initialWorkers.journeymen} |');
  buffer.writeln('| masters | ${initialWorkers.masters} |');
  buffer.writeln();

  if (militaryUnits != null || treasury != null) {
    buffer.writeln('### Other');
    buffer.writeln();
    buffer.writeln('| Key | Value |');
    buffer.writeln('| --- | ----- |');
    if (militaryUnits != null) {
      buffer.writeln('| militaryUnits | $militaryUnits |');
    }
    if (treasury != null) {
      buffer.writeln('| treasury | $treasury |');
    }
    buffer.writeln();
  }

  buffer.writeln('## Turns');
  buffer.writeln();

  for (final entry in turns) {
    final turn = entry['turn'] as int;
    final stockpileStart =
        (entry['stockpileStart'] as Map).cast<String, int>();
    final stockpileEnd = (entry['stockpileEnd'] as Map).cast<String, int>();
    final deltaExtraction =
        (entry['deltaExtraction'] as Map).cast<String, int>();
    final deltaRiches =
        (entry['deltaRiches'] as Map?)?.cast<String, int>() ?? const {};
    final deltaProduction =
        (entry['deltaProduction'] as Map).cast<String, int>();
    final deltaConsumption =
        (entry['deltaConsumption'] as Map).cast<String, int>();
    final treasuryDeltaFromRiches = entry['treasuryDeltaFromRiches'] as int? ?? 0;
    final treasuryEndOfTurn = entry['treasuryEndOfTurn'] as int?;
    final workersStart =
        (entry['workersStart'] as Map).cast<String, dynamic>();
    final workersEnd = (entry['workersEnd'] as Map).cast<String, dynamic>();
    final assignments =
        (entry['workerAssignments'] as List).cast<Map<String, dynamic>>();

    buffer.writeln('### Turn $turn');
    buffer.writeln();
    buffer.writeln('#### Economy – stockpile & flows');
    buffer.writeln();
    buffer.writeln('| Commodity | Start | End | Δ | Flows | Reason |');
    buffer.writeln('| --------- | ----- | --- | - | ----- | ------ |');

    final allCommodityIds = <String>{}
      ..addAll(stockpileStart.keys)
      ..addAll(stockpileEnd.keys)
      ..addAll(deltaExtraction.keys)
      ..addAll(deltaRiches.keys)
      ..addAll(deltaProduction.keys)
      ..addAll(deltaConsumption.keys);

    for (final id in _sortedCommodityIds(allCommodityIds)) {
      final start = stockpileStart[id] ?? 0;
      final end = stockpileEnd[id] ?? 0;
      final deltaTotal = end - start;
      final e = deltaExtraction[id] ?? 0;
      final r = deltaRiches[id] ?? 0;
      final p = deltaProduction[id] ?? 0;
      final c = deltaConsumption[id] ?? 0;

      final flows = <String>[];
      if (e != 0) flows.add('E${_signed(e)}');
      if (r != 0) flows.add('R${_signed(r)}');
      if (p != 0) flows.add('P${_signed(p)}');
      if (c != 0) flows.add('C${_signed(c)}');

      final flowsCell = flows.isEmpty ? '' : flows.join(', ');

      final reasonParts = <String>[];
      final totalWorkersStart = (workersStart['peasants'] as int? ?? 0) +
          (workersStart['apprentices'] as int? ?? 0) +
          (workersStart['journeymen'] as int? ?? 0) +
          (workersStart['masters'] as int? ?? 0);

      final commodity = CommodityCatalog.byId[id];
      final category = commodity?.category;

      if (c != 0 &&
          (id == CommodityCatalog.grain.id || id == CommodityCatalog.meat.id)) {
        if (totalWorkersStart > 0) {
          reasonParts.add('worker food');
        }
        if ((militaryUnits ?? 0) > 0) {
          reasonParts.add('military upkeep');
        }
      }

      if (r != 0) {
        reasonParts.add('riches to treasury');
      }

      if (p != 0) {
        if (category == CommodityCategory.manufactured && p > 0) {
          reasonParts.add('production output');
        } else if (category == CommodityCategory.rawMaterial && p < 0) {
          reasonParts.add('production inputs');
        } else {
          reasonParts.add('production');
        }
      }

      if (e != 0 && reasonParts.isEmpty) {
        reasonParts.add('extraction');
      }
      if (e != 0 && c == 0 && reasonParts.isNotEmpty) {
        reasonParts.insert(0, 'extraction');
      }

      final reasonCell =
          reasonParts.isEmpty ? '' : reasonParts.join(' + ');

      buffer.writeln(
        '| $id | $start | $end | ${_signed(deltaTotal)} | $flowsCell | $reasonCell |',
      );
    }

    if (treasuryEndOfTurn != null || treasuryDeltaFromRiches != 0) {
      buffer.writeln();
      buffer.writeln('Treasury: ${treasuryEndOfTurn ?? '-'}'
          '${treasuryDeltaFromRiches != 0 ? ' (Δ from riches: ${_signed(treasuryDeltaFromRiches)})' : ''}');
    }

    buffer.writeln();
    buffer.writeln('#### Labour – workers & assignments');
    buffer.writeln();
    buffer.writeln(
        '| Type | Name | Start | End | Δ / Labour | Notes |');
    buffer.writeln(
        '| ---- | ---- | ----- | --- | ---------- | ----- |');

    void writeWorkerRow(String name, int start, int end) {
      final delta = end - start;
      buffer.writeln(
        '| W | $name | $start | $end | Δ ${_signed(delta)} | |',
      );
    }

    writeWorkerRow(
      'peasants',
      (workersStart['peasants'] as int? ?? 0),
      (workersEnd['peasants'] as int? ?? 0),
    );
    writeWorkerRow(
      'apprentices',
      (workersStart['apprentices'] as int? ?? 0),
      (workersEnd['apprentices'] as int? ?? 0),
    );
    writeWorkerRow(
      'journeymen',
      (workersStart['journeymen'] as int? ?? 0),
      (workersEnd['journeymen'] as int? ?? 0),
    );
    writeWorkerRow(
      'masters',
      (workersStart['masters'] as int? ?? 0),
      (workersEnd['masters'] as int? ?? 0),
    );

    int totalStartLabour = 0;
    int totalEndLabour = 0;
    totalStartLabour +=
        (workersStart['peasants'] as int? ?? 0) * 1;
    totalEndLabour += (workersEnd['peasants'] as int? ?? 0) * 1;
    totalStartLabour +=
        (workersStart['apprentices'] as int? ?? 0) * 4;
    totalEndLabour +=
        (workersEnd['apprentices'] as int? ?? 0) * 4;
    totalStartLabour +=
        (workersStart['journeymen'] as int? ?? 0) * 6;
    totalEndLabour +=
        (workersEnd['journeymen'] as int? ?? 0) * 6;

    final totalDeltaLabour = totalEndLabour - totalStartLabour;
    buffer.writeln(
      '| W | total labour (approx) | $totalStartLabour | $totalEndLabour | Δ ${_signed(totalDeltaLabour)} | |',
    );

    for (final a in assignments) {
      final recipeId = a['recipeId'] as String? ?? '';
      final labour = a['assignedLabour'] as int? ?? 0;
      String notes = '';
      final recipe = ProductionRecipesCatalog.byId[recipeId];
      if (recipe != null) {
        final outputId = recipe.outputCommodityId;
        notes = '→ $outputId';
      }
      buffer.writeln(
        '| R | $recipeId | - | - | L $labour | $notes |',
      );
    }

    buffer.writeln();
  }

  return buffer.toString();
}

class SimEconomyOutputConfig {
  const SimEconomyOutputConfig({
    required this.markdownPath,
    required this.jsonPath,
  });

  final String markdownPath;
  final String? jsonPath;
}

SimEconomyOutputConfig resolveOutputConfig({
  String? outputPath,
  String? jsonOutputPath,
}) {
  final markdownPath =
      (outputPath == null || outputPath.isEmpty) ? 'sim_economy.md' : outputPath;
  final jsonPath =
      (jsonOutputPath == null || jsonOutputPath.isEmpty) ? null : jsonOutputPath;
  return SimEconomyOutputConfig(
    markdownPath: markdownPath,
    jsonPath: jsonPath,
  );
}

class _RandomInitialState {
  _RandomInitialState({
    required this.stockpile,
    required this.workers,
    required this.militaryUnits,
    required this.treasury,
  });

  final Stockpile stockpile;
  final WorkerPool workers;
  final int militaryUnits;
  final int treasury;
}

_RandomInitialState _randomInitialState(Random rng) {
  int r(int min, int max) => min + rng.nextInt(max - min + 1);

  var stockpile = const Stockpile()
      .applyDelta(CommodityCatalog.grain.id, r(40, 80))
      .applyDelta(CommodityCatalog.meat.id, r(20, 40))
      .applyDelta(CommodityCatalog.timber.id, r(20, 40))
      .applyDelta(CommodityCatalog.iron.id, r(10, 25))
      .applyDelta(CommodityCatalog.coal.id, r(10, 20))
      .applyDelta(CommodityCatalog.wool.id, r(10, 20))
      .applyDelta(CommodityCatalog.cotton.id, r(0, 10))
      .applyDelta(CommodityCatalog.sugarCane.id, r(0, 10))
      .applyDelta(CommodityCatalog.tobacco.id, r(0, 10))
      .applyDelta(CommodityCatalog.furs.id, r(0, 10))
      .applyDelta(CommodityCatalog.lumber.id, r(5, 15))
      .applyDelta(CommodityCatalog.castIron.id, r(5, 15))
      .applyDelta(CommodityCatalog.fabric.id, r(10, 20))
      .applyDelta(CommodityCatalog.paper.id, r(5, 10))
      .applyDelta(CommodityCatalog.refinedSugar.id, r(0, 5))
      .applyDelta(CommodityCatalog.cigars.id, r(0, 5))
      .applyDelta(CommodityCatalog.furHats.id, r(0, 5))
      .applyDelta(CommodityCatalog.gold.id, r(0, 3))
      .applyDelta(CommodityCatalog.silver.id, r(0, 5))
      .applyDelta(CommodityCatalog.gems.id, r(0, 3))
      .applyDelta(CommodityCatalog.diamonds.id, r(0, 1))
      .applyDelta(CommodityCatalog.spices.id, r(0, 3));

  final workers = WorkerPool(
    peasants: r(8, 14),
    apprentices: r(0, 3),
    journeymen: r(0, 1),
    masters: 0,
  );

  final militaryUnits = r(0, 1);
  final treasury = r(50, 150);

  return _RandomInitialState(
    stockpile: stockpile,
    workers: workers,
    militaryUnits: militaryUnits,
    treasury: treasury,
  );
}

Map<CommodityId, int> _defaultExtractionProfile(Random rng) {
  int r(int min, int max) => min + rng.nextInt(max - min + 1);

  return {
    CommodityCatalog.grain.id: r(4, 6),
    CommodityCatalog.meat.id: r(1, 3),
    CommodityCatalog.timber.id: r(3, 5),
    CommodityCatalog.iron.id: r(1, 3),
    CommodityCatalog.coal.id: r(1, 2),
    CommodityCatalog.wool.id: r(1, 2),
    CommodityCatalog.sugarCane.id: r(0, 2),
    CommodityCatalog.tobacco.id: r(0, 2),
    CommodityCatalog.furs.id: r(0, 2),
  };
}

List<AssignedRecipe> _defaultAssignments(
  WorkerPool workers,
  Stockpile stockpile,
  Random rng,
) {
  // Simple baseline: distribute a fixed amount of labour to core recipes.
  final totalLabour = workers.labourSupplyPerTurn;
  if (totalLabour <= 0) return const [];

  final toFabric = (totalLabour * 0.4).round();
  final toCastIron = (totalLabour * 0.3).round();
  final toLumber = totalLabour - toFabric - toCastIron;

  return [
    if (toFabric > 0)
      AssignedRecipe(
        recipeId: 'fabric_from_wool',
        assignedLabour: toFabric,
      ),
    if (toCastIron > 0)
      AssignedRecipe(
        recipeId: 'castIron_from_iron',
        assignedLabour: toCastIron,
      ),
    if (toLumber > 0)
      AssignedRecipe(
        recipeId: 'lumber_from_timber',
        assignedLabour: toLumber,
      ),
  ];
}

class _ScriptTurn {
  _ScriptTurn({
    required this.turn,
    required this.extraction,
    required this.assignments,
  });

  final int turn;
  final Map<CommodityId, int> extraction;
  final List<AssignedRecipe> assignments;
}

class ParsedScript {
  ParsedScript({
    required this.initialStockpile,
    required this.initialWorkers,
    required this.initialMilitaryUnits,
    required this.initialTreasury,
    required this.turns,
  });

  final Stockpile initialStockpile;
  final WorkerPool initialWorkers;
  final int initialMilitaryUnits;
  final int initialTreasury;
  final List<_ScriptTurn> turns;
}

ParsedScript parseSimEconomyScript(Map<String, dynamic> json) {
  final initial = json['initialState'] as Map<String, dynamic>? ?? {};
  final stockpileJson =
      (initial['stockpile'] as Map<String, dynamic>?) ?? const {};
  final workersJson =
      (initial['workers'] as Map<String, dynamic>?) ?? const {};

  final stockpile = Stockpile.fromJson({
    'quantities': stockpileJson,
  });
  final workers = WorkerPool.fromJson(workersJson);
  final militaryUnits = (initial['militaryUnits'] as int?) ?? 0;
  final treasury = (initial['treasury'] as int?) ?? 0;

  final turnsList = (json['turns'] as List<dynamic>? ?? [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();

  final parsedTurns = <_ScriptTurn>[];
  for (final t in turnsList) {
    final turnIndex = t['turn'] as int? ?? (parsedTurns.length + 1);
    final extractionRaw = t['extraction'];
    final extraction = <CommodityId, int>{};
    if (extractionRaw is Map<String, dynamic>) {
      extractionRaw.forEach((k, v) {
        extraction[k] = v is int ? v : int.tryParse('$v') ?? 0;
      });
    } else if (extractionRaw is Map) {
      extractionRaw.forEach((k, v) {
        extraction['$k'] = v is int ? v : int.tryParse('$v') ?? 0;
      });
    }

    final assignmentsRaw =
        t['workerAssignments'] as List<dynamic>? ?? const [];
    final assignments = <AssignedRecipe>[];
    for (final a in assignmentsRaw) {
      final map = Map<String, dynamic>.from(a as Map);
      final id = map['recipeId'] as String?;
      final labour = map['assignedLabour'] as int? ?? 0;
      if (id == null || labour <= 0) continue;
      assignments.add(AssignedRecipe(recipeId: id, assignedLabour: labour));
    }

    parsedTurns.add(
      _ScriptTurn(
        turn: turnIndex,
        extraction: extraction,
        assignments: assignments,
      ),
    );
  }

  return ParsedScript(
    initialStockpile: stockpile,
    initialWorkers: workers,
    initialMilitaryUnits: militaryUnits,
    initialTreasury: treasury,
    turns: parsedTurns,
  );
}

extension AssignedRecipeCopy on AssignedRecipe {
  AssignedRecipe copyWith({int? assignedLabour}) {
    return AssignedRecipe(
      recipeId: recipeId,
      assignedLabour: assignedLabour ?? this.assignedLabour,
    );
  }
}

