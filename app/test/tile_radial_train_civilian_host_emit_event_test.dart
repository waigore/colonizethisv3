// Host-level MAP30001 Train Explorer tap → UNIT40001 (Refs #4752 AC5).

import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart'
    show trainCiviliansDialogId;
import 'package:colonizethis_app/features/game/widgets/map_radial/game_map_tile_radial_host.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_keys.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'app_test_hive_harness.dart';
import 'province_explore_shortcut_host_emit_event_test_support.dart';
import 'widget_test_assets.dart';

const Key _kMapStubKey = Key('tile_radial_train_map_stub');

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    await preloadNinePatchImage();
    gamesBox = await openAppTestHiveBox(
      suiteId: 'tile_radial_train_civilian_host_emit',
    );
  });

  Future<void> pumpHost(WidgetTester tester, {required AppEventBus bus}) {
    final game = buildExploreShortcutGame(withExplorer: false);
    final region = exploreShortcutPartiallyRevealedRegion();
    return pumpAppShell(
      tester,
      viewport: const Size(800, 800),
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      overrides: [
        gamesBoxProvider.overrideWith((ref) => gamesBox),
        gameServiceProvider.overrideWith(
          (ref) => provinceShortcutHostEmitGameService(
            gamesBox: gamesBox,
            gameId: kExploreShortcutGameId,
            combinedTopology: exploreShortcutCombinedTopology,
            tileMapByRegion: exploreShortcutTileMapByRegion,
            topologyByRegion: exploreShortcutTopologyByRegion,
          ),
        ),
        currentOrdersProvider.overrideWith(
          () => CurrentOrdersNotifier(const Orders()),
        ),
      ],
      child: GameMapTileRadialHost(
        game: game,
        region: region,
        humanPlayerId: kExploreShortcutHumanPlayerId,
        playerView: buildPlayerView(
          game,
          exploreShortcutCombinedTopology,
          kExploreShortcutHumanPlayerId,
        ),
        workTargetSelectionCache: exploreShortcutCache(),
        canMutateViaUi: true,
        bus: bus,
        mapBuilder: (onSecondary) {
          return GestureDetector(
            key: _kMapStubKey,
            onTap: onSecondary == null
                ? null
                : () => onSecondary(
                    kExploreShortcutTileKey,
                    const Offset(400, 400),
                  ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }

  testWidgets('Train Explorer wedge opens UNIT40001 without assigning work', (
    tester,
  ) async {
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);
    final dialog = <OpenDialogEvent>[];
    final panel = <OpenCivilianUnitsPanelEvent>[];
    bus.on<OpenDialogEvent>().listen(dialog.add);
    bus.on<OpenCivilianUnitsPanelEvent>().listen(panel.add);
    await pumpHost(tester, bus: bus);
    tester
        .state<GameMapTileRadialHostState>(find.byType(GameMapTileRadialHost))
        .openFromSecondary(kExploreShortcutTileKey, const Offset(400, 400));
    await tester.pump();
    expect(find.byKey(kTileContextRadialKey), findsOneWidget);
    expect(find.text('Train Explorer'), findsOneWidget);
    await tester.tap(find.byKey(kTileRadialExploreKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(dialog, hasLength(1));
    expect(dialog.single.dialogId, trainCiviliansDialogId);
    expect(dialog.single.params, isNull);
    expect(panel, isEmpty);
    expect(find.byKey(kTileContextRadialKey), findsNothing);
    final ctx = tester.element(find.byType(GameMapTileRadialHost));
    final orders = ProviderScope.containerOf(ctx).read(currentOrdersProvider);
    expect(orders.workOrdersByPlayerId, isEmpty);
    expect(orders.buildUnitOrdersByPlayerId, isEmpty);
  });
}
