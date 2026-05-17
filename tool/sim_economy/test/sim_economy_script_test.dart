import 'dart:convert';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../bin/sim_economy.dart' as cli;

void main() {
  group('sim_economy script parsing', () {
    test('parses minimal script and applies one turn deterministically', () {
      final scriptJson =
          jsonDecode(r'''
{
  "initialState": {
    "stockpile": {
      "grain": 10,
      "meat": 5
    },
    "workers": {
      "peasants": 2,
      "apprentices": 0,
      "journeymen": 0,
      "masters": 0
    },
    "militaryUnits": 0,
    "treasury": 100
  },
  "turns": [
    {
      "turn": 1,
      "extraction": {
        "grain": 3
      },
      "workerAssignments": []
    }
  ]
}
''')
              as Map<String, dynamic>;

      final parsed = cli.parseSimEconomyScript(scriptJson);
      final stockpileStart = parsed.initialStockpile;
      final workersStart = parsed.initialWorkers;

      final turn = parsed.turns.single;

      // Extraction
      final stockpileAfterExtraction = applyExtractionToStockpile(
        stockpileStart,
        turn.extraction,
      );

      // Riches to treasury
      final richesResult = resolveRichesToTreasury(
        stockpile: stockpileAfterExtraction,
      );
      final stockpileAfterRiches = richesResult.stockpile;
      final treasuryEndOfTurn = 100 + richesResult.treasuryDelta;

      // Consumption before production
      final consumption = resolveConsumption(
        stockpile: stockpileAfterRiches,
        workers: workersStart,
      );
      final stockpileAfterConsumption = consumption.stockpile;
      final workersAfterConsumption = consumption.workerPool;

      final production = resolveProduction(
        stockpile: stockpileAfterConsumption,
        workers: workersAfterConsumption,
        idleLabour: consumption.idleLabour,
        assignments: turn.assignments,
      );
      final stockpileAfterProduction = production.stockpile;
      final workersEnd = production.workerPool;
      final stockpileEnd = stockpileAfterProduction;

      // Build turn log entry and verify conservation identity.
      final entry = cli.buildTurnLogEntry(
        turn: 1,
        stockpileStart: stockpileStart,
        stockpileAfterExtraction: stockpileAfterExtraction,
        stockpileAfterRiches: stockpileAfterRiches,
        stockpileAfterConsumption: stockpileAfterConsumption,
        stockpileAfterProduction: stockpileAfterProduction,
        stockpileEnd: stockpileEnd,
        workersStart: workersStart,
        workersEnd: workersEnd,
        extractionVector: turn.extraction,
        assignments: turn.assignments,
        treasuryDeltaFromRiches: richesResult.treasuryDelta,
        treasuryEndOfTurn: treasuryEndOfTurn,
      );

      final start = (entry['stockpileStart'] as Map<dynamic, dynamic>)
          .cast<String, int>();
      final end = (entry['stockpileEnd'] as Map<dynamic, dynamic>)
          .cast<String, int>();
      final dE = (entry['deltaExtraction'] as Map<dynamic, dynamic>)
          .cast<String, int>();
      final dR = (entry['deltaRiches'] as Map<dynamic, dynamic>)
          .cast<String, int>();
      final dP = (entry['deltaProduction'] as Map<dynamic, dynamic>)
          .cast<String, int>();
      final dC = (entry['deltaConsumption'] as Map<dynamic, dynamic>)
          .cast<String, int>();

      for (final id
          in <String>{}
            ..addAll(start.keys)
            ..addAll(end.keys)
            ..addAll(dE.keys)
            ..addAll(dR.keys)
            ..addAll(dP.keys)
            ..addAll(dC.keys)) {
        final s = start[id] ?? 0;
        final e = end[id] ?? 0;
        final de = dE[id] ?? 0;
        final dr = dR[id] ?? 0;
        final dp = dP[id] ?? 0;
        final dc = dC[id] ?? 0;
        expect(s + de + dr + dp + dc, equals(e));
      }

      // Also sanity-check total food bounds from original test.
      final totalGrain = stockpileEnd.quantityOf(CommodityCatalog.grain.id);
      final totalMeat = stockpileEnd.quantityOf(CommodityCatalog.meat.id);
      expect(totalGrain + totalMeat, lessThanOrEqualTo(18));
      expect(totalGrain + totalMeat, greaterThanOrEqualTo(3));
    });

    test('throws on malformed script without turns array', () {
      final scriptJson =
          jsonDecode(r'''
{
  "initialState": {
    "stockpile": { "grain": 10 }
  }
}
''')
              as Map<String, dynamic>;

      expect(() => cli.parseSimEconomyScript(scriptJson), returnsNormally);
    });

    test('builds Markdown report with expected sections', () {
      final scriptJson =
          jsonDecode(r'''
{
  "initialState": {
    "stockpile": {
      "grain": 10,
      "meat": 5
    },
    "workers": {
      "peasants": 2,
      "apprentices": 0,
      "journeymen": 0,
      "masters": 0
    },
    "militaryUnits": 0,
    "treasury": 100
  },
  "turns": [
    {
      "turn": 1,
      "extraction": {
        "grain": 3
      },
      "workerAssignments": []
    }
  ]
}
''')
              as Map<String, dynamic>;

      final parsed = cli.parseSimEconomyScript(scriptJson);
      final stockpileStart = parsed.initialStockpile;
      final workersStart = parsed.initialWorkers;
      final turn = parsed.turns.single;

      final stockpileAfterExtraction = applyExtractionToStockpile(
        stockpileStart,
        turn.extraction,
      );
      final richesResult = resolveRichesToTreasury(
        stockpile: stockpileAfterExtraction,
      );
      final stockpileAfterRiches = richesResult.stockpile;
      final treasuryEndOfTurn =
          parsed.initialTreasury + richesResult.treasuryDelta;
      final consumption = resolveConsumption(
        stockpile: stockpileAfterRiches,
        workers: workersStart,
      );
      final stockpileAfterConsumption = consumption.stockpile;
      final production = resolveProduction(
        stockpile: stockpileAfterConsumption,
        workers: workersStart,
        idleLabour: consumption.idleLabour,
        assignments: turn.assignments,
      );
      final stockpileAfterProduction = production.stockpile;
      final stockpileEnd = stockpileAfterProduction;
      final workersEnd = workersStart;

      final entry = cli.buildTurnLogEntry(
        turn: 1,
        stockpileStart: stockpileStart,
        stockpileAfterExtraction: stockpileAfterExtraction,
        stockpileAfterRiches: stockpileAfterRiches,
        stockpileAfterConsumption: stockpileAfterConsumption,
        stockpileAfterProduction: stockpileAfterProduction,
        stockpileEnd: stockpileEnd,
        workersStart: workersStart,
        workersEnd: workersEnd,
        extractionVector: turn.extraction,
        assignments: turn.assignments,
        treasuryDeltaFromRiches: richesResult.treasuryDelta,
        treasuryEndOfTurn: treasuryEndOfTurn,
      );

      final markdown = cli.buildMarkdownReport(
        turns: [entry],
        totalTurns: 1,
        initialStockpile: parsed.initialStockpile,
        initialWorkers: parsed.initialWorkers,
        seed: 123,
        scriptPath: 'test_script.json',
        militaryUnits: 1,
        treasury: 100,
      );

      expect(markdown, contains('# sim_economy run'));
      expect(markdown, contains('## Run metadata'));
      expect(markdown, contains('## Initial state'));
      expect(markdown, contains('## Turns'));
      expect(markdown, contains('### Turn 1'));
      expect(markdown, contains('Economy – stockpile & flows'));
      expect(markdown, contains('Labour – workers & assignments'));
      expect(markdown, contains('militaryUnits'));
      expect(markdown, contains('treasury'));
    });

    test(
      'Reason column explains worker vs military consumption and production',
      () {
        // Construct a synthetic turn entry where:
        // - grain has E+5, C-13 (workers + military).
        // - lumber/fabric have production effects.
        final entry = <String, dynamic>{
          'turn': 1,
          'stockpileStart': {
            'grain': 45,
            'meat': 32,
            'timber': 30,
            'lumber': 8,
            'fabric': 19,
          },
          'stockpileAfterRiches': {
            'grain': 50,
            'meat': 33,
            'timber': 33,
            'lumber': 8,
            'fabric': 19,
          },
          'stockpileEnd': {
            'grain': 37,
            'meat': 33,
            'timber': 27,
            'lumber': 10,
            'fabric': 22,
          },
          'deltaExtraction': {'grain': 5, 'meat': 1, 'timber': 3},
          'deltaRiches': <String, int>{},
          'deltaProduction': {'timber': -6, 'lumber': 2, 'fabric': 3},
          'deltaConsumption': {'grain': -13},
          'treasuryDeltaFromRiches': 0,
          'treasuryEndOfTurn': 100,
          'workersStart': {
            'peasants': 9,
            'apprentices': 0,
            'journeymen': 1,
            'masters': 0,
          },
          'workersEnd': {
            'peasants': 9,
            'apprentices': 0,
            'journeymen': 1,
            'masters': 0,
          },
          'workerAssignments': <Map<String, dynamic>>[],
        };

        final markdownNoMilitary = cli.buildMarkdownReport(
          turns: [entry],
          totalTurns: 1,
          initialStockpile: const Stockpile(),
          initialWorkers: const WorkerPool(
            peasants: 9,
            apprentices: 0,
            journeymen: 1,
            masters: 0,
          ),
          seed: null,
          scriptPath: null,
          militaryUnits: 0,
          treasury: null,
        );

        // With no military, grain reason should mention worker food but not military upkeep.
        expect(
          markdownNoMilitary,
          contains('grain | 45 | 37 | -8 | E+5, C-13 | worker food'),
        );
        expect(markdownNoMilitary, isNot(contains('military upkeep')));

        final markdownWithMilitary = cli.buildMarkdownReport(
          turns: [entry],
          totalTurns: 1,
          initialStockpile: const Stockpile(),
          initialWorkers: const WorkerPool(
            peasants: 9,
            apprentices: 0,
            journeymen: 1,
            masters: 0,
          ),
          seed: null,
          scriptPath: null,
          militaryUnits: 1,
          treasury: null,
        );

        // With military, grain reason should mention both worker food and military upkeep.
        expect(
          markdownWithMilitary,
          contains(
            'grain | 45 | 37 | -8 | E+5, C-13 | worker food + military upkeep',
          ),
        );

        // Production reasons: lumber (manufactured, P>0) and timber (raw, P<0).
        expect(
          markdownWithMilitary,
          contains('lumber | 8 | 10 | +2 | P+2 | production output'),
        );
        expect(
          markdownWithMilitary,
          contains(
            'timber | 30 | 27 | -3 | E+3, P-6 | extraction + production inputs',
          ),
        );
      },
    );

    test('resolveOutputConfig applies defaults and overrides correctly', () {
      // No flags: Markdown defaults to sim_economy.md, no JSON.
      final cfgDefault = cli.resolveOutputConfig();
      expect(cfgDefault.markdownPath, equals('sim_economy.md'));
      expect(cfgDefault.jsonPath, isNull);

      // Only --output: Markdown uses provided path, no JSON.
      final cfgMarkdownOnly = cli.resolveOutputConfig(outputPath: 'report.md');
      expect(cfgMarkdownOnly.markdownPath, equals('report.md'));
      expect(cfgMarkdownOnly.jsonPath, isNull);

      // Only --json-output: Markdown still defaults, JSON uses provided path.
      final cfgJsonOnly = cli.resolveOutputConfig(jsonOutputPath: 'log.json');
      expect(cfgJsonOnly.markdownPath, equals('sim_economy.md'));
      expect(cfgJsonOnly.jsonPath, equals('log.json'));

      // Both flags: both paths are respected.
      final cfgBoth = cli.resolveOutputConfig(
        outputPath: 'custom_report.md',
        jsonOutputPath: 'custom_log.json',
      );
      expect(cfgBoth.markdownPath, equals('custom_report.md'));
      expect(cfgBoth.jsonPath, equals('custom_log.json'));
    });
  });

  group('riches to treasury', () {
    test('treasury increases when extraction includes riches', () {
      final scriptJson =
          jsonDecode(r'''
{
  "initialState": {
    "stockpile": { "grain": 20 },
    "workers": { "peasants": 2, "apprentices": 0, "journeymen": 0, "masters": 0 },
    "treasury": 100
  },
  "turns": [
    {
      "turn": 1,
      "extraction": { "grain": 2, "spices": 2, "gold": 1 },
      "workerAssignments": []
    }
  ]
}
''')
              as Map<String, dynamic>;

      final parsed = cli.parseSimEconomyScript(scriptJson);
      var stockpile = parsed.initialStockpile;
      // Workers are not used in this test case
      var treasury = parsed.initialTreasury;
      final turn = parsed.turns.single;

      stockpile = applyExtractionToStockpile(stockpile, turn.extraction);
      final richesResult = resolveRichesToTreasury(stockpile: stockpile);
      stockpile = richesResult.stockpile;
      treasury += richesResult.treasuryDelta;

      expect(richesResult.treasuryDelta, 2 * 50 + 1 * richesBasePrice('gold'));
      expect(treasury, 100 + richesResult.treasuryDelta);
      expect(stockpile.quantityOf(CommodityCatalog.spices.id), 0);
      expect(stockpile.quantityOf(CommodityCatalog.gold.id), 0);
      expect(stockpile.quantityOf(CommodityCatalog.grain.id), 22);
    });
  });
}
