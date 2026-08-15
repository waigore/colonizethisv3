// Pins Invade preselect after Home Army detach (issue #4407 AC 4).

import 'dart:async';

import 'package:colonizethis_app/features/game/widgets/unit_orders/home_army_detach_then_move_flow.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/move_army_dialog.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_world/colonizethis_world.dart' show applyArmySplit;
import 'package:flutter_test/flutter_test.dart';

import 'move_dialogs_specs_test_support.dart';

void main() {
  suppressLogsForTests();

  const playerId = 'gp_detach_invade';
  const rivalId = 'gp_rival';
  const from = 'oldWorld|p_from';
  const invade = 'oldWorld|p_invade';

  const topology = MapTopology(
    nodes: [
      TopologyNode(
        id: from,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: invade,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: [TopologyEdge(id1: from, id2: invade)],
  );

  Game buildGame() {
    return Game(
      id: 'g_detach_invade',
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
              id: invade,
              regionId: 'oldWorld',
              ownerId: rivalId,
              displayName: 'Invade Dest',
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
        ),
        newWorld: const RegionData(),
        armies: const [
          Army(
            id: 'home',
            ownerId: playerId,
            regionId: 'oldWorld',
            stationedProvinceId: from,
            regimentUnitIds: ['u1'],
            isHomeArmy: true,
          ),
        ],
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            from: ['oldWorld|p_from|0|0'],
            invade: ['oldWorld|p_invade|0|0'],
          },
        },
        playerVisibilityByTile: const {
          playerId: {
            'oldWorld|p_from|0|0': 'fullyVisible',
            'oldWorld|p_invade|0|0': 'fullyVisible',
          },
        },
      ),
      players: const [
        Player(
          id: playerId,
          displayName: 'Human',
          isHuman: true,
          capitalProvinceId: from,
        ),
        Player(
          id: rivalId,
          displayName: 'Rival',
          isHuman: false,
          capitalProvinceId: invade,
        ),
      ],
      diplomacyRelations: const [
        DiplomacyRelation(
          factionId1: playerId,
          factionId2: rivalId,
          state: RelationState.atWar,
          score: 20,
        ),
      ],
    );
  }

  testWidgets(
    'confirm split then confirm invade uses new army and preselected P',
    (tester) async {
      final game = buildGame();
      final bus = AppEventBus();
      final l10n = AppLocalizationsEn();
      ArmyMoveRequestedEvent? move;
      final splitSub = bus.on<ArmySplitRequestedEvent>().listen((event) {
        final next = applyArmySplit(
          game: game,
          playerId: event.humanPlayerId,
          sourceArmyId: event.sourceArmyId,
          unitIdsToMove: event.unitIdsToMove,
        );
        bus.emit(LandArmiesUpdatedEvent(game: next));
      });
      final moveSub = bus.on<ArmyMoveRequestedEvent>().listen((event) {
        move = event;
      });
      addTearDown(() async {
        await splitSub.cancel();
        await moveSub.cancel();
      });

      await tester.pumpWidget(
        moveDialogsSpecsFrameWithOpener((context) {
          return () {
            unawaited(
              showHomeArmyDetachThenMoveFlow(
                context: context,
                game: game,
                topology: topology,
                humanPlayerId: playerId,
                draftOrders: const Orders(),
                bus: bus,
                initialDestinationProvinceId: invade,
              ),
            );
          };
        }),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('pikemen')));
      await tester.pump();
      final detachConfirm = find.text(l10n.splitArmy_detachConfirm);
      await tester.ensureVisible(detachConfirm);
      await tester.pumpAndSettle();
      await tester.tap(detachConfirm);
      await tester.pumpAndSettle();

      final dialog = tester.widget<MoveArmyDialog>(find.byType(MoveArmyDialog));
      expect(dialog.army.isHomeArmy, isFalse);
      expect(dialog.initialDestinationProvinceId, invade);
      expect(find.text('Invade Dest'), findsOneWidget);
      final newArmyId = dialog.army.id;

      await tester.tap(
        find.widgetWithText(CtNinePatchButton, l10n.common_confirm),
      );
      await tester.pumpAndSettle();

      expect(move, isNotNull);
      expect(move!.moveOrder.armyId, newArmyId);
      expect(move!.moveOrder.armyId, isNot('home'));
      expect(move!.moveOrder.destinationProvinceId, invade);
    },
  );
}
