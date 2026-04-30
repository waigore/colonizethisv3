// Integration tests for ProductionScreen + productionDesiredOutputProvider.
// SPEC/ui/production-panel.md.

import 'package:colonizethis_app/features/game/screens/production_screen.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/production_allocation_provider.dart';
import 'package:colonizethis_app/widgets/ct_slider.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test_pumps.dart';
import 'production_panel_test_fixtures.dart';

class _SeededProductionDesiredOutputNotifier
    extends ProductionDesiredOutputNotifier {
  _SeededProductionDesiredOutputNotifier(this._initial);

  final Map<String, int> _initial;

  @override
  Map<String, int> build() => _initial;
}

void main() {
  suppressLogsForTests();

  late Game isolatedGame;
  late Player fullPlayer;

  setUpAll(() {
    fullPlayer = productionPanelTestFullPlayer();
    isolatedGame = Game(
      id: 'production-integration',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      players: [fullPlayer],
    );
  });

  Widget buildScreen({
    Map<String, int>? initialDesiredOutput,
    Orders initialOrders = const Orders(),
    double width = 800,
    double height = 500,
  }) {
    return ProviderScope(
      overrides: [
        currentGameProvider.overrideWith(
          () => CurrentGameNotifier(isolatedGame),
        ),
        currentOrdersProvider.overrideWith(
          () => CurrentOrdersNotifier(initialOrders),
        ),
        appEventBusProvider.overrideWith((ref) {
          final bus = AppEventBus.create();
          ref.onDispose(bus.dispose);
          return bus;
        }),
        if (initialDesiredOutput != null)
          productionDesiredOutputProvider.overrideWith(
            () => _SeededProductionDesiredOutputNotifier(initialDesiredOutput),
          ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, height)),
          child: ProductionScreen(
            game: isolatedGame,
            player: fullPlayer,
            attachGameToUiListener: false,
            panelTopologyOverride: const MapTopology(),
            panelTileMapByRegionOverride: null,
          ),
        ),
      ),
    );
  }

  group('ProductionScreen + provider integration', () {
    testWidgets(
      'preseeded provider state is reflected in Available net changes',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildScreen(initialDesiredOutput: {'lumber_from_timber': 5}),
        );
        await pumpSettleCapped(tester);

        expect(find.textContaining('Timber:'), findsOneWidget);
        expect(find.textContaining(RegExp(r'\(-10\)')), findsOneWidget);
        expect(find.textContaining('Lumber:'), findsOneWidget);
        expect(find.textContaining(RegExp(r'\(\+5\)')), findsOneWidget);
      },
    );

    testWidgets('moving a slider updates derived values via provider rebuild', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await pumpSettleCapped(tester);

      expect(find.textContaining('Timber:'), findsOneWidget);

      final sliders = find.byType(CtSlider);
      expect(sliders, findsNWidgets(ProductionRecipesCatalog.all.length));

      await tester.drag(sliders.first, const Offset(80, 0));
      await pumpSyncFrames(tester);

      expect(find.textContaining('Timber:'), findsOneWidget);
      expect(find.textContaining(RegExp(r'\(|\+|-')), findsWidgets);
    });

    testWidgets('pending build orders affect Available net deltas', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildScreen(
          initialOrders: const Orders(
            buildUnitOrdersByPlayerId: {
              'test_gp_full': [
                BuildUnitOrder(
                  unitType: kUnitTypeBuilder,
                  isMilitary: false,
                  spawnProvinceId: 'ow|prov-1',
                ),
              ],
            },
          ),
        ),
      );
      await pumpSettleCapped(tester);

      expect(find.textContaining('Paper:'), findsOneWidget);
      expect(find.textContaining(RegExp(r'\(-2\)')), findsOneWidget);
    });

    testWidgets(
      'Breakdown dialog shows phase columns and live-updates from provider',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildScreen());
        await pumpSettleCapped(tester);

        await tester.tap(find.text('Breakdown'));
        await pumpSettleCapped(
          tester,
          timeout: const Duration(milliseconds: 800),
        );

        expect(find.text('Commodity breakdown'), findsOneWidget);
        final tableFinder = find.byType(DataTable);
        expect(tableFinder, findsOneWidget);
        expect(
          find.descendant(of: tableFinder, matching: find.text('Extraction')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: tableFinder,
            matching: find.text('Pending build costs'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: tableFinder,
            matching: find.text('Riches to treasury'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: tableFinder, matching: find.text('Consumption')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: tableFinder, matching: find.text('Production')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: tableFinder, matching: find.text('Total')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: tableFinder,
            matching: find.byWidgetPredicate(
              (w) => w is ResourceIcon && w.commodityId == 'grain',
            ),
          ),
          findsOneWidget,
        );

        final screenContext = tester.element(find.byType(ProductionScreen));
        final container = ProviderScope.containerOf(screenContext);
        container.read(productionDesiredOutputProvider.notifier).replaceAll({
          'lumber_from_timber': 2,
        });
        await pumpSyncFrames(tester);

        expect(find.text('Commodity breakdown'), findsOneWidget);
        expect(find.text('+2'), findsWidgets);
      },
    );
  });
}
