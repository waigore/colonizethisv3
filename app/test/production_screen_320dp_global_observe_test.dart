// Pin the 320 dp minimum-viewport contract for the in-game
// `ProductionScreen` (`UiScreenIds.productionScreen`) full-screen feature
// surface — extending the existing screen-, panel-, dialog-, and
// unit-panel-level pins (`mobile_320dp_min_viewport_test.dart`,
// `panels_320dp_min_viewport_test.dart`,
// `dialogs_320dp_min_viewport_test.dart`,
// `unit_panels_320dp_min_viewport_test.dart`,
// `trade_screen_320dp_min_viewport_test.dart`,
// `diplomacy_screen_320dp_min_viewport_test.dart`,
// `technology_screen_320dp_min_viewport_test.dart`) to the in-game
// production route opened from the empire shell.
//
// `ProductionScreen` mounts `CtGameFeatureScreenShell` with the dark
// editorial-monocle `CtTopBar` (back chevron + literal `Map` label + 18 ×
// 18 px production icon + literal title `Production`, 36 dp height)
// above an observe-mode-aware body. At `kMinViewportWidth` (320 dp) the
// available width collapses to 320 dp; the chrome and the
// `ProductionPanel` body (already pinned in
// `panels_320dp_min_viewport_test.dart`) must still lay out together
// without `RenderFlex` overflow per `SPEC/ui/mobile-adaptation.md` § 7
  group('SPEC/ui/mobile-adaptation.md § 7 — ProductionScreen (global '
      'observe) @ 320 dp (Refs #2870 S10)', () {
    testWidgets('AC (positive) ProductionScreen global-observe @ 320×640: no '
        'RenderFlex overflow exception, dark CtTopBar still paints, '
        'ObserveModeNotDefinedPanel sentinel renders, ProductionPanel '
        'body is absent', (WidgetTester tester) async {
      await _pumpProductionScreen(
        tester,
        size: _kMinViewport,
        game: game,
        player: humanPlayer,
        globalObserve: true,
      );

      expect(
        tester.takeException(),
        isNull,
        reason:
            'SPEC/ui/mobile-adaptation.md § 7: ProductionScreen '
            'global-observe body must not emit a RenderFlex '
            'overflow exception at kMinViewportWidth (320 dp). '
            'The dark CtTopBar plus the '
            "`ObserveModeNotDefinedPanel(title: 'Production')` "
            'sentinel must lay out within the 320 dp column.',
      );

      expect(
        find.byKey(ProductionScreen.topBarKey),
        findsOneWidget,
        reason:
            'Observe override only swaps the body (see SPEC/ui/'
            'production-panel.md § States and variants); the dark '
            'CtTopBar must still paint so the AC for the chrome '
            'is exercised at 320 dp under both variants.',
      );

      final observePanelFinder = find.byType(ObserveModeNotDefinedPanel);
      expect(observePanelFinder, findsOneWidget);
      final ObserveModeNotDefinedPanel observePanel = tester
          .widget<ObserveModeNotDefinedPanel>(observePanelFinder);
      // SPEC/ui/production-panel.md § States and variants requires
      // the literal `Production` title under the observe sentinel.
      expect(observePanel.title, ProductionScreen.topBarTitle);

      expect(
        find.byType(ProductionPanel),
        findsNothing,
        reason:
            'Global-observe path MUST NOT mount the '
            'ProductionPanel body — SPEC/ui/production-panel.md '
            '§ States and variants reserves the observe sentinel '
            'for that branch.',
      );
    });

    testWidgets('Negative control: ProductionScreen global-observe @ 1024×768 '
        'also pumps without exception (regression sentinel for the '
        'overflow contract under the observe variant)', (
      WidgetTester tester,
    ) async {
      await _pumpProductionScreen(
        tester,
        size: _kWideRegressionViewport,
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
