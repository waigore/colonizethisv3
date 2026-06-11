// Scenario runner - executes scenarios and collects results.

import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'game_factory.dart';
import 'order_script.dart';
import 'scenario.dart';
import 'seaboard_port_audit.dart';
import 'state_verifier.dart';

/// Holds game state for scenario execution.
class ScenarioContext {
  const ScenarioContext({
    required this.game,
    this.topology,
    this.topologyByRegion,
    this.tileMapByRegion,
  });

  final Game game;
  final MapTopology? topology;
  final Map<String, MapTopology>? topologyByRegion;
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
    this.seaboardPortAudit,
  });

  final String scenarioName;
  final bool passed;
  final List<String> failures;
  final Game? finalState;
  final Map<int, TurnResult> turnResults;

  /// GitHub #1766 — null if audit did not run (e.g. init failed before context).
  final SeaboardPortAuditOutcome? seaboardPortAudit;
}

/// Result of a single turn within a scenario.
class TurnResult {
  const TurnResult({required this.turnNumber, required this.assertionResults});

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
  const BatchResult({required this.results, required this.runTime});

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
          topologyByRegion: currentContext.topologyByRegion,
          tileMapByRegion: currentContext.tileMapByRegion,
        );
      }

      final maps = currentContext.tileMapByRegion;
      final topoByRegion = currentContext.topologyByRegion;
      final SeaboardPortAuditOutcome portAudit;
      if (maps != null &&
          topoByRegion != null &&
          maps.isNotEmpty &&
          topoByRegion.isNotEmpty) {
        portAudit = runSeaboardPortAudit(
          game: currentContext.game,
          tileMapByRegion: maps,
          topologyByRegion: topoByRegion,
        );
      } else {
        portAudit = SeaboardPortAuditOutcome(
          skipped: true,
          skipReason:
              'missing tileMapByRegion or topologyByRegion (e.g. saved-game init without maps)',
        );
      }

      // 3. Run each turn
      final turnResults = <int, TurnResult>{};

      for (final turnScript in scenario.turns) {
        final gameForTurn = ensureMilitaryArmiesForGame(currentContext.game);
        final contextForTurn = ScenarioContext(
          game: gameForTurn,
          topology: currentContext.topology,
          topologyByRegion: currentContext.topologyByRegion,
          tileMapByRegion: currentContext.tileMapByRegion,
        );
        // Parse orders
        final orders = parseOrderCommands(turnScript.orders, gameForTurn);

        // Resolve turn (returns updated game). Use per-turn workerAssignments when
        // present; otherwise fall back to scenario-level productionAssignments.
        // When resolution blocks on human overture decisions, turnScript.overtureDecisions are applied.
        final nextGame = _resolveTurn(
          contextForTurn,
          orders,
          scenario,
          turnScript.workerAssignments,
          turnScript,
        );
        currentContext = ScenarioContext(
          game: nextGame,
          topology: currentContext.topology,
          topologyByRegion: currentContext.topologyByRegion,
          tileMapByRegion: currentContext.tileMapByRegion,
        );

        // Verify assertions for this turn
        final assertionResults = _verifyTurnAssertions(
          currentContext.game,
          scenario.assertions,
          turnScript.turn,
        );

        turnResults[turnScript.turn] = TurnResult(
          turnNumber: turnScript.turn,
          assertionResults: assertionResults,
        );
      }

      // 4. Verify final assertions (those without turn specified)
      final finalAssertions = scenario.assertions
          .where((a) => a.turn == null)
          .toList();
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

      if (!portAudit.skipped && !portAudit.passed) {
        allFailures.addAll(portAudit.failures.map((f) => f.message));
      }

      return ScenarioResult(
        scenarioName: scenario.name,
        passed: allFailures.isEmpty,
        failures: allFailures,
        finalState: currentContext.game,
        turnResults: turnResults,
        seaboardPortAudit: portAudit,
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

    return BatchResult(results: results, runTime: DateTime.now());
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
    switch (scenario.init.type) {
      case 'fresh':
        return _initializeFreshGame(scenario);
      case 'fromTopology':
        return _initializeFromTopology(scenario);
      case 'saved':
        return _initializeSavedGame(scenario);
      default:
        return null;
    }
  }

  Future<ScenarioContext> _initializeFreshGame(Scenario scenario) async {
    final result = scenario.init.config != null
        ? await gameFactory.createFreshGameFromJson(scenario.init.config!)
        : await gameFactory.createFreshGame(GameSetupConfig(seed: 42));
    return _toScenarioContext(result);
  }

  Future<ScenarioContext> _initializeFromTopology(Scenario scenario) async {
    final result = await gameFactory.createFromTopology(scenario.init);
    return _toScenarioContext(result);
  }

  Future<ScenarioContext?> _initializeSavedGame(Scenario scenario) async {
    final gameId = scenario.init.gameId;
    if (gameId == null) {
      return null;
    }
    final game = await gameFactory.loadSavedGame(gameId);
    if (game == null) {
      return null;
    }
    return ScenarioContext(game: game);
  }

  ScenarioContext _toScenarioContext(GameInitResult result) {
    return ScenarioContext(
      game: result.game,
      topology: result.topology,
      topologyByRegion: result.topologyByRegion,
      tileMapByRegion: result.tileMapByRegion,
    );
  }

  /// Applies scenario setup (unit injection, etc.). Returns updated game.
  Game _applySetup(Game game, ScenarioSetup setup) {
    var updated = game;
    updated = _applyUnitPlacements(updated, setup);
    updated = _applyInitialFleets(updated, setup);
    updated = _applyPlayerEconomyDefaults(updated, setup);
    updated = _applyInitialStockpile(updated, setup);
    updated = _applyInitialWorkers(updated, setup);
    updated = _applyInitialTileState(updated, setup);
    updated = _applyLeaderKeys(updated, setup);
    updated = _applyInitialTech(updated, setup);
    updated = _applyDefaultCombatMode(updated, setup);
    updated = _applyInitialTreasury(updated, setup);
    updated = _applyPurchasedTiles(updated, setup);
    return updated;
  }

  Game _applyUnitPlacements(Game game, ScenarioSetup setup) {
    final placements = setup.units;
    if (placements == null || placements.isEmpty) {
      return game;
    }
    final owUnits = <Unit>[];
    final nwUnits = <Unit>[];
    for (final placement in placements) {
      final fullProvinceId = placement.provinceId.contains('|')
          ? placement.provinceId
          : 'oldWorld|${placement.provinceId}';
      final isNewWorld = fullProvinceId.startsWith('newWorld|');
      final type = placement.unitType;
      for (var k = 0; k < placement.count; k++) {
        final unit = Unit(
          id: '${placement.playerId}_${type.toLowerCase().replaceAll(' ', '_')}_$k',
          type: type,
          ownerId: placement.playerId,
          locationProvinceId: fullProvinceId,
          status: UnitStatus.idle,
          medals: 0,
        );
        if (isNewWorld) {
          nwUnits.add(unit);
        } else {
          owUnits.add(unit);
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
    return game.copyWith(
      worldState: game.worldState.copyWith(oldWorld: newOw, newWorld: newNw),
    );
  }

  Game _applyInitialFleets(Game game, ScenarioSetup setup) {
    final initialFleets = setup.initialFleets;
    if (initialFleets == null || initialFleets.isEmpty) {
      return game;
    }
    final fleets = initialFleets
        .map(
          (f) => Fleet(
            id: f.id,
            ownerId: f.ownerId,
            seaZoneId: f.seaZoneId,
            inPortAtProvinceId: f.inPortAtProvinceId,
            regionId: f.regionId,
            shipTypeIds: f.shipTypeIds,
            mission: FleetMission.values.firstWhere(
              (m) => m.name == f.mission,
              orElse: () => FleetMission.none,
            ),
          ),
        )
        .toList();
    return game.copyWith(worldState: game.worldState.copyWith(fleets: fleets));
  }

  Game _applyPlayerEconomyDefaults(Game game, ScenarioSetup setup) {
    if (setup.initialWorkers == null && setup.initialStockpile == null) {
      return game;
    }
    final players = [
      for (final player in game.players)
        _applyPlayerEconomyOverrides(player, setup),
    ];
    return game.copyWith(players: players);
  }

  Game _applyInitialStockpile(Game game, ScenarioSetup setup) {
    final initialStockpile = setup.initialStockpile;
    if (initialStockpile == null || initialStockpile.isEmpty) {
      return game;
    }
    final updatedPlayers = <Player>[];
    for (final player in game.players) {
      final quantities = initialStockpile[player.id];
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
    return game.copyWith(players: updatedPlayers);
  }

  Game _applyInitialWorkers(Game game, ScenarioSetup setup) {
    final initialWorkers = setup.initialWorkers;
    if (initialWorkers == null || initialWorkers.isEmpty) {
      return game;
    }
    final updatedPlayers = <Player>[];
    for (final player in game.players) {
      final counts = initialWorkers[player.id];
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
    return game.copyWith(players: updatedPlayers);
  }

  Game _applyInitialTileState(Game game, ScenarioSetup setup) {
    final initialTileState = setup.initialTileState;
    if (initialTileState == null || initialTileState.isEmpty) {
      return game;
    }
    var tileState = game.worldState.tileState;
    for (final entry in initialTileState.entries) {
      final tileKey = entry.key;
      final opts = entry.value;
      final imp = opts['improvementLevel'];
      final road = opts['roadLevel'];
      if (imp != null) tileState = tileState.setImprovement(tileKey, imp);
      if (road != null) tileState = tileState.setRoadLevel(tileKey, road);
    }
    return game.copyWith(
      worldState: game.worldState.copyWith(tileState: tileState),
    );
  }

  Game _applyLeaderKeys(Game game, ScenarioSetup setup) {
    final leaderKeys = setup.leaderKeys;
    if (leaderKeys == null || leaderKeys.isEmpty) {
      return game;
    }
    final updatedPlayers = <Player>[];
    for (final player in game.players) {
      final key = leaderKeys[player.id];
      if (key == null) {
        updatedPlayers.add(player);
        continue;
      }
      updatedPlayers.add(player.copyWith(leaderKey: key));
    }
    return game.copyWith(players: updatedPlayers);
  }

  Game _applyInitialTech(Game game, ScenarioSetup setup) {
    final initialTech = setup.initialTech;
    if (initialTech == null || initialTech.isEmpty) {
      return game;
    }
    final updatedPlayers = <Player>[];
    for (final player in game.players) {
      final techIds = initialTech[player.id];
      if (techIds == null || techIds.isEmpty) {
        updatedPlayers.add(player);
        continue;
      }
      final techUnlocked = Map<String, bool>.from(player.techUnlocked ?? {});
      for (final tid in techIds) {
        techUnlocked[tid] = true;
      }
      final militaryLevel = militaryLevelForUnlocked(techUnlocked);
      updatedPlayers.add(
        player.copyWith(
          techUnlocked: techUnlocked,
          militaryLevel: militaryLevel,
        ),
      );
    }
    final updatedGame = game.copyWith(players: updatedPlayers);
    return _applyGeneralCapFromTech(updatedGame);
  }

  Game _applyDefaultCombatMode(Game game, ScenarioSetup setup) {
    final defaultCombatMode = setup.defaultCombatMode;
    if (defaultCombatMode == null || defaultCombatMode.isEmpty) {
      return game;
    }
    final raw = defaultCombatMode.toLowerCase();
    final mode = (raw == 'quickbattle' || raw == 'quick_battle')
        ? CombatMode.quickBattle
        : CombatMode.autoResolve;
    return game.copyWith(defaultCombatMode: mode);
  }

  Game _applyInitialTreasury(Game game, ScenarioSetup setup) {
    final initialTreasury = setup.initialTreasury;
    if (initialTreasury == null || initialTreasury.isEmpty) {
      return game;
    }
    final updatedPlayers = <Player>[];
    for (final player in game.players) {
      final treasury = initialTreasury[player.id];
      if (treasury == null) {
        updatedPlayers.add(player);
        continue;
      }
      updatedPlayers.add(player.copyWith(treasury: treasury));
    }
    return game.copyWith(players: updatedPlayers);
  }

  Game _applyPurchasedTiles(Game game, ScenarioSetup setup) {
    final purchasedTilesByTileKey = setup.purchasedTilesByTileKey;
    if (purchasedTilesByTileKey == null || purchasedTilesByTileKey.isEmpty) {
      return game;
    }
    final purchased = Map<String, String>.from(
      game.worldState.purchasedTilesByTileKey,
    )..addAll(purchasedTilesByTileKey);
    return game.copyWith(
      worldState: game.worldState.copyWith(purchasedTilesByTileKey: purchased),
    );
  }

  /// SPEC/game/military-generals.md: general cap from tech. Ensures each GP has exactly cap many generals.
  static int _generalCapFromTech(Map<String, bool>? techUnlocked) {
    final t = techUnlocked ?? {};
    var cap = 1;
    if (t[kTechIdOrganisedRegiments] == true) cap = 2;
    if (t[kTechIdNationalBureaucracy] == true ||
        t[kTechIdImprovedInfantryTactics] == true)
      cap = 3;
    if (t[kTechIdNationalism] == true) cap = 4;
    return cap;
  }

  static Game _applyGeneralCapFromTech(Game game) {
    final newGenerals = <General>[];
    for (final player in game.players) {
      final cap = _generalCapFromTech(player.techUnlocked);
      final existing = game.generals
          .where((g) => g.ownerId == player.id)
          .toList();
      for (var i = 0; i < cap; i++) {
        if (i < existing.length) {
          newGenerals.add(existing[i]);
        } else {
          newGenerals.add(
            General(id: '${player.id}_gen_$i', ownerId: player.id, medals: 0),
          );
        }
      }
    }
    return game.copyWith(generals: newGenerals);
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
        p = p.copyWith(
          stockpile: Stockpile(quantities: Map<String, int>.from(s)),
        );
      }
    }
    return p;
  }

  /// Resolves one turn and returns the updated game.
  /// When resolution returns [TurnResolutionPendingOvertures], [turnScript.overtureDecisions]
  /// must be non-null; they are applied via resumeTurnResolutionWithOvertureDecisions.
  Game _resolveTurn(
    ScenarioContext context,
    Orders orders,
    Scenario scenario, [
    List<WorkerAssignment>? workerAssignments,
    TurnScript? turnScript,
  ]) {
    final topology = context.topology;
    if (topology == null) {
      throw StateError('Topology required for turn resolution');
    }

    final defaultAssignments =
        workerAssignments != null && workerAssignments.isNotEmpty
        ? workerAssignments
              .map(
                (w) => AssignedRecipe(
                  recipeId: w.recipeId,
                  assignedLabour: w.assignedLabour,
                ),
              )
              .toList()
        : _productionAssignments(scenario);

    final orderEngine = OrderEngine(initialOrders: orders);
    TurnResolutionResult result = resolveTurnForGameFromOrderEngine(
      game: context.game,
      topology: topology,
      orderEngine: orderEngine,
      aiOrders: null,
      tileMapByRegion: context.tileMapByRegion,
      defaultAssignments: defaultAssignments,
    );

    final resumeConfig = TurnResolverConfig(
      topology: topology,
      orders: orderEngine.orders,
      tileMapByRegion: context.tileMapByRegion,
      defaultAssignments: defaultAssignments,
    );

    while (true) {
      if (result is TurnResolutionComplete) {
        return result.game;
      }
      if (result is TurnResolutionPendingOvertures) {
        final decisions = turnScript?.overtureDecisions;
        if (decisions == null || decisions.isEmpty) {
          throw StateError(
            'Turn ${turnScript?.turn ?? 0} resolution is pending overture decisions '
            '(human GP target) but scenario has no overtureDecisions for this turn. '
            'Add overtureDecisions to the turn script.',
          );
        }
        final logicDecisions = decisions
            .map(
              (d) => OvertureDecision(
                offererGpId: d.offererGpId,
                targetFactionId: d.targetFactionId,
                stage: OvertureStage.values.firstWhere(
                  (e) => e.name == d.stage,
                  orElse: () => OvertureStage.none,
                ),
                accepted: d.accepted,
              ),
            )
            .toList();
        result = resumeTurnResolutionWithOvertureDecisions(
          game: result.game,
          pendingOvertures: result.pendingOvertures,
          decisions: logicDecisions,
          config: resumeConfig,
        );
        continue;
      }
      if (result is TurnResolutionPendingCallToArms) {
        final decisions = turnScript?.callToArmsDecisions;
        if (decisions == null || decisions.isEmpty) {
          throw StateError(
            'Turn ${turnScript?.turn ?? 0} resolution is pending call to arms '
            'but scenario has no callToArmsDecisions for this turn.',
          );
        }
        final logicDecisions = decisions
            .map(
              (d) => CallToArmsDecision(
                allyGpId: d.allyGpId,
                defenderGpId: d.defenderGpId,
                aggressorGpId: d.aggressorGpId,
                accepted: d.accepted,
              ),
            )
            .toList();
        result = resumeTurnResolutionWithCallToArmsDecisions(
          game: result.game,
          decisions: logicDecisions,
          config: resumeConfig,
        );
        continue;
      }
      throw StateError(
        'Unhandled turn resolution result: ${result.runtimeType}',
      );
    }
  }

  /// Converts scenario setup productionAssignments to AssignedRecipe list for resolver.
  List<AssignedRecipe> _productionAssignments(Scenario scenario) {
    final list = scenario.setup?.productionAssignments;
    if (list == null || list.isEmpty) return const [];
    return list
        .map(
          (a) => AssignedRecipe(
            recipeId: a.recipeId,
            assignedLabour: a.assignedLabour,
          ),
        )
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
      results.add(
        AssertionResult(
          assertion: assertion,
          passed: result.passed,
          failureMessage: result.failures.isNotEmpty
              ? result.failures.first
              : null,
        ),
      );
    }

    return results;
  }
}
