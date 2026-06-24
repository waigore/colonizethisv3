// Visual parity goldens for the GAME40001 Technology Slots tab (Refs #3510):
// the full `TechnologyPanel` body captured at a desktop-width viewport and at
// the 360 x 640 dp mobile frame (SPEC/ui/technology-panel.md § Defined
// viewports). These close the AC-1 / AC-8 side-by-side visual-parity golden gap
// flagged on issue #3510's verification — the mockup-faithful section heading
// style, slot-card geometry, compact action controls, and locked Slot 4
// placeholder are pinned by `matchesGoldenFile` baselines.
//
// Rendered against `AppThemes.editorialMonocle` (the running-app dark theme) at
// device pixel ratio 1.0 from the deterministic lightweight
// `buildTechnologyPanelTestGame()` fixture (Refs #3656), inside a keyed
// `RepaintBoundary` over a viewport-sized
// `SingleChildScrollView`, matching the committed golden harness pattern
// (`new_game_leader_selection_dialog_golden_test.dart`). The structural /
// behavioural contracts (heading widget type, compact controls, locked-slot
// width, no dev-only header) remain pinned by `technology_panel_test.dart` and
// `technology_panel_dark_chrome_test.dart`; this file adds the visual proof.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/technology_panel.dart';
import 'package:colonizethis_app/l10n/l10n.dart';

import 'support/panel_test_fixtures.dart';

Future<void> _pumpPanel(
  WidgetTester tester, {
  required Key boundaryKey,
  required Size viewport,
  required Game game,
  required Player player,
}) async {
  addTearDown(tester.view.reset);
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: boundaryKey,
            child: SizedBox(
              width: viewport.width,
              height: viewport.height,
              child: SingleChildScrollView(
                child: TechnologyPanel(
                  game: game,
                  player: player,
                  onOrdersChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  suppressLogsForTests();

  late Game game;
  late Player player;

  setUpAll(() {
    game = buildTechnologyPanelTestGame();
    player = game.players.first;
  });

  testWidgets(
    'golden: Slots tab parity at desktop width (Refs #3510 AC1/AC8)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('technologySlotsPanelDesktopGolden');
      await _pumpPanel(
        tester,
        boundaryKey: boundaryKey,
        viewport: const Size(900, 760),
        game: game,
        player: player,
      );

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/technology_slots_panel_desktop.png'),
      );
    },
  );

  testWidgets(
    'golden: Slots tab parity at 360x640 mobile viewport (Refs #3510 AC1/AC8)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('technologySlotsPanelMobileGolden');
      await _pumpPanel(
        tester,
        boundaryKey: boundaryKey,
        viewport: const Size(360, 640),
        game: game,
        player: player,
      );

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/technology_slots_panel_mobile_360.png'),
      );
    },
  );
}
