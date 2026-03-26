// Integration tests for ProductionScreen + productionDesiredOutputProvider.
// SPEC/ui/production-panel.md.

import 'package:colonizethis_app/features/game/widgets/production_panel_demo_data.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart';
import 'package:colonizethis_app/features/game/widgets/production_screen.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/production_allocation_provider.dart';
import 'package:colonizethis_app/widgets/ct_slider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SeededProductionDesiredOutputNotifier
    extends ProductionDesiredOutputNotifier {
  _SeededProductionDesiredOutputNotifier(this._initial);

  final Map<String, int> _initial;

  @override
  Map<String, int> build() => _initial;
}

void main() {
  suppressLogsForTests();

  late Game demoGame;
  late Player fullPlayer;

  setUpAll(() {
    demoGame = demoGameForOverlay;
    fullPlayer = fullAvailabilityProductionPlayer();
  });

  Widget _buildScreen({
    Map<String, int>? initialDesiredOutput,
    double width = 800,
    double height = 500,
  }) {
    return ProviderScope(
      overrides: [
        currentGameProvider.overrideWith(() => CurrentGameNotifier(demoGame)),
        appEventBusProvider.overrideWith((ref) {
          final bus = AppEventBus.create();
          ref.onDispose(bus.dispose);
          return bus;
        }),
        if (initialDesiredOutput != null)
          productionDesiredOutputProvider
              .overrideWith(() {
                return _SeededProductionDesiredOutputNotifier(
                  initialDesiredOutput,
                );
              }),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, height)),
          child: ProductionScreen(
            game: demoGame,
            player: fullPlayer,
            attachGameToUiListener: false,
          ),
        ),
      ),
    );
  }

  group('ProductionScreen + provider integration', () {
    testWidgets(
      'preseeded provider state is reflected in Available net changes',
      (WidgetTester tester) async {
        // 5 runs of lumber_from_timber consume 10 timber and produce 5 lumber,
        // matching expectations from ProductionPanel tests.
        await tester.pumpWidget(
          _buildScreen(initialDesiredOutput: {'lumber_from_timber': 5}),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Timber:'), findsOneWidget);
        expect(find.textContaining(RegExp(r'\(-10\)')), findsOneWidget);
        expect(find.textContaining('Lumber:'), findsOneWidget);
        expect(find.textContaining(r'(+5)'), findsOneWidget);
      },
    );

    testWidgets(
      'moving a slider updates derived values via provider rebuild',
      (WidgetTester tester) async {
        await tester.pumpWidget(_buildScreen());
        await tester.pumpAndSettle();

        // Initially there should be no net change annotations like "(-" or "(+"
        // for timber; after dragging a slider, they should appear.
        expect(find.textContaining('Timber:'), findsOneWidget);

        final sliders = find.byType(CtSlider);
        expect(sliders, findsNWidgets(ProductionRecipesCatalog.all.length));

        await tester.drag(sliders.first, const Offset(80, 0));
        await tester.pumpAndSettle();

        // After the drag, the provider has been updated and the screen rebuilt,
        // so net changes should now be visible.
        expect(find.textContaining('Timber:'), findsOneWidget);
        expect(
          find.textContaining(RegExp(r'\(|\+|-')),
          findsWidgets,
        );
      },
    );
  });
}

