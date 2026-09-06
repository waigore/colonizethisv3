// Golden + widget checks for MAP20001 Purchase land shortcut (Refs #4274).

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

const _kGameId = 'g_pl_golden';
const _kHuman = kProvinceShortcutHostHumanPlayerId;
const _kMinor = 'minor1';
const _kProvince = kProvinceShortcutHostOldWorldProvinceId;
const _kTile = kProvinceShortcutHostTileKey;
final _topology = provinceShortcutHostCombinedTopology();

Game goldenPurchaseLandGame() => Game(
  id: _kGameId,
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: [Province(id: _kProvince, regionId: 'oldWorld', ownerId: _kMinor)],
      units: [
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
  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'province_pl_golden');
  });

  Future<void> pumpWide(WidgetTester tester) => pumpProvinceShortcutGoldenWideHost(
    tester,
    gamesBox: gamesBox,
    game: goldenPurchaseLandGame(),
    region: provinceShortcutHostRegionView(
      ownerFactionId: _kMinor,
      provinceDisplayName: 'Minor Province',
    ),
    topology: _topology,
    boundaryKey: const ValueKey('province_pl_shortcut_wide_golden'),
    tileKey: _kTile,
    gameId: _kGameId,
    useCoastalTileMap: false,
  );

  Future<void> pumpNarrow(WidgetTester tester) => pumpProvinceShortcutGoldenNarrowHost(
    tester,
    gamesBox: gamesBox,
    game: goldenPurchaseLandGame(),
    region: provinceShortcutHostRegionView(
      ownerFactionId: _kMinor,
      provinceDisplayName: 'Minor Province',
    ),
    topology: _topology,
    boundaryKey: const ValueKey('province_pl_shortcut_narrow_golden'),
    tileKey: _kTile,
    gameId: _kGameId,
    useCoastalTileMap: false,
    afterTileTap: tapProvinceShortcutGoldenNarrowTileTab,
  );

  testWidgets(
    'golden: wide province side panel shows enabled Purchase land shortcut (Refs #4274)',
    (tester) async {
      await pumpWide(tester);
      await expectLater(
        find.byKey(const ValueKey('province_pl_shortcut_wide_golden')),
        matchesGoldenFile('goldens/province_purchase_land_wide_panel.png'),
      );
    },
  );

  testWidgets(
    'narrow detail overlay shows enabled Purchase land shortcut (Refs #4274)',
    (tester) async {
      await pumpNarrow(tester);
      expect(
        find.byWidgetPredicate(
          (w) => w is CtIconAction && w.onPressed != null && w.icon == Icons.payments,
        ),
        findsOneWidget,
      );
    },
  );
}
