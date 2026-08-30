// Widget goldens for GAME70001 political minimap (Refs #4165, #4606 Slice D).
import 'package:colonizethis_app/features/game/screens/victory/victory_political_minimap.dart';
import 'package:colonizethis_app/features/game/screens/victory/victory_screen_keys.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'panel_fixtures/core.dart';
import 'victory_panel_goldens_test_support.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'golden: political minimap ownership colours (Refs #4165 AC-5/AC-14–AC-16)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('victoryPoliticalMinimapGolden');
      final game = buildPanelTestGame(
        players: [
          panelTestHumanPlayer(id: 'gp1', displayName: 'England'),
          const Player(id: 'gp2', displayName: 'France', isHuman: false),
        ],
        oldWorldProvinces: const [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
          Province(
            id: 'oldWorld|p2',
            regionId: 'oldWorld',
            ownerId: 'gp2',
            originalOwnerId: 'gp1',
            displayName: 'Yorkshire',
          ),
        ],
      );

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(360, 400),
        includeLocalizations: true,
        wrapInProviderScope: true,
        center: false,
        child: SizedBox(
          width: 360,
          height: 400,
          child: VictoryPoliticalMinimap(
            game: game,
            region: victoryPanelGoldenSampleOldWorldRegion(),
          ),
        ),
      );

      expect(
        find.byKey(VictoryScreenKeys.politicalMinimapPaintKey),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/victory_political_minimap.png'),
      );
    },
  );

  testWidgets(
    'golden: political minimap capture inspect line (Refs #4165 AC-6)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'victoryPoliticalMinimapInspectGolden',
      );
      final game = buildPanelTestGame(
        players: [
          panelTestHumanPlayer(id: 'gp1', displayName: 'England'),
          const Player(id: 'gp2', displayName: 'France', isHuman: false),
        ],
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|p2',
            regionId: 'oldWorld',
            ownerId: 'gp2',
            originalOwnerId: 'gp1',
            displayName: 'Yorkshire',
          ),
        ],
      );

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(360, 440),
        includeLocalizations: true,
        wrapInProviderScope: true,
        center: false,
        child: SizedBox(
          width: 360,
          height: 440,
          child: VictoryPoliticalMinimap(
            game: game,
            region: victoryPanelGoldenSampleOldWorldRegion(),
          ),
        ),
      );

      final gesture = find.byKey(VictoryScreenKeys.politicalMinimapGestureKey);
      final topLeft = tester.getTopLeft(gesture);
      final size = tester.getSize(gesture);
      await tester.tapAt(
        topLeft + Offset(size.width * 0.75, size.height * 0.75),
      );
      await pumpSyncFrames(tester);

      expect(
        find.byKey(VictoryScreenKeys.politicalMinimapInspectKey),
        findsOneWidget,
      );
      expect(find.textContaining('captured from England'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/victory_political_minimap_inspect.png'),
      );
    },
  );
}
