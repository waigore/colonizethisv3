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
      var currentContext = context;
      if (scenario.setup != null) {
        currentContext = ScenarioContext(
          game: _applySetup(currentContext.game, scenario.setup!),
          topology: currentContext.topology,
          tileMapByRegion: currentContext.tileMapByRegion,
        );
      }

      // 3. Run each turn
      final turnResults = <int, TurnResult>{};
      
      for (final turnScript in scenario.turns) {
        // Parse orders
        final orders = parseOrderCommands(turnScript.orders, currentContext.game);
        
        // Resolve turn (returns updated game)
        final nextGame = _resolveTurn(currentContext, orders, scenario);
        currentContext = ScenarioContext(
          game: nextGame,
          topology: currentContext.topology,
          tileMapByRegion: currentContext.tileMapByRegion,
        );
        
        // Verify assertions for this turn
        final assertionResults = _verifyTurnAssertions(currentContext.game, scenario.assertions, turnScript.turn);
        
        turnResults[turnScript.turn] = TurnResult(
          turnNumber: turnScript.turn,
          assertionResults: assertionResults,
        );
      }

      // 4. Verify final assertions (those without turn specified)
      final finalAssertions = scenario.assertions.where((a) => a.turn == null).toList();
      final finalResult = verifier.verify(currentContext.game, finalAssertions);
      
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
        finalState: currentContext.game,
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
    } else if (scenario.init.type == 'fromTopology') {
      final result = await gameFactory.createFromTopology(scenario.init);
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

  /// Applies scenario setup (unit injection, etc.). Returns updated game.
  Game _applySetup(Game game, ScenarioSetup setup) {
    if (setup.units != null && setup.units!.isNotEmpty) {
      final owUnits = <Unit>[];
      final nwUnits = <Unit>[];
      for (final placement in setup.units!) {
        final fullProvinceId = placement.provinceId.contains('|')
            ? placement.provinceId
            : 'oldWorld|${placement.provinceId}';
        final regionId = fullProvinceId.startsWith('newWorld|')
            ? 'newWorld'
            : 'oldWorld';
        final type = placement.unitType;
        for (var k = 0; k < placement.count; k++) {
          final unitId =
              '${placement.playerId}_${type.toLowerCase().replaceAll(' ', '_')}_$k';
          final unit = Unit(
            id: unitId,
            type: type,
            ownerId: placement.playerId,
            provinceId: fullProvinceId,
            status: UnitStatus.idle,
            medals: 0,
          );
          if (regionId == 'oldWorld') {
            owUnits.add(unit);
          } else {
            nwUnits.add(unit);
          }
        }
      }
      final newOw = RegionData(
        provinces: game.worldState.oldWorld.provinces,
        units: [...game.worldState.oldWorld.units, ...owUnits],
      );
      final newNw = RegionData(
        provinces: game.worldState.newWorld.provinces,
        units: [...game.worldState.newWorld.units, ...nwUnits],
      );
      game = game.copyWith(
        worldState: game.worldState.copyWith(
          oldWorld: newOw,
          newWorld: newNw,
        ),
      );
    }
    // Apply initialWorkers and initialStockpile (SPEC/game/workers-and-population.md).
    var players = game.players;
    if (setup.initialWorkers != null || setup.initialStockpile != null) {
      players = [
        for (final player in game.players)
          _applyPlayerEconomyOverrides(player, setup),
      ];
    }
    if (players != game.players) {
      game = game.copyWith(players: players);
    }
    if (setup.initialStockpile != null && setup.initialStockpile!.isNotEmpty) {
      final updatedPlayers = <Player>[];
      for (final player in game.players) {
        final quantities = setup.initialStockpile![player.id];
        if (quantities == null || quantities.isEmpty) {
          updatedPlayers.add(player);
          continue;
        }
        var stockpile = const Stockpile();
        for (final entry in quantities.entries) {
          if (entry.value > 0) {
            stockpile = stockpile.applyDelta(entry.key, entry.value);
          }
        }
        updatedPlayers.add(player.copyWith(stockpile: stockpile));
      }
      game = game.copyWith(players: updatedPlayers);
    }
    if (setup.initialWorkers != null && setup.initialWorkers!.isNotEmpty) {
      final updatedPlayers = <Player>[];
      for (final player in game.players) {
        final counts = setup.initialWorkers![player.id];
        if (counts == null || counts.isEmpty) {
          updatedPlayers.add(player);
          continue;
        }
        final pool = WorkerPool(
          peasants: counts['peasants'] ?? 0,
          apprentices: counts['apprentices'] ?? 0,
          journeymen: counts['journeymen'] ?? 0,
          masters: counts['masters'] ?? 0,
        );
        updatedPlayers.add(player.copyWith(workerPool: pool));
      }
      game = game.copyWith(players: updatedPlayers);
    }
    return game;
  }

  Player _applyPlayerEconomyOverrides(Player player, ScenarioSetup setup) {
    var p = player;
    if (setup.initialWorkers != null) {
      final w = setup.initialWorkers![player.id];
      if (w != null) {
        p = p.copyWith(
          workerPool: WorkerPool(
            peasants: w['peasants'] ?? 0,
            apprentices: w['apprentices'] ?? 0,
            journeymen: w['journeymen'] ?? 0,
            masters: w['masters'] ?? 0,
          ),
        );
      }
    }
    if (setup.initialStockpile != null) {
      final s = setup.initialStockpile![player.id];
      if (s != null && s.isNotEmpty) {
        p = p.copyWith(stockpile: Stockpile(quantities: Map<String, int>.from(s)));
      }
    }
    return p;
  }

  /// Resolves one turn and returns the updated game.
  Game _resolveTurn(ScenarioContext context, Orders orders, Scenario scenario) {
    final topology = context.topology;
    if (topology == null) {
      throw StateError('Topology required for turn resolution');
    }

    final defaultAssignments = _productionAssignments(scenario);

    final orderEngine = OrderEngine(initialOrders: orders);
    return resolveTurnForGameFromOrderEngine(
      game: context.game,
      topology: topology,
      orderEngine: orderEngine,
      aiOrders: null,
      tileMapByRegion: context.tileMapByRegion,
      defaultAssignments: defaultAssignments,
    );
  }

  /// Converts scenario setup productionAssignments to AssignedRecipe list for resolver.
  List<AssignedRecipe> _productionAssignments(Scenario scenario) {
    final list = scenario.setup?.productionAssignments;
    if (list == null || list.isEmpty) return const [];
    return list
        .map((a) => AssignedRecipe(
              recipeId: a.recipeId,
              assignedLabour: a.assignedLabour,
            ))
        .toList();
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
