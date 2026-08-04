// Widget goldens for move army invasion underfed soft-warn (DLG20001 / #4242).
// SPEC/ui/move-army-dialog.md § Forces food soft warning.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/move_army_dialog.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';
import 'move_army_invasion_intel_goldens_test_support.dart';
import 'widget_test_assets.dart';

const _playerId = moveArmyInvasionIntelGoldenPlayerId;
const _rivalId = moveArmyInvasionIntelGoldenRivalId;
const _from = moveArmyInvasionIntelGoldenFrom;
const _invasionDest = moveArmyInvasionIntelGoldenInvasionDest;

Game _buildUnderfedInvasionGame() {
  return Game(
    id: 'g_move_army_underfed_golden',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: _from,
            regionId: 'oldWorld',
            ownerId: _playerId,
            displayName: 'Origin',
          ),
          Province(
            id: _invasionDest,
            regionId: 'oldWorld',
            ownerId: _rivalId,
            displayName: 'Invade Dest',
          ),
        ],
        units: [
          Unit(
            id: 'u1',
            type: 'musketeers',
            ownerId: _playerId,
            locationProvinceId: _from,
          ),
          Unit(
            id: 'u2',
            type: 'pikemen',
            ownerId: _playerId,
            locationProvinceId: _from,
          ),
          Unit(
            id: 'u3',
            type: 'pikemen',
            ownerId: _playerId,
            locationProvinceId: _from,
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: const [
        Army(
          id: 'a_move',
          ownerId: _playerId,
          regionId: 'oldWorld',
          stationedProvinceId: _from,
          regimentUnitIds: ['u1', 'u2', 'u3'],
          isHomeArmy: false,
        ),
      ],
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          _from: ['oldWorld|p_from|0|0'],
          _invasionDest: ['oldWorld|p_invade|0|0'],
        },
      },
      playerVisibilityByTile: {
        _playerId: {
          'oldWorld|p_from|0|0': 'fullyVisible',
          'oldWorld|p_invade|0|0': 'fullyVisible',
        },
      },
    ),
    players: [
      Player(
        id: _playerId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: _from,
        stockpile: const Stockpile().applyDelta('grain', 2),
      ),
      Player(
        id: _rivalId,
        displayName: 'Rival',
        isHuman: false,
        capitalProvinceId: _invasionDest,
      ),
    ],
  );
}

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  testWidgets(
    'golden: invasion destination shows land underfed soft warning (Refs #4242)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'moveArmyInvasionUnderfedForcesGolden',
      );
      final topology = buildMoveArmyInvasionIntelGoldenTopology();
      final game = _buildUnderfedInvasionGame();
      final view = buildPlayerView(game, topology, _playerId);
      final army = game.worldState.armies.first;

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: kMoveArmyInvasionIntelGoldenViewport,
        settle: false,
        includeLocalizations: true,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: MoveArmyDialog(
          army: army,
          game: game,
          humanPlayerId: _playerId,
          bus: AppEventBus.create(),
          topology: topology,
          draftOrders: const Orders(),
          playerView: view,
        ),
      );

      await tester.tap(find.text('Invade Dest'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(
        find.text(
          'Your armies are very short on rations — they will fight much weaker this turn.',
        ),
        findsOneWidget,
      );

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/move_army_invasion_underfed_forces.png'),
      );
    },
  );
}
