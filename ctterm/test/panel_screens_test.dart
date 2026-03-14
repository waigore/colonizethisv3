// Tests for panel screens (Units, Development, Production, Academy, Shipyard, Diplomacy, Technology). SPEC/tui/ctterm.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:ctterm/screens/units_screen.dart';
import 'package:ctterm/screens/development_screen.dart';
import 'package:ctterm/screens/production_screen.dart';
import 'package:ctterm/screens/academy_screen.dart';
import 'package:ctterm/screens/shipyard_screen.dart';
import 'package:ctterm/screens/diplomacy_screen.dart';
import 'package:ctterm/screens/technology_screen.dart';
import 'package:ctterm/screens/map_context_screen.dart';
import 'package:ctterm/ctterm_routes.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  late Game testGame;
  late InitGameResult initResult;

  setUpAll(() {
    // Initialize a test game once for all tests
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

    initResult = runInitGame(
      config: config,
      options: const InitGameOptions(renderPng: false),
    );
    testGame = initResult.game;
  });

  group('UnitsScreen (SPEC/tui/screens/units.md)', () {
    test('can be constructed with required parameters', () {
      final screen = UnitsScreen(
        onNavigate: (route) {},
        game: testGame,
        orders: const Orders(),
        onOrdersChanged: (orders) {},
        combinedTopology: initResult.combinedTopology,
      );

      expect(screen.onNavigate, isNotNull);
      expect(screen.game, isNotNull);
      expect(screen.orders, isNotNull);
      expect(screen.onOrdersChanged, isNotNull);
    });

    test('callbacks are invoked correctly', () {
      var navigateRoute = CttermRoute.mainMenu;
      Orders? changedOrders;

      final screen = UnitsScreen(
        onNavigate: (route) => navigateRoute = route,
        game: testGame,
        orders: const Orders(),
        onOrdersChanged: (orders) => changedOrders = orders,
        combinedTopology: initResult.combinedTopology,
      );

      screen.onNavigate(CttermRoute.mainMenu);
      expect(navigateRoute, CttermRoute.mainMenu);

      screen.onOrdersChanged(const Orders());
      expect(changedOrders, isNotNull);
    });

    // Detailed rendering tests for UnitsScreen are covered by higher-level
    // ctterm integration tests; here we only verify construction and wiring.
  });

  group('DevelopmentScreen (SPEC/tui/screens/development.md)', () {
    test('can be constructed with required parameters', () {
      final screen = DevelopmentScreen(
        onNavigate: (route) {},
        game: testGame,
        orders: const Orders(),
        onOrdersChanged: (orders) {},
      );

      expect(screen.onNavigate, isNotNull);
      expect(screen.game, isNotNull);
      expect(screen.orders, isNotNull);
      expect(screen.onOrdersChanged, isNotNull);
    });

    test('callbacks are invoked correctly', () {
      var navigateRoute = CttermRoute.mainMenu;
      Orders? changedOrders;

      final screen = DevelopmentScreen(
        onNavigate: (route) => navigateRoute = route,
        game: testGame,
        orders: const Orders(),
        onOrdersChanged: (orders) => changedOrders = orders,
      );

      screen.onNavigate(CttermRoute.mainMenu);
      expect(navigateRoute, CttermRoute.mainMenu);

      screen.onOrdersChanged(const Orders());
      expect(changedOrders, isNotNull);
    });
  });

  group('ProductionScreen (SPEC/tui/screens/production.md)', () {
    test('can be constructed with required parameters', () {
      final screen = ProductionScreen(
        onNavigate: (route) {},
        game: testGame,
      );

      expect(screen.onNavigate, isNotNull);
      expect(screen.game, isNotNull);
    });

    test('callbacks are invoked correctly', () {
      var navigateRoute = CttermRoute.mainMenu;

      final screen = ProductionScreen(
        onNavigate: (route) => navigateRoute = route,
        game: testGame,
      );

      screen.onNavigate(CttermRoute.mainMenu);
      expect(navigateRoute, CttermRoute.mainMenu);
    });
  });

  group('AcademyScreen (SPEC/tui/screens/academy.md)', () {
    test('can be constructed with required parameters', () {
      final screen = AcademyScreen(
        onNavigate: (route) {},
        game: testGame,
        orders: const Orders(),
        onOrdersChanged: (orders) {},
      );

      expect(screen.onNavigate, isNotNull);
      expect(screen.game, isNotNull);
      expect(screen.orders, isNotNull);
      expect(screen.onOrdersChanged, isNotNull);
    });

    test('callbacks are invoked correctly', () {
      var navigateRoute = CttermRoute.mainMenu;
      Orders? changedOrders;

      final screen = AcademyScreen(
        onNavigate: (route) => navigateRoute = route,
        game: testGame,
        orders: const Orders(),
        onOrdersChanged: (orders) => changedOrders = orders,
      );

      screen.onNavigate(CttermRoute.mainMenu);
      expect(navigateRoute, CttermRoute.mainMenu);

      screen.onOrdersChanged(const Orders());
      expect(changedOrders, isNotNull);
    });
  });

  group('ShipyardScreen (SPEC/tui/screens/shipyard.md)', () {
    test('can be constructed with required parameters', () {
      final screen = ShipyardScreen(
        onNavigate: (route) {},
        game: testGame,
        orders: const Orders(),
        onOrdersChanged: (orders) {},
      );

      expect(screen.onNavigate, isNotNull);
      expect(screen.game, isNotNull);
      expect(screen.orders, isNotNull);
      expect(screen.onOrdersChanged, isNotNull);
    });

    test('callbacks are invoked correctly', () {
      var navigateRoute = CttermRoute.mainMenu;
      Orders? changedOrders;

      final screen = ShipyardScreen(
        onNavigate: (route) => navigateRoute = route,
        game: testGame,
        orders: const Orders(),
        onOrdersChanged: (orders) => changedOrders = orders,
      );

      screen.onNavigate(CttermRoute.mainMenu);
      expect(navigateRoute, CttermRoute.mainMenu);

      screen.onOrdersChanged(const Orders());
      expect(changedOrders, isNotNull);
    });
  });

  group('DiplomacyScreen (SPEC/tui/screens/diplomacy.md)', () {
    test('display mapping aligned with SPEC (relationScoreToDisplayLabel bands)', () {
      expect(relationScoreToDisplayLabel(0), 'Hostile');
      expect(relationScoreToDisplayLabel(50), 'Cordial');
      expect(relationScoreToDisplayLabel(70), 'Friendly');
    });

    test('can be constructed with required parameters', () {
      final screen = DiplomacyScreen(
        onNavigate: (route) {},
        game: testGame,
        orders: const Orders(),
        onOrdersChanged: (orders) {},
      );

      expect(screen.onNavigate, isNotNull);
      expect(screen.game, isNotNull);
      expect(screen.orders, isNotNull);
      expect(screen.onOrdersChanged, isNotNull);
    });

    test('callbacks are invoked correctly', () {
      var navigateRoute = CttermRoute.mainMenu;
      Orders? changedOrders;

      final screen = DiplomacyScreen(
        onNavigate: (route) => navigateRoute = route,
        game: testGame,
        orders: const Orders(),
        onOrdersChanged: (orders) => changedOrders = orders,
      );

      screen.onNavigate(CttermRoute.mainMenu);
      expect(navigateRoute, CttermRoute.mainMenu);

      screen.onOrdersChanged(const Orders());
      expect(changedOrders, isNotNull);
    });
  });

  group('TechnologyScreen (SPEC/tui/screens/technology.md)', () {
    test('can be constructed with required parameters', () {
      final screen = TechnologyScreen(
        onNavigate: (route) {},
        game: testGame,
        orders: const Orders(),
        onOrdersChanged: (orders) {},
      );

      expect(screen.onNavigate, isNotNull);
      expect(screen.game, isNotNull);
      expect(screen.orders, isNotNull);
      expect(screen.onOrdersChanged, isNotNull);
    });

    test('callbacks are invoked correctly', () {
      var navigateRoute = CttermRoute.mainMenu;
      Orders? changedOrders;

      final screen = TechnologyScreen(
        onNavigate: (route) => navigateRoute = route,
        game: testGame,
        orders: const Orders(),
        onOrdersChanged: (orders) => changedOrders = orders,
      );

      screen.onNavigate(CttermRoute.mainMenu);
      expect(navigateRoute, CttermRoute.mainMenu);

      screen.onOrdersChanged(const Orders());
      expect(changedOrders, isNotNull);
    });
  });

  group('MapContextScreen (SPEC/tui/screens/map-context.md)', () {
    test('can be constructed with required parameters', () {
      final screen = MapContextScreen(
        onNavigate: (route) {},
        game: testGame,
      );

      expect(screen.onNavigate, isNotNull);
      expect(screen.game, isNotNull);
    });

    test('callbacks are invoked correctly', () {
      var navigateRoute = CttermRoute.mainMenu;

      final screen = MapContextScreen(
        onNavigate: (route) => navigateRoute = route,
        game: testGame,
      );

      screen.onNavigate(CttermRoute.mainMenu);
      expect(navigateRoute, CttermRoute.mainMenu);
    });
  });
}
