// Host-level MAP20001 Train Explorer tap → UNIT40001 (Refs #4752 AC2/AC6).

import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart'
    show trainCiviliansDialogId;
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/map_train_civilian_control.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test_hive_harness.dart';
import 'province_explore_shortcut_host_emit_event_test_support.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    await preloadNinePatchImage();
    gamesBox = await openAppTestHiveBox(
      suiteId: 'province_train_civilian_host_emit',
    );
  });

  Future<
    ({List<OpenCivilianUnitsPanelEvent> panel, List<OpenDialogEvent> dialog})
  >
  pumpHost(
    WidgetTester tester, {
    required Game game,
    required ProvinceShortcutHostCase host,
    bool canMutateViaUi = true,
  }) async {
    final dialog = <OpenDialogEvent>[];
    final panel = await pumpProvinceShortcutHostAndSelect(
      tester,
      gamesBox: gamesBox,
      gameService: provinceShortcutHostEmitGameService(
        gamesBox: gamesBox,
        gameId: kExploreShortcutGameId,
        combinedTopology: exploreShortcutCombinedTopology,
        tileMapByRegion: exploreShortcutTileMapByRegion,
        topologyByRegion: exploreShortcutTopologyByRegion,
      ),
      game: game,
      humanPlayerId: kExploreShortcutHumanPlayerId,
      host: host,
      region: exploreShortcutPartiallyRevealedRegion(),
      combinedTopology: exploreShortcutCombinedTopology,
      workTargetSelectionCache: exploreShortcutCache(),
      selectedTileKey: kExploreShortcutTileKey,
      dialogOpened: dialog,
      canMutateViaUi: canMutateViaUi,
    );
    return (panel: panel, dialog: dialog);
  }

  for (final host in provinceShortcutHostCases) {
    testWidgets('${host.wide ? 'wide' : 'narrow'} host: Train Explorer opens '
        'UNIT40001 without assigning work', (tester) async {
      final events = await pumpHost(
        tester,
        game: buildExploreShortcutGame(withExplorer: false),
        host: host,
      );
      expect(find.byKey(kProvinceOverlayTrainExplorerKey), findsOneWidget);
      final train = find.widgetWithText(CtActionTextButton, 'Train Explorer');
      expect(train, findsOneWidget);
      await tester.ensureVisible(train);
      await tester.tap(train);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(events.dialog, hasLength(1));
      expect(events.dialog.single.dialogId, trainCiviliansDialogId);
      expect(events.dialog.single.params, isNull);
      expect(events.panel, isEmpty);
      expect(find.byType(host.hostType), findsOneWidget);
      expect(find.byType(ProvinceSeaZoneDetailOverlay), findsOneWidget);
      final ctx = tester.element(find.byType(host.hostType));
      final orders = ProviderScope.containerOf(ctx).read(currentOrdersProvider);
      expect(orders.workOrdersByPlayerId, isEmpty);
      expect(orders.buildUnitOrdersByPlayerId, isEmpty);
    });
  }

  testWidgets('observe mode omits Train Explorer', (tester) async {
    final events = await pumpHost(
      tester,
      game: buildExploreShortcutGame(withExplorer: false),
      host: provinceShortcutHostCases.first,
      canMutateViaUi: false,
    );
    expect(find.byKey(kProvinceOverlayTrainExplorerKey), findsNothing);
    expect(events.dialog, isEmpty);
    expect(events.panel, isEmpty);
  });

  testWidgets('Explorer units omit Train Explorer', (tester) async {
    await pumpHost(
      tester,
      game: buildExploreShortcutGame(withExplorer: true),
      host: provinceShortcutHostCases.first,
    );
    expect(find.byKey(kProvinceOverlayTrainExplorerKey), findsNothing);
  });
}
