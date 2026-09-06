// Golden + widget checks for MAP20001 Build port Engineer shortcut (Refs #4332).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_test_hive_harness.dart';
import 'province_shortcut_host_golden_test_support.dart';

const _kGameId = 'g_bp_golden';
const _kHuman = kProvinceShortcutHostHumanPlayerId;
const _kProvince = kProvinceShortcutHostOldWorldProvinceId;
const _kTile = kProvinceShortcutHostTileKey;
final _topology = provinceShortcutHostCombinedTopology();

Game goldenBuildPortGame() => Game(
  id: _kGameId,
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: [Province(id: _kProvince, regionId: 'oldWorld', ownerId: _kHuman)],
      units: [
        Unit(
          id: 'u_engineer',
          type: kUnitTypeEngineer,
          ownerId: _kHuman,
          locationProvinceId: _kProvince,
          tileKey: _kTile,
          status: UnitStatus.idle,
        ),
      ],
    ),
    newWorld: const RegionData(provinces: [], units: []),
    portsByProvinceSeaboard: const {},
    resourceByTileKey: const {_kTile: 'grain'},
    tileKeysByRegionAndProvince: {
      'oldWorld': {_kProvince: [_kTile]},
    },
    tileState: TileMapState(),
    playerVisibilityByTile: {_kHuman: {_kTile: 'fullyVisible'}},
  ),
  players: [
    Player(
      id: _kHuman,
      displayName: 'Human',
      isHuman: true,
      capitalProvinceId: _kProvince,
      stockpile: const Stockpile(quantities: {'lumber': 10, 'castIron': 10}),
    ),
  ],
  minorNations: const [],
  tribes: const [],
);

void main() {
  suppressLogsForTests();
  late Box<dynamic> gamesBox;
  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'province_bp_golden');
  });

  Future<void> pumpWide(WidgetTester tester) => pumpProvinceShortcutGoldenWideHost(
    tester,
    gamesBox: gamesBox,
    game: goldenBuildPortGame(),
    region: provinceShortcutHostRegionView(provinceDisplayName: 'Golden Province'),
    topology: _topology,
    boundaryKey: const ValueKey('province_bf_shortcut_wide_golden'),
    tileKey: _kTile,
    gameId: _kGameId,
  );

  Future<void> pumpNarrow(WidgetTester tester) => pumpProvinceShortcutGoldenNarrowHost(
    tester,
    gamesBox: gamesBox,
    game: goldenBuildPortGame(),
    region: provinceShortcutHostRegionView(provinceDisplayName: 'Golden Province'),
    topology: _topology,
    boundaryKey: const ValueKey('province_bf_shortcut_narrow_golden'),
    tileKey: _kTile,
    gameId: _kGameId,
  );

  testWidgets(
    'golden: wide province side panel shows enabled Build port shortcut (Refs #4332)',
    (tester) async {
      await pumpWide(tester);
      await expectLater(
        find.byKey(const ValueKey('province_bf_shortcut_wide_golden')),
        matchesGoldenFile('goldens/province_build_port_wide_panel.png'),
      );
    },
  );

  testWidgets(
    'narrow detail overlay shows enabled Build port shortcut (Refs #4332)',
    (tester) async {
      await pumpNarrow(tester);
      expect(
        find.byWidgetPredicate(
          (w) => w is CtIconAction && w.onPressed != null && w.icon == Icons.anchor,
        ),
        findsOneWidget,
      );
    },
  );
}
