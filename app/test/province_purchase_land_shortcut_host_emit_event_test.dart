// Pins host-level Purchase land shortcut-assignment tap flow (Refs #4274).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart' show buildPlayerView;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_test_hive_harness.dart';
import 'province_shortcut_host_emit_test_support.dart';

const _kGameId = 'g_pl_shortcut_emit';
const _kHuman = kProvinceShortcutHostHumanPlayerId;
const _kMinor = 'minor1';
const _kProvince = kProvinceShortcutHostOldWorldProvinceId;
const _kTile = kProvinceShortcutHostTileKey;
final _maps = provinceShortcutHostPlainMaps();
final _region = provinceShortcutHostRegionView(
  ownerFactionId: _kMinor,
  provinceDisplayName: 'Minor Province',
);

Game _buildGame({required bool withMerchant}) => Game(
  id: _kGameId,
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: [Province(id: _kProvince, regionId: 'oldWorld', ownerId: _kMinor)],
      units: [
        if (withMerchant)
          Unit(
            id: 'u_merchant',
            type: kUnitTypeMerchant,
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
      capitalProvinceId: 'oldWorld|home',
      treasury: 500,
      techUnlocked: const {kTechIdMerchantCompanies: true},
    ),
  ],
  minorNations: const [MinorNation(id: _kMinor, displayName: 'Minor 1')],
  tribes: const [],
  overtureStates: const [
    OvertureState(
      gpId: _kHuman,
      targetId: _kMinor,
      stage: OvertureStage.embassy,
      sinceTurn: 0,
    ),
  ],
);

void main() {
  suppressLogsForTests();
  late Box<dynamic> gamesBox;
  late ProvinceShortcutHostEmitPump pumpHost;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'province_pl_shortcut_emit');
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

  test('purchase land action state fixture is enabled for host wiring', () {
    final game = _buildGame(withMerchant: true);
    final state = GameMapAreaStateLogicProvinceActions.provincePurchaseLandActionState(
      game: game,
      humanPlayerId: _kHuman,
      selectedTileKey: _kTile,
      playerView: buildPlayerView(game, _maps.combinedTopology, _kHuman),
      topology: _maps.combinedTopology,
      currentOrders: const Orders(),
      tileMapByRegion: _maps.tileMapByRegion,
    );
    expect(state.showIcon, isTrue);
    expect(state.enabled, isTrue);
  });

  Future<void> expectEmits(WidgetTester tester, List<OpenCivilianUnitsPanelEvent> opened) async {
    final shortcut = provinceShortcutHostIconAction(Icons.payments);
    expect(shortcut, findsOneWidget);
    await tester.ensureVisible(shortcut);
    await tester.tap(shortcut);
    await tester.pump();
    expect(opened, hasLength(1));
    final event = opened.single;
    expect(event.merchantOnly, isTrue);
    expect(event.purchaseLandShortcutTargetTileKey, _kTile);
    expect(event.exploreShortcutTargetTileKey, isNull);
    expect(event.buildRoadShortcutTargetTileKey, isNull);
  }

  for (final host in provinceShortcutHostCases) {
    testWidgets(
      '${host.wide ? 'wide' : 'narrow'} host: Purchase land shortcut emits merchant-only event',
      (tester) async {
        final opened = await pumpHost(tester, game: _buildGame(withMerchant: true), host: host);
        await expectEmits(tester, opened);
      },
    );

    testWidgets(
      'negative — ${host.wide ? 'wide' : 'narrow'} host without Merchant emits nothing',
      (tester) async {
        final negativeHost = host.wide ? host : provinceShortcutHostCaseWithoutTileTab(host);
        final opened = await pumpHost(
          tester,
          game: _buildGame(withMerchant: false),
          host: negativeHost,
        );
        expect(provinceShortcutHostIconAction(Icons.payments), findsNothing);
        if (host.wide) {
          final any = provinceShortcutHostIconAction(Icons.payments, enabledOnly: false);
          if (any.evaluate().isNotEmpty) {
            await tester.tap(any.first, warnIfMissed: false);
            await tester.pump();
          }
        }
        expect(opened, isEmpty);
      },
    );
  }
}
