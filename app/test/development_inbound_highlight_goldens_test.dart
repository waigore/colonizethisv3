// Goldens for Development inbound feedstock highlight landing. Refs #4725.
//
// Mirrors `production_available_trade_goldens_test.dart` (Trade highlight from
// Production): pins GAME80001 with highlightCommodityId and the named empty-
// match banner so verify can map AC5/AC6 to PNG baselines.

import 'package:colonizethis_app/features/game/screens/development/development_inbound_highlight.dart';
import 'package:colonizethis_app/features/game/screens/development/development_screen_body.dart';
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
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

const Size _kInboundGoldenViewport = Size(360, 640);

Widget _developmentInboundHost({
  required Game game,
  String? highlightCommodityId,
  String? highlightTileKey,
}) {
  return SizedBox(
    width: _kInboundGoldenViewport.width,
    height: _kInboundGoldenViewport.height,
    child: DevelopmentScreenBody(
      game: game,
      humanPlayerId: kPanelTestHumanPlayerId,
      highlightCommodityId: highlightCommodityId,
      highlightTileKey: highlightTileKey,
    ),
  );
}

Future<void> _pumpInboundGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Game game,
  required Box<dynamic> gamesBox,
  String? highlightCommodityId,
  String? highlightTileKey,
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: _kInboundGoldenViewport,
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
      currentOrdersProvider.overrideWith(
        () => CurrentOrdersNotifier(const Orders()),
      ),
      shellPlayerContextProvider.overrideWithValue(
        developmentPanelProjectionShellContext(),
      ),
    ],
    child: _developmentInboundHost(
      game: game,
      highlightCommodityId: highlightCommodityId,
      highlightTileKey: highlightTileKey,
    ),
  );
  await pumpDevelopmentPanelReady(tester);
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openDevelopmentPanelTestHiveBox(
      suiteId: 'inbound_highlight_goldens',
    );
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  testWidgets(
    'golden: inbound highlight from Production/Counsel at 360×640 (#4725)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'development_inbound_highlight_golden',
      );
      final game = buildDevelopmentPanelGoldenGame();
      await _pumpInboundGolden(
        tester,
        boundaryKey: boundaryKey,
        game: game,
        gamesBox: gamesBox,
        highlightCommodityId: 'grain',
        highlightTileKey: 'oldWorld|p1|0|0',
      );

      expect(
        find.byKey(DevelopmentInboundCommodityHighlight.highlightKey('grain')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('development_inbound_no_match_banner')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/development_inbound_highlight_360x640.png',
        ),
      );
    },
  );

  testWidgets(
    'golden: inbound miss names the good at 360×640 (#4725)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'development_inbound_no_match_golden',
      );
      final game = buildDevelopmentPanelGoldenGame();
      await _pumpInboundGolden(
        tester,
        boundaryKey: boundaryKey,
        game: game,
        gamesBox: gamesBox,
        highlightCommodityId: 'timber',
      );

      expect(
        find.byKey(const ValueKey<String>('development_inbound_no_match_banner')),
        findsOneWidget,
      );
      expect(find.textContaining('Timber'), findsOneWidget);
      expect(
        find.byKey(DevelopmentInboundCommodityHighlight.highlightKey('timber')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/development_inbound_no_match_360x640.png',
        ),
      );
    },
  );
}
