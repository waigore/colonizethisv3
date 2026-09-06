// Pins host-level Upgrade town shortcut-assignment tap flow (Refs #4316, #4352).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_state_logic.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart' show buildPlayerView;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_test_hive_harness.dart';
import 'province_shortcut_host_emit_test_support.dart';

const _kGameId = 'g_ut_shortcut_emit';
const _kHuman = kProvinceShortcutHostHumanPlayerId;
const _kProvince = kProvinceShortcutHostOldWorldProvinceId;
const _kTile = kProvinceShortcutHostTileKey;
final _maps = provinceShortcutHostPlainMaps();
final _region = provinceShortcutHostRegionView();
final _l10n = AppLocalizationsEn();

Game _buildGame({required bool withBuilder}) => Game(
  id: _kGameId,
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: [
        Province(
          id: _kProvince,
          regionId: 'oldWorld',
          ownerId: _kHuman,
          townDevelopmentLevel: 2,
          townTileKey: _kTile,
        ),
      ],
      units: [
        if (withBuilder)
          Unit(
            id: 'u_builder',
            type: kUnitTypeBuilder,
            ownerId: _kHuman,
            locationProvinceId: _kProvince,
            tileKey: _kTile,
            status: UnitStatus.idle,
          ),
      ],
    ),
    newWorld: const RegionData(provinces: [], units: []),
    resourceByTileKey: const {_kTile: 'grain'},
    tileKeysByRegionAndProvince: {
      'oldWorld': {_kProvince: [_kTile]},
    },
    playerVisibilityByTile: {_kHuman: {_kTile: 'fullyVisible'}},
  ),
  players: [
    Player(
      id: _kHuman,
      displayName: 'Human',
      isHuman: true,
      capitalProvinceId: _kProvince,
      stockpile: const Stockpile(quantities: {'lumber': 10, 'castIron': 10}),
      techUnlocked: const {kTechIdNationalBureaucracy: true},
    ),
  ],
  minorNations: const [],
  tribes: const [],
);

Finder _upgradeTownAction({required bool enabledOnly}) => find.byWidgetPredicate(
  (w) =>
      w is CtActionTextButton &&
      w.label == _l10n.provinceOverlay_upgradeTownAction &&
      (!enabledOnly || (w.enabled && w.onPressed != null)),
);

void main() {
  suppressLogsForTests();
  late Box<dynamic> gamesBox;
  late ProvinceShortcutHostEmitPump pumpHost;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'province_ut_shortcut_emit');
  });

  setUp(() {
    pumpHost = ProvinceShortcutHostEmitPump(
      gamesBox: gamesBox,
      gameId: _kGameId,
      humanPlayerId: _kHuman,
      maps: _maps,
      region: _region,
      selectedTileKey: _kTile,
    );
  });

  test('upgrade town action state fixture is enabled for host wiring', () {
    final game = _buildGame(withBuilder: true);
    final state = GameMapAreaStateLogicProvinceActions.provinceUpgradeTownActionState(
      game: game,
      humanPlayerId: _kHuman,
      provinceId: _kProvince,
      playerView: buildPlayerView(game, _maps.combinedTopology, _kHuman),
      topology: _maps.combinedTopology,
      currentOrders: const Orders(),
      tileMapByRegion: _maps.tileMapByRegion,
    );
    expect(state.showControl, isTrue);
    expect(state.enabled, isTrue);
    expect(state.townTileKey, _kTile);
  });

  Future<void> expectEmits(WidgetTester tester, List<OpenCivilianUnitsPanelEvent> opened) async {
    final shortcut = _upgradeTownAction(enabledOnly: true);
    expect(shortcut, findsOneWidget);
    await tester.ensureVisible(shortcut);
    await tester.tap(shortcut);
    await tester.pump();
    expect(opened, hasLength(1));
    final event = opened.single;
    expect(event.builderOnly, isTrue);
    expect(event.upgradeTownShortcutTargetTileKey, _kTile);
    expect(event.exploreShortcutTargetTileKey, isNull);
    expect(event.buildImprovementShortcutTargetTileKey, isNull);
  }

  for (final host in provinceShortcutHostCases) {
    testWidgets(
      '${host.wide ? 'wide' : 'narrow'} host: Upgrade town shortcut emits Builder-only event',
      (tester) async {
        final opened = await pumpHost(
          tester,
          game: _buildGame(withBuilder: true),
          host: provinceShortcutHostCaseWithoutTileTab(host),
        );
        await expectEmits(tester, opened);
      },
    );

    testWidgets(
      'negative — ${host.wide ? 'wide' : 'narrow'} host without Builder emits nothing',
      (tester) async {
        final opened = await pumpHost(
          tester,
          game: _buildGame(withBuilder: false),
          host: provinceShortcutHostCaseWithoutTileTab(host),
        );
        expect(_upgradeTownAction(enabledOnly: true), findsNothing);
        final disabled = _upgradeTownAction(enabledOnly: false);
        if (disabled.evaluate().isNotEmpty) {
          await tester.tap(disabled.first, warnIfMissed: false);
          await tester.pump();
        }
        expect(opened, isEmpty);
      },
    );
  }
}
