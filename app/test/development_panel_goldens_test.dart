// Widget goldens for the Development panel (GAME80001) visual acceptance criteria
// (Refs #4175). Pixel baselines live under `app/test/goldens/` and are asserted
// with `matchesGoldenFile`, following the committed golden harness pattern.
//
// Golden mapping:
//  - Shell/list overview with improvable commodity rows and idle civilian counts
//  - Wide side-by-side list + panel map layout (≥ kNarrowBreakpoint)
//  - Narrow stacked list + panel map layout (< kNarrowBreakpoint)
//
// SPEC: SPEC/ui/development-panel.md § Acceptance criteria.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/screens/development/development_panel_keys.dart';
import 'package:colonizethis_app/features/game/screens/development/development_screen_body.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'development_panel_test_support.dart';
import 'golden_capture_harness.dart';
import 'panel_fixtures/core.dart';

const Size _kDevelopmentWideViewport = Size(900, 760);
const Size _kDevelopmentNarrowViewport = Size(360, 720);

Widget _developmentBodyHost({
  required Game game,
  required Size viewport,
}) {
  return SizedBox(
    width: viewport.width,
    height: viewport.height,
    child: DevelopmentScreenBody(
      game: game,
      humanPlayerId: kPanelTestHumanPlayerId,
    ),
  );
}

Future<void> _pumpDevelopmentBodyGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Game game,
  required Box<dynamic> gamesBox,
  Size viewport = _kDevelopmentWideViewport,
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: viewport,
    includeLocalizations: true,
    wrapInProviderScope: true,
    center: false,
    settle: false,
    overrides: [
      gamesBoxProvider.overrideWith((ref) => gamesBox),
      gameServiceProvider.overrideWith(
        (ref) => DevelopmentPanelMapGameService(gamesBox, GameSaveAdapter()),
      ),
      currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      currentOrdersProvider.overrideWith(() => CurrentOrdersNotifier(const Orders())),
    ],
    child: _developmentBodyHost(game: game, viewport: viewport),
  );
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openDevelopmentPanelTestHiveBox();
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  testWidgets(
    'golden: wide layout with improvable rows and overview (Refs #4175)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('developmentPanelWideGolden');
      final game = buildDevelopmentPanelGoldenGame();
      await _pumpDevelopmentBodyGolden(
        tester,
        boundaryKey: boundaryKey,
        game: game,
        gamesBox: gamesBox,
      );

      expect(find.byKey(DevelopmentPanelKeys.overviewKey), findsOneWidget);
      expect(find.byKey(DevelopmentPanelKeys.scopeListKey), findsOneWidget);
      expect(find.byKey(DevelopmentPanelKeys.panelMapKey), findsOneWidget);
      expect(find.text('Avalon'), findsOneWidget);
      expect(find.text('Barren'), findsOneWidget);
      expect(find.text('No improvable resources'), findsOneWidget);
      expect(find.textContaining('Idle Builders:'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/development_panel_wide.png'),
      );
    },
  );

  testWidgets(
    'golden: narrow stacked layout (Refs #4175)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('developmentPanelNarrowGolden');
      final game = buildDevelopmentPanelGoldenGame();
      await _pumpDevelopmentBodyGolden(
        tester,
        boundaryKey: boundaryKey,
        game: game,
        gamesBox: gamesBox,
        viewport: _kDevelopmentNarrowViewport,
      );

      expect(find.byKey(DevelopmentPanelKeys.overviewKey), findsOneWidget);
      expect(
        MediaQuery.sizeOf(tester.element(find.byType(DevelopmentScreenBody)))
            .width,
        lessThan(kNarrowBreakpoint),
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/development_panel_narrow.png'),
      );
    },
  );
}
