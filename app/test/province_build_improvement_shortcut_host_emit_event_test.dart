// Pins host-level Build improvement shortcut-assignment tap flow (Refs #2865).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_test_hive_harness.dart';
import 'province_shortcut_host_emit_test_support.dart';

const _kGameId = 'g_bi_shortcut_emit';
const _kHuman = kProvinceShortcutHostHumanPlayerId;
const _kProvince = kProvinceShortcutHostOldWorldProvinceId;
const _kTile = kProvinceShortcutHostTileKey;
final _maps = provinceShortcutHostCoastalMaps();
final _region = provinceShortcutHostRegionView();

Game _buildGame({required bool withBuilder}) => Game(
  id: _kGameId,
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: [Province(id: _kProvince, regionId: 'oldWorld', ownerId: _kHuman)],
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
    tileState: TileMapState(improvementByTile: {_kTile: 0}),
    playerVisibilityByTile: {_kHuman: {_kTile: 'fullyVisible'}},
  ),
  players: [
    Player(
      id: _kHuman,
      displayName: 'Human',
      isHuman: true,
      capitalProvinceId: _kProvince,
      stockpile: const Stockpile(quantities: {'lumber': 10, 'castIron': 10}),
      techUnlocked: const {kTechIdCircularSaw: true},
    ),
  ],
  minorNations: const [],
  tribes: const [],
);

void main() {
  suppressLogsForTests();
  late Box<dynamic> gamesBox;
  late ProvinceShortcutHostEmitPump pumpHost;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'province_bi_shortcut_emit');
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

  Future<void> expectEmits(WidgetTester tester, List<OpenCivilianUnitsPanelEvent> opened) async {
    final shortcut = provinceShortcutHostIconAction(Icons.handyman);
    expect(shortcut, findsOneWidget);
    await tester.ensureVisible(shortcut);
    await tester.tap(shortcut);
    await tester.pump();
    expect(opened, hasLength(1));
    final event = opened.single;
    expect(event.builderOnly, isTrue);
    expect(event.explorerOnly, isFalse);
    expect(event.buildImprovementShortcutTargetTileKey, _kTile);
    expect(event.exploreShortcutTargetTileKey, isNull);
    expect(event.prospectShortcutTargetTileKey, isNull);
  }

  for (final host in provinceShortcutHostCases) {
    testWidgets(
      '${host.wide ? 'wide' : 'narrow'} host: Build improvement shortcut emits Builder-only event',
      (tester) async {
        final opened = await pumpHost(tester, game: _buildGame(withBuilder: true), host: host);
        await expectEmits(tester, opened);
      },
    );

    testWidgets(
      'negative — ${host.wide ? 'wide' : 'narrow'} host without Builder emits nothing',
      (tester) async {
        final opened = await pumpHost(tester, game: _buildGame(withBuilder: false), host: host);
        await expectProvinceShortcutHostIconNegative(
          tester,
          enabledAction: provinceShortcutHostIconAction(Icons.handyman),
          anyAction: provinceShortcutHostIconAction(Icons.handyman, enabledOnly: false),
          opened: opened,
          wide: host.wide,
          wideDisabledReason:
              'Without an assignable Builder the Build improvement inline action must not be enabled.',
        );
      },
    );
  }
}
