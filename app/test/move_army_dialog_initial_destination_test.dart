// Pins MoveArmyDialog initialDestinationProvinceId selection (Refs #4350).
// Reuses move_dialogs_specs_part1 fixture shape so destinations validate.

import 'dart:async';

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_army_dialog.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'move_dialogs_specs_test_support.dart';

void main() {
  suppressLogsForTests();

  const playerId = 'gp_specs_army';
  const otherFactionId = 'gp_specs_rival';
  const from = 'oldWorld|p_from';
  const playerDest = 'oldWorld|p_owned';
  const invasionDest = 'oldWorld|p_invade';

  MapTopology buildTopology() {
    return const MapTopology(
      nodes: [
        TopologyNode(
          id: from,
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: playerDest,
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: invasionDest,
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
      ],
      edges: [
        TopologyEdge(id1: from, id2: playerDest),
        TopologyEdge(id1: from, id2: invasionDest),
      ],
    );
  }

  Game buildGame() {
    return Game(
      id: 'g_specs_army_init',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: const [
            Province(
              id: from,
              regionId: 'oldWorld',
              ownerId: playerId,
              displayName: 'Origin',
            ),
            Province(
              id: playerDest,
              regionId: 'oldWorld',
              ownerId: playerId,
              displayName: 'Owned Dest',
            ),
            Province(
              id: invasionDest,
              regionId: 'oldWorld',
              ownerId: otherFactionId,
              displayName: 'Invade Dest',
            ),
          ],
          units: [
            Unit(
              id: 'u_specs',
              type: 'musketeers',
              ownerId: playerId,
              locationProvinceId: from,
            ),
          ],
        ),
        newWorld: const RegionData(),
        armies: const [
          Army(
            id: 'aspecs',
            ownerId: playerId,
            regionId: 'oldWorld',
            stationedProvinceId: from,
            regimentUnitIds: ['u_specs'],
            isHomeArmy: false,
          ),
        ],
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            from: ['oldWorld|p_from|0|0'],
            playerDest: ['oldWorld|p_owned|0|0'],
            invasionDest: ['oldWorld|p_invade|0|0'],
          },
        },
        playerVisibilityByTile: const {
          playerId: {
            'oldWorld|p_from|0|0': 'fullyVisible',
            'oldWorld|p_owned|0|0': 'fullyVisible',
            'oldWorld|p_invade|0|0': 'fullyVisible',
          },
        },
      ),
      players: const [
        Player(
          id: playerId,
          displayName: 'Specs Player',
          isHuman: true,
          capitalProvinceId: from,
        ),
        Player(
          id: otherFactionId,
          displayName: 'Specs Rival',
          isHuman: false,
          capitalProvinceId: invasionDest,
        ),
      ],
    );
  }

  testWidgets(
    'initialDestinationProvinceId selects invade row not first owned',
    (tester) async {
      final game = buildGame();
      final army = game.worldState.armies.first;
      final bus = AppEventBus.create();
      final l10n = AppLocalizationsEn();

      await tester.pumpWidget(
        moveDialogsSpecsFrameWithOpener((context) {
          return () {
            unawaited(
              showDialog<void>(
                context: context,
                builder: (_) => MoveArmyDialog(
                  army: army,
                  game: game,
                  humanPlayerId: playerId,
                  bus: bus,
                  topology: buildTopology(),
                  draftOrders: const Orders(),
                  initialDestinationProvinceId: invasionDest,
                ),
              ),
            );
          };
        }),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(MoveArmyDialog), findsOneWidget);
      expect(find.text('YOUR PROVINCES'), findsOneWidget);
      expect(find.text('INVASION TARGETS'), findsOneWidget);
      expect(find.text('Owned Dest'), findsOneWidget);
      expect(find.text('Invade Dest'), findsOneWidget);
      // Confirm enabled with invade preselected (not requiring re-tap).
      final confirm = tester.widget<CtNinePatchButton>(
        find.widgetWithText(CtNinePatchButton, l10n.common_confirm),
      );
      expect(confirm.onPressed, isNotNull);
      // Declare-war trigger appears only when invasion row is selected.
      expect(find.text('declare war on Specs Rival'), findsOneWidget);
    },
  );
}
