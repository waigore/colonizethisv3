// Pins host-level Build railroad shortcut-assignment tap flow (Refs #4383).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_test_hive_harness.dart';
import 'province_shortcut_host_emit_test_support.dart';

const _kGameId = 'g_brr_shortcut_emit';
const _kHuman = kProvinceShortcutHostHumanPlayerId;
const _kProvince = kProvinceShortcutHostOldWorldProvinceId;
const _kTile = kProvinceShortcutHostTileKey;
final _maps = provinceShortcutHostCoastalMaps();
final _region = provinceShortcutHostRegionView();

Game _buildGame({required bool withRailBuilder, int roadLevel = 1}) => Game(
  id: _kGameId,
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    portsByProvinceSeaboard: const {},
    oldWorld: RegionData(
      provinces: [Province(id: _kProvince, regionId: 'oldWorld', ownerId: _kHuman)],
      units: [
        if (withRailBuilder)
          Unit(
            id: 'u_rail',
            type: kUnitTypeRailBuilder,
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
    tileState: TileMapState().setRoadLevel(_kTile, roadLevel),
    playerVisibilityByTile: {_kHuman: {_kTile: 'fullyVisible'}},
  ),
  players: [
    Player(
      id: _kHuman,
      displayName: 'Human',
      isHuman: true,
      capitalProvinceId: _kProvince,
      stockpile: const Stockpile(quantities: {'lumber': 10, 'steel': 10}),
      techUnlocked: const {kTechIdEarlySteamEngine: true},
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
    gamesBox = await openAppTestHiveBox(suiteId: 'province_brr_shortcut_emit');
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
    final shortcut = provinceShortcutHostIconAction(Icons.directions_railway);
    expect(shortcut, findsOneWidget);
    await tester.ensureVisible(shortcut);
    await tester.tap(shortcut);
    await tester.pump();
    expect(opened, hasLength(1));
    final event = opened.single;
    expect(event.railBuilderOnly, isTrue);
    expect(event.engineerOnly, isFalse);
    expect(event.buildRailShortcutTargetTileKey, _kTile);
    expect(event.buildPortShortcutTargetTileKey, isNull);
    expect(event.buildRoadShortcutTargetTileKey, isNull);
  }

  for (final host in provinceShortcutHostCases) {
    testWidgets(
      '${host.wide ? 'wide' : 'narrow'} host: Build railroad shortcut emits Rail-Builder-only event',
      (tester) async {
        final opened = await pumpHost(
          tester,
          game: _buildGame(withRailBuilder: true),
          host: host,
        );
        await expectEmits(tester, opened);
      },
    );

    testWidgets(
      'negative — ${host.wide ? 'wide' : 'narrow'} host without Rail Builder emits nothing',
      (tester) async {
        final opened = await pumpHost(
          tester,
          game: _buildGame(withRailBuilder: false),
          host: host,
        );
        await expectProvinceShortcutHostIconNegative(
          tester,
          enabledAction: provinceShortcutHostIconAction(Icons.directions_railway),
          anyAction: provinceShortcutHostIconAction(Icons.directions_railway, enabledOnly: false),
          opened: opened,
          wide: host.wide,
          wideDisabledReason:
              'Without an assignable Rail Builder the Build railroad inline action must not be enabled.',
        );
      },
    );

    for (final roadLevel in [0, 4])
      testWidgets(
        'negative — ${host.wide ? 'wide' : 'narrow'} host hides Build railroad when transport is $roadLevel',
        (tester) async {
          final opened = await pumpHost(
            tester,
            game: _buildGame(withRailBuilder: true, roadLevel: roadLevel),
            host: host,
          );
          expect(
            provinceShortcutHostIconAction(Icons.directions_railway, enabledOnly: false),
            findsNothing,
          );
          expect(opened, isEmpty);
        },
      );
  }
}
