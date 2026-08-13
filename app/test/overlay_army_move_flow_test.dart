// Pins overlay army move flow + picker (Refs #4350).

import 'dart:async';

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_army_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/overlay_army_move_flow.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/overlay_army_move_picker_dialog.dart';
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

  const playerId = 'gp_flow';
  const from = 'oldWorld|p_from';
  const dest = 'oldWorld|p_dest';

  MapTopology topology() => const MapTopology(
    nodes: [
      TopologyNode(
        id: from,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: dest,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: [TopologyEdge(id1: from, id2: dest)],
  );

  Game buildGame({required List<Army> armies, required List<Unit> units}) {
    return Game(
      id: 'g_flow',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: const [
            Province(
              id: from,
              regionId: 'oldWorld',
              ownerId: playerId,
              displayName: 'From',
            ),
            Province(
              id: dest,
              regionId: 'oldWorld',
              ownerId: playerId,
              displayName: 'Dest',
            ),
          ],
          units: units,
        ),
        newWorld: const RegionData(),
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            from: ['oldWorld|p_from|0|0'],
            dest: ['oldWorld|p_dest|0|0'],
          },
        },
        playerVisibilityByTile: const {
          playerId: {
            'oldWorld|p_from|0|0': 'fullyVisible',
            'oldWorld|p_dest|0|0': 'fullyVisible',
          },
        },
        armies: armies,
      ),
      players: const [
        Player(id: playerId, displayName: 'Human', isHuman: true),
      ],
    );
  }

  testWidgets('single army opens MoveArmyDialog immediately', (tester) async {
    final game = buildGame(
      armies: const [
        Army(
          id: 'a1',
          ownerId: playerId,
          regionId: 'oldWorld',
          stationedProvinceId: from,
          regimentUnitIds: ['u1'],
        ),
      ],
      units: [
        Unit(
          id: 'u1',
          type: 'pikemen',
          ownerId: playerId,
          locationProvinceId: from,
        ),
      ],
    );
    final bus = AppEventBus();
    final l10n = AppLocalizationsEn();

    await tester.pumpWidget(
      moveDialogsSpecsFrameWithOpener((context) {
        return () {
          unawaited(
            showOverlayArmyMoveFlow(
              context: context,
              game: game,
              topology: topology(),
              humanPlayerId: playerId,
              draftOrders: const Orders(),
              bus: bus,
              armyIds: const ['a1'],
            ),
          );
        };
      }),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(OverlayArmyMovePickerDialog), findsNothing);
    expect(find.byType(MoveArmyDialog), findsOneWidget);
    expect(find.text(l10n.moveArmy_title('a1')), findsOneWidget);
  });

  testWidgets('multi army shows picker then dialog', (tester) async {
    final game = buildGame(
      armies: const [
        Army(
          id: 'a1',
          ownerId: playerId,
          regionId: 'oldWorld',
          stationedProvinceId: from,
          regimentUnitIds: ['u1'],
        ),
        Army(
          id: 'a2',
          ownerId: playerId,
          regionId: 'oldWorld',
          stationedProvinceId: from,
          regimentUnitIds: ['u2'],
        ),
      ],
      units: [
        Unit(
          id: 'u1',
          type: 'pikemen',
          ownerId: playerId,
          locationProvinceId: from,
        ),
        Unit(
          id: 'u2',
          type: 'pikemen',
          ownerId: playerId,
          locationProvinceId: from,
        ),
      ],
    );
    final bus = AppEventBus();
    final l10n = AppLocalizationsEn();

    await tester.pumpWidget(
      moveDialogsSpecsFrameWithOpener((context) {
        return () {
          unawaited(
            showOverlayArmyMoveFlow(
              context: context,
              game: game,
              topology: topology(),
              humanPlayerId: playerId,
              draftOrders: const Orders(),
              bus: bus,
              armyIds: const ['a1', 'a2'],
            ),
          );
        };
      }),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(OverlayArmyMovePickerDialog), findsOneWidget);
    expect(find.text(l10n.provinceOverlay_selectArmyTitle), findsOneWidget);

    await tester.tap(
      find.widgetWithText(CtNinePatchButton, l10n.common_confirm),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OverlayArmyMovePickerDialog), findsNothing);
    expect(find.byType(MoveArmyDialog), findsOneWidget);
  });
}
