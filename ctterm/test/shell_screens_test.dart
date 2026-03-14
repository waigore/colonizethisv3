// Tests for shell screens (ShellScreen, InGameShellScreen). SPEC/tui/ctterm.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:ctterm/screens/shell_screen.dart';
import 'package:ctterm/screens/in_game_shell_screen.dart';
import 'package:ctterm/ctterm_routes.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('ShellScreen (SPEC/tui/ctterm.md)', () {
    test('can be constructed with required parameters', () {
      final screen = ShellScreen(
        route: CttermRoute.mainMenu,
        onNavigate: (route) {},
        onExit: () {},
      );

      expect(screen.route, CttermRoute.mainMenu);
      expect(screen.onNavigate, isNotNull);
      expect(screen.onExit, isNotNull);
    });

    test('callbacks are invoked correctly', () {
      var navigateRoute = CttermRoute.mainMenu;
      var exitCount = 0;

      final screen = ShellScreen(
        route: CttermRoute.mainMenu,
        onNavigate: (route) => navigateRoute = route,
        onExit: () => exitCount++,
      );

      screen.onNavigate(CttermRoute.gameSetup);
      expect(navigateRoute, CttermRoute.gameSetup);

      screen.onExit();
      expect(exitCount, 1);
    });

    test('can be constructed with game parameter', () {
      final config = GameSetupConfig(
        selectedGreatPowerIds: List<String>.from(GameSetupConfig.defaultConfig.selectedGreatPowerIds),
        leaderVariantByGpId: {},
        seed: 42,
        continentCount: GameSetupConfig.defaultConfig.continentCount,
        minorNationCount: GameSetupConfig.defaultConfig.minorNationCount,
        tribeCount: GameSetupConfig.defaultConfig.tribeCount,
        numProvincesOldWorld: GameSetupConfig.defaultConfig.numProvincesOldWorld,
        numProvincesNewWorld: GameSetupConfig.defaultConfig.numProvincesNewWorld,
        minProvincesPerMinor: GameSetupConfig.defaultConfig.minProvincesPerMinor,
      );

      final initResult = runInitGame(
        config: config,
        options: const InitGameOptions(renderPng: false),
      );

      final screen = ShellScreen(
        route: CttermRoute.inGameShell,
        onNavigate: (route) {},
        onExit: () {},
        game: initResult.game,
      );

      expect(screen.game, isNotNull);
    });
  });

  group('InGameShellScreen (SPEC/tui/screens/in-game-shell.md)', () {
    test('can be constructed with required parameters', () {
      final screen = InGameShellScreen(
        orders: const Orders(),
        onNavigate: (route) {},
        onEndTurn: () async {},
        onVictory: () {},
        onDefeat: () {},
        onExitToMainMenu: () {},
      );

      expect(screen.onNavigate, isNotNull);
      expect(screen.onEndTurn, isNotNull);
      expect(screen.onVictory, isNotNull);
      expect(screen.onDefeat, isNotNull);
      expect(screen.onExitToMainMenu, isNotNull);
    });

    test('callbacks are invoked correctly', () {
      var navigateRoute = CttermRoute.mainMenu;
      var victoryCount = 0;
      var defeatCount = 0;
      var exitCount = 0;

      final screen = InGameShellScreen(
        orders: const Orders(),
        onNavigate: (route) => navigateRoute = route,
        onEndTurn: () async {},
        onVictory: () => victoryCount++,
        onDefeat: () => defeatCount++,
        onExitToMainMenu: () => exitCount++,
      );

      screen.onNavigate(CttermRoute.units);
      expect(navigateRoute, CttermRoute.units);

      screen.onVictory();
      expect(victoryCount, 1);

      screen.onDefeat();
      expect(defeatCount, 1);

      screen.onExitToMainMenu();
      expect(exitCount, 1);
    });

    test('can be constructed with game parameter', () {
      final config = GameSetupConfig(
        selectedGreatPowerIds: List<String>.from(GameSetupConfig.defaultConfig.selectedGreatPowerIds),
        leaderVariantByGpId: {},
        seed: 42,
        continentCount: GameSetupConfig.defaultConfig.continentCount,
        minorNationCount: GameSetupConfig.defaultConfig.minorNationCount,
        tribeCount: GameSetupConfig.defaultConfig.tribeCount,
        numProvincesOldWorld: GameSetupConfig.defaultConfig.numProvincesOldWorld,
        numProvincesNewWorld: GameSetupConfig.defaultConfig.numProvincesNewWorld,
        minProvincesPerMinor: GameSetupConfig.defaultConfig.minProvincesPerMinor,
      );

      final initResult = runInitGame(
        config: config,
        options: const InitGameOptions(renderPng: false),
      );

      final screen = InGameShellScreen(
        orders: const Orders(),
        onNavigate: (route) {},
        onEndTurn: () async {},
        onVictory: () {},
        onDefeat: () {},
        onExitToMainMenu: () {},
        game: initResult.game,
      );

      expect(screen.game, isNotNull);
    });

    test('can be constructed with gameEvents parameter', () {
      final screen = InGameShellScreen(
        orders: const Orders(),
        onNavigate: (route) {},
        onEndTurn: () async {},
        onVictory: () {},
        onDefeat: () {},
        onExitToMainMenu: () {},
        gameEvents: const [],
      );

      expect(screen.gameEvents, isNotNull);
    });

    test('HUD year matches turnToYear for initialized game', () {
      final config = GameSetupConfig(
        selectedGreatPowerIds: List<String>.from(
          GameSetupConfig.defaultConfig.selectedGreatPowerIds,
        ),
        leaderVariantByGpId: {},
        seed: 42,
        continentCount: GameSetupConfig.defaultConfig.continentCount,
        minorNationCount: GameSetupConfig.defaultConfig.minorNationCount,
        tribeCount: GameSetupConfig.defaultConfig.tribeCount,
        numProvincesOldWorld: GameSetupConfig.defaultConfig.numProvincesOldWorld,
        numProvincesNewWorld: GameSetupConfig.defaultConfig.numProvincesNewWorld,
        minProvincesPerMinor: GameSetupConfig.defaultConfig.minProvincesPerMinor,
      );

      final initResult = runInitGame(
        config: config,
        options: const InitGameOptions(renderPng: false),
      );

      final game = initResult.game;
      final turnNumber = game.worldState.turnState.turnNumber;
      final expectedYear = turnToYear(turnNumber, game.turnTimeMapping);

      final screen = InGameShellScreen(
        orders: const Orders(),
        onNavigate: (route) {},
        onEndTurn: () async {},
        onVictory: () {},
        onDefeat: () {},
        onExitToMainMenu: () {},
        game: game,
      );

      // Use the same helper as the HUD getter to compute the year.
      final hudYear =
          (screen.createState() as dynamic).inGameShellHudYear(game, turnNumber);

      expect(hudYear, expectedYear);
    });

    test('HUD resource summary shows starting resources for human player', () {
      final config = GameSetupConfig(
        selectedGreatPowerIds: List<String>.from(
          GameSetupConfig.defaultConfig.selectedGreatPowerIds,
        ),
        leaderVariantByGpId: {},
        seed: 42,
        continentCount: GameSetupConfig.defaultConfig.continentCount,
        minorNationCount: GameSetupConfig.defaultConfig.minorNationCount,
        tribeCount: GameSetupConfig.defaultConfig.tribeCount,
        numProvincesOldWorld: GameSetupConfig.defaultConfig.numProvincesOldWorld,
        numProvincesNewWorld: GameSetupConfig.defaultConfig.numProvincesNewWorld,
        minProvincesPerMinor: GameSetupConfig.defaultConfig.minProvincesPerMinor,
      );

      final starting = config.startingResources;
      final expectedGrain =
          starting.initialPeasants * starting.initialGrainTurns;
      final expectedSlots = starting.initialImprovementSlots;

      final initResult = runInitGame(
        config: config,
        options: const InitGameOptions(renderPng: false),
      );

      final game = initResult.game;

      Player? human;
      for (final p in game.players) {
        final isAiControlled = game.aiControlByGpId[p.id] ?? false;
        if (!isAiControlled) {
          human = p;
          break;
        }
      }

      expect(human, isNotNull);
      final stock = human!.stockpile;
      expect(stock.quantityOf('grain'), expectedGrain);
      expect(stock.quantityOf('lumber'), expectedSlots);
      expect(stock.quantityOf('castIron'), expectedSlots);

      final screen = InGameShellScreen(
        orders: const Orders(),
        onNavigate: (route) {},
        onEndTurn: () async {},
        onVictory: () {},
        onDefeat: () {},
        onExitToMainMenu: () {},
        game: game,
      );

      final state = screen.createState() as dynamic;
      final summary =
          state.inGameShellHudResourceSummary(game) as String;

      expect(summary, contains('g:$expectedGrain'));
      expect(summary, contains('L:$expectedSlots'));
      expect(summary, contains('CI:$expectedSlots'));
    });

  });
}
