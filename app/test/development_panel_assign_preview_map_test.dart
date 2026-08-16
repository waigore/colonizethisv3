// Full-panel Show highlights the auto-picked Assign tile (Refs #4472).

import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/screens/development/development_panel_keys.dart';
import 'package:colonizethis_app/features/game/screens/development/development_screen_body.dart';
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/ct_region_map.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'development_panel_test_support.dart';
import 'panel_fixtures/core.dart';

Game _previewGame() {
  final base = buildDevelopmentPanelGoldenGame();
  return base.copyWith(
    worldState: base.worldState.copyWith(
      tileState: const TileMapState(
        improvementByTile: {'oldWorld|p1|0|0': 1, 'oldWorld|p1|1|0': 1},
      ),
    ),
    players: [
      base.players.first.copyWith(
        techUnlocked: const {
          kTechIdCircularSaw: true,
          kTechIdLandEnclosure: true,
        },
      ),
    ],
  );
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openDevelopmentPanelTestHiveBox(suiteId: 'assign_preview');
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  testWidgets('Show selects the auto-picked tile on the panel map', (
    tester,
  ) async {
    final game = _previewGame();
    final container = ProviderContainer(
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
          const ShellPlayerContext(
            effectiveHumanPlayerId: kPanelTestHumanPlayerId,
            viewingPlayerId: kPanelTestHumanPlayerId,
            mapVisibilityMode: CtMapVisibilityMode.playerConstrained,
            playerView: null,
            omniscientDetail: false,
            showPlayerChrome: true,
            canMutateViaUi: true,
            debugCommandTargetPlayerId: kPanelTestHumanPlayerId,
            inObservePhase: false,
            observeBannerLabel: null,
            treasuryNotDefined: false,
            cargoNotDefined: false,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      buildAppShellWithContainer(
        container: container,
        child: SizedBox(
          width: 900,
          height: 760,
          child: DevelopmentScreenBody(
            game: game,
            humanPlayerId: kPanelTestHumanPlayerId,
          ),
        ),
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
      ),
    );
    await pumpDevelopmentPanelReady(tester);

    await tester.tap(
      find.byKey(DevelopmentPanelKeys.showButtonKey('oldWorld|p1', 'grain')),
    );
    await tester.pump();

    final map = tester.widget<CtRegionMap>(find.byType(CtRegionMap));
    expect(map.selectedTileKey, 'oldWorld|p1|0|0');
    expect(
      map.secondaryHighlightTileKeys,
      containsAll(<String>['oldWorld|p1|0|0', 'oldWorld|p1|1|0']),
    );
    expect(find.textContaining('1 → 2'), findsWidgets);
  });
}
