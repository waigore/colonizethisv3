// Scenario runner - executes scenarios and collects results.

import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'game_factory.dart';
import 'order_script.dart';
import 'scenario.dart';
import 'state_verifier.dart';

/// Holds game state for scenario execution.
class ScenarioContext {
  const ScenarioContext({
    required this.game,
    this.topology,
    this.tileMapByRegion,
  });

  final Game game;
  final MapTopology? topology;
  final Map<String, TileMapResult>? tileMapByRegion;
}

/// Result of running a single scenario.
class ScenarioResult {
  const ScenarioResult({
    required this.scenarioName,
    required this.passed,
    required this.failures,
    this.finalState,
    this.turnResults = const {},
  });

  final String scenarioName;
  final bool passed;
  final List<String> failures;
  final Game? finalState;
  final Map<int, TurnResult> turnResults;
}

/// Result of a single turn within a scenario.
class TurnResult {
  const TurnResult({
    required this.turnNumber,
    required this.assertionResults,
  });

  final int turnNumber;
  final List<AssertionResult> assertionResults;
}

/// Result of a single assertion.
class AssertionResult {
  const AssertionResult({
    required this.assertion,
    required this.passed,
    this.failureMessage,
  });

  final Assertion assertion;
  final bool passed;
  final String? failureMessage;
}

/// Result of running multiple scenarios.
class BatchResult {
  const BatchResult({
    required this.results,
    required this.runTime,
  });

  final List<ScenarioResult> results;
  final DateTime runTime;

  int get total => results.length;
  int get passed => results.where((r) => r.passed).length;
  int get failed => results.where((r) => !r.passed).length;
}

/// Runs scenarios.
class ScenarioRunner {
  ScenarioRunner({GameFactory? gameFactory})
      : gameFactory = gameFactory ?? GameFactory(),
        verifier = StateVerifier();

  final GameFactory gameFactory;
  final StateVerifier verifier;

  /// Runs a single scenario.
  Future<ScenarioResult> run(Scenario scenario) async {
    try {
      // 1. Initialize game
      final context = await _initializeGame(scenario);
      if (context == null) {
        return ScenarioResult(
          scenarioName: scenario.name,
          passed: false,
          failures: ['Failed to initialize game'],
        );
      }

      // 2. Apply setup if specified (for saved-game scenarios)
      if (scenario.setup != null) {
        _applySetup(context.game, scenario.setup!);
      }

      // 3. Run each turn
      final turnResults = <int, TurnResult>{};
      
      for (final turnScript in scenario.turns) {
        // Parse orders
        final orders = parseOrderCommands(turnScript.orders, context.game);
        
        // Resolve turn
        await _resolveTurn(context, orders);
        
        // Verify assertions for this turn
        final assertionResults = _verifyTurnAssertions(context.game, scenario.assertions, turnScript.turn);
        
        turnResults[turnScript.turn] = TurnResult(
          turnNumber: turnScript.turn,
          assertionResults: assertionResults,
        );
      }

      // 4. Verify final assertions (those without turn specified)
      final finalAssertions = scenario.assertions.where((a) => a.turn == null).toList();
      final finalResult = verifier.verify(context.game, finalAssertions);
      
      final allFailures = <String>[];
      for (final tr in turnResults.values) {
        for (final ar in tr.assertionResults) {
          if (!ar.passed && ar.failureMessage != null) {
            allFailures.add(ar.failureMessage!);
          }
        }
      }
      allFailures.addAll(finalResult.failures);

      return ScenarioResult(
        scenarioName: scenario.name,
        passed: allFailures.isEmpty,
        failures: allFailures,
        finalState: context.game,
        turnResults: turnResults,
      );
    } catch (e, stack) {
      return ScenarioResult(
        scenarioName: scenario.name,
        passed: false,
        failures: ['Error: $e\n$stack'],
      );
    }
  }

  /// Runs all scenarios in a directory.
  Future<BatchResult> runAll(Directory dir) async {
    final scenarios = discoverScenarios(dir);
    final results = <ScenarioResult>[];
    
    for (final scenario in scenarios) {
      print('Running scenario: ${scenario.name}...');
      final result = await run(scenario);
      results.add(result);
    }

    return BatchResult(
      results: results,
      runTime: DateTime.now(),
    );
  }

  /// Runs a scenario from a file.
  Future<ScenarioResult> runFile(File file) async {
    final scenarios = parseScenarioFile(file);
    if (scenarios.isEmpty) {
      return ScenarioResult(
        scenarioName: file.path,
        passed: false,
        failures: ['No scenarios found in file'],
      );
    }
    return run(scenarios.first);
  }

  Future<ScenarioContext?> _initializeGame(Scenario scenario) async {
    if (scenario.init.type == 'fresh') {
      GameInitResult result;
      if (scenario.init.config != null) {
        result = await gameFactory.createFreshGameFromJson(scenario.init.config!);
      } else {
        // Default fresh game
        result = await gameFactory.createFreshGame(GameSetupConfig(seed: 42));
      }
      return ScenarioContext(
        game: result.game,
        topology: result.topology,
        tileMapByRegion: result.tileMapByRegion,
      );
    } else if (scenario.init.type == 'saved') {
      if (scenario.init.gameId != null) {
        final game = await gameFactory.loadSavedGame(scenario.init.gameId!);
        if (game != null) {
          return ScenarioContext(game: game);
        }
      }
    }
    return null;
  }

  void _applySetup(Game game, ScenarioSetup setup) {
    // TODO: Implement unit injection for saved-game scenarios
    // This would add units to provinces as specified in setup.units
    if (setup.stockpileOverrides != null) {
      for (final player in game.players) {
        final override = setup.stockpileOverrides![player.id];
        if (override != null) {
          // Note: Player stockpile is final, need to create new instance
          // This is a simplified implementation
        }
      }
    }
  }

  Future<void> _resolveTurn(ScenarioContext context, Orders orders) async {
    final topology = context.topology;
    if (topology == null) {
      throw StateError('Topology required for turn resolution');
    }
    
    // Create order engine with the orders
    final orderEngine = OrderEngine(initialOrders: orders);
    
    // Resolve turn - this modifies context.game in place
    resolveTurnForGameFromOrderEngine(
      game: context.game,
      topology: topology,
      orderEngine: orderEngine,
      aiOrders: null, // Deterministic: no AI orders
      tileMapByRegion: context.tileMapByRegion,
    );
  }

  List<AssertionResult> _verifyTurnAssertions(
    Game game,
    List<Assertion> allAssertions,
    int turn,
  ) {
    final turnAssertions = allAssertions.where((a) => a.turn == turn).toList();
    final results = <AssertionResult>[];
    
    for (final assertion in turnAssertions) {
      final result = verifier.verify(game, [assertion], atTurn: turn);
      results.add(AssertionResult(
        assertion: assertion,
        passed: result.passed,
        failureMessage: result.failures.isNotEmpty ? result.failures.first : null,
      ));
    }
    
    return results;
  }
}
