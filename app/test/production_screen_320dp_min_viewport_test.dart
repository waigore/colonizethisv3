// SPEC/ui/mobile-adaptation.md § 7 — ProductionScreen @ 320 dp (Refs #2870 S10).

import 'package:colonizethis_app/features/game/screens/production/production_screen.dart';
import 'package:colonizethis_app/features/game/widgets/panels/observe_mode_not_defined_panel.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_panel.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'production_panel_test_support.dart';
import 'production_screen_320dp_min_viewport_support.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late Player humanPlayer;

  setUpAll(() {
    humanPlayer = productionPanelTestFullPlayer();
    game = productionPanelTestGameFor(humanPlayer);
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — ProductionScreen (default) @ '
      '320 dp (Refs #2870 S10)', () {
    testWidgets(
      'AC (positive) ProductionScreen default @ 320×640: no RenderFlex '
      'overflow exception, dark CtTopBar (title `Production`, back '
      'label `Map`) + ProductionPanel narrow body (both `Available` '
      'and `Allocation` labels) all render',
      (WidgetTester tester) async {
        await pumpProductionScreenAtViewport(
          tester,
          size: kProductionMinViewport,
          game: game,
          player: humanPlayer,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: ProductionScreen must '
              'not emit a RenderFlex overflow exception at '
              'kMinViewportWidth (320 dp).',
        );

        final topBarFinder = find.byKey(ProductionScreen.topBarKey);
        expect(topBarFinder, findsOneWidget);
        final CtTopBar topBar = tester.widget<CtTopBar>(topBarFinder);
        expect(topBar.title, ProductionScreen.topBarTitle);
        expect(topBar.backButtonLabel, ProductionScreen.topBarBackLabel);

        expect(
          find.descendant(
            of: topBarFinder,
            matching: find.byType(CtBackButton),
          ),
          findsOneWidget,
        );

        expect(find.byType(ProductionPanel), findsOneWidget);
        expect(find.text('Available'), findsOneWidget);
        expect(find.text('Allocation'), findsOneWidget);
        expect(find.byType(ObserveModeNotDefinedPanel), findsNothing);
      },
    );

    testWidgets('Negative control: ProductionScreen default @ 1024×768 also '
        'pumps without exception (regression sentinel for the overflow '
        'contract — keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      await pumpProductionScreenAtViewport(
        tester,
        size: kProductionWideRegressionViewport,
        game: game,
        player: humanPlayer,
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(ProductionScreen.topBarKey), findsOneWidget);
      expect(find.byType(ProductionPanel), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Allocation'), findsOneWidget);
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — ProductionScreen (global '
      'observe) @ 320 dp (Refs #2870 S10)', () {
    testWidgets('AC (positive) ProductionScreen global-observe @ 320×640: no '
        'RenderFlex overflow exception, dark CtTopBar still paints, '
        'ObserveModeNotDefinedPanel sentinel renders, ProductionPanel '
        'body is absent', (WidgetTester tester) async {
      await pumpProductionScreenAtViewport(
        tester,
        size: kProductionMinViewport,
        game: game,
        player: humanPlayer,
        globalObserve: true,
      );

      expect(tester.takeException(), isNull);

      expect(find.byKey(ProductionScreen.topBarKey), findsOneWidget);

      final observePanelFinder = find.byType(ObserveModeNotDefinedPanel);
      expect(observePanelFinder, findsOneWidget);
      final ObserveModeNotDefinedPanel observePanel = tester
          .widget<ObserveModeNotDefinedPanel>(observePanelFinder);
      expect(observePanel.title, ProductionScreen.topBarTitle);

      expect(find.byType(ProductionPanel), findsNothing);
    });

    testWidgets('Negative control: ProductionScreen global-observe @ 1024×768 '
        'also pumps without exception (regression sentinel for the '
        'overflow contract under the observe variant)', (
      WidgetTester tester,
    ) async {
      await pumpProductionScreenAtViewport(
        tester,
        size: kProductionWideRegressionViewport,
        game: game,
        player: humanPlayer,
        globalObserve: true,
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(ProductionScreen.topBarKey), findsOneWidget);
      expect(find.byType(ObserveModeNotDefinedPanel), findsOneWidget);
      expect(find.byType(ProductionPanel), findsNothing);
    });
  });
}
