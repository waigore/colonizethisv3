// Pins province Prospect shortcut host emit wiring (Refs #4734 Slice H).

import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'province_prospect_shortcut_host_emit_fixtures.dart';
import 'province_shortcut_host_emit_test_support.dart';
import 'app_test_hive_harness.dart';

void main() {
  suppressLogsForTests();

  test('prospect action state fixture is enabled for host wiring', () {
    final game = buildProspectShortcutEmitGame(withExplorer: true);
    final playerView = buildPlayerView(
      game,
      kProspectShortcutEmitCombinedTopology,
      kProspectShortcutEmitHumanPlayerId,
    );
    final state =
        GameMapAreaStateLogicProvinceActions.provinceProspectActionState(
          game: game,
          humanPlayerId: kProspectShortcutEmitHumanPlayerId,
          selectedTileKey: kProspectShortcutEmitTileKey,
          playerView: playerView,
          topology: kProspectShortcutEmitCombinedTopology,
          currentOrders: const Orders(),
          tileMapByRegion: kProspectShortcutEmitTileMapByRegion,
        );
    expect(state.showIcon, isTrue);
    expect(state.enabled, isTrue);
  });

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'province_prospect_shortcut_emit');
  });

  Future<List<OpenCivilianUnitsPanelEvent>> pumpHostAndSelect(
    WidgetTester tester, {
    required Game game,
    required ProvinceShortcutHostCase host,
  }) => pumpProvinceShortcutHostAndSelect(
    tester,
    gamesBox: gamesBox,
    gameService: provinceShortcutHostEmitGameService(
      gamesBox: gamesBox,
      gameId: kProspectShortcutEmitGameId,
      combinedTopology: kProspectShortcutEmitCombinedTopology,
      tileMapByRegion: kProspectShortcutEmitTileMapByRegion,
      topologyByRegion: kProspectShortcutEmitTopologyByRegion,
    ),
    game: game,
    humanPlayerId: kProspectShortcutEmitHumanPlayerId,
    host: host,
    region: prospectShortcutEmitFullyVisibleRegion(),
    combinedTopology: kProspectShortcutEmitCombinedTopology,
    workTargetSelectionCache: refreshedProvinceShortcutWorkTargetCache(
      game: game,
      humanPlayerId: kProspectShortcutEmitHumanPlayerId,
      combinedTopology: kProspectShortcutEmitCombinedTopology,
      tileMapByRegion: kProspectShortcutEmitTileMapByRegion,
    ),
    selectedTileKey: kProspectShortcutEmitTileKey,
  );

  for (final host in provinceShortcutHostCases) {
    testWidgets(
      '${host.wide ? 'wide' : 'narrow'} host: tapping the enabled Prospect '
      'shortcut emits an explorer-only OpenCivilianUnitsPanelEvent targeting '
      'the exact selected tile key '
      '(SPEC § Tile inline actions — Prospect shortcut assignment)',
      (WidgetTester tester) async {
        final opened = await pumpHostAndSelect(
          tester,
          game: buildProspectShortcutEmitGame(withExplorer: true),
          host: host,
        );
        await expectProspectShortcutTapEmits(
          tester,
          opened: opened,
          hostLabel: host.label,
        );
      },
    );

    testWidgets(
      'negative — ${host.wide ? 'wide' : 'narrow'} host with no Explorer unit '
      'does not enable Prospect and emits no OpenCivilianUnitsPanelEvent',
      (WidgetTester tester) async {
        final opened = await pumpHostAndSelect(
          tester,
          game: buildProspectShortcutEmitGame(withExplorer: false),
          host: host.wide ? host : provinceShortcutHostCaseWithoutTileTab(host),
        );
        expect(prospectShortcutActionFinder(enabledOnly: true), findsNothing);
        if (host.wide) {
          final anyShortcut = prospectShortcutActionFinder(enabledOnly: false);
          if (anyShortcut.evaluate().isNotEmpty) {
            await tester.tap(anyShortcut.first, warnIfMissed: false);
            await tester.pump();
          }
        }
        expect(opened, isEmpty);
      },
    );
  }
}
