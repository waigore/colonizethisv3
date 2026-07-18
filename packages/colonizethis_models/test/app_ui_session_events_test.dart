import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('UIActionEvent payloads', () {
    test('carry their constructor arguments', () {
      const open = OpenDialogEvent('confirm', {'k': 1});
      expect(open.dialogId, 'confirm');
      expect(open.params, {'k': 1});

      const navigate = NavigateToRouteEvent('/game', 42);
      expect(navigate.route, '/game');
      expect(navigate.arguments, 42);

      const panel = OpenPanelEvent('side', {'x': true});
      expect(panel.panelId, 'side');
      expect(panel.params, {'x': true});

      const locate = LocateMapTileEvent(tileKey: 'r1|p1|0|0', regionId: 'r1');
      expect(locate.tileKey, 'r1|p1|0|0');
      expect(locate.regionId, 'r1');

      const civilians = OpenCivilianUnitsPanelEvent(
        tileScopeTileKey: 'r1|p1|1|1',
        explorerOnly: true,
      );
      expect(civilians.tileScopeTileKey, 'r1|p1|1|1');
      expect(civilians.explorerOnly, isTrue);
      expect(civilians.builderOnly, isFalse);
    });

    test('ConfirmDialogEvent invokes its result callback', () {
      bool? answer;
      final event = ConfirmDialogEvent(
        title: 'Quit?',
        message: 'Sure?',
        onResult: (v) => answer = v,
      );
      expect(event.confirmLabel, 'OK');
      expect(event.cancelLabel, 'Cancel');
      event.result(true);
      expect(answer, isTrue);
    });

    test('CombatModeChosenEvent retains chosen mode', () {
      const event = CombatModeChosenEvent(CombatMode.quickBattle);
      expect(event.mode, CombatMode.quickBattle);
    });
  });

  group('UISystemEvent payloads', () {
    test('snackbar action callback fires', () {
      var fired = false;
      final event = ShowSnackBarEvent(
        message: 'Saved',
        actionLabel: 'Undo',
        action: () => fired = true,
      );
      expect(event.message, 'Saved');
      expect(event.actionLabel, 'Undo');
      event.action?.call();
      expect(fired, isTrue);
    });

    test('overlay and notify events carry their fields', () {
      const overlay = ShowOverlayEvent(overlayId: 'spinner');
      expect(overlay.overlayId, 'spinner');
      const dismiss = DismissOverlayEvent('spinner');
      expect(dismiss.overlayId, 'spinner');
      const notify = NotifyEvent(
        title: 'Research',
        body: 'Done',
        priority: NotifyPriority.high,
      );
      expect(notify.priority, NotifyPriority.high);
      expect(NotifyPriority.values, hasLength(3));
    });
  });

  group('GameToUIEvent payloads', () {
    test('turn resolution and capture mirrors carry fields', () {
      const turn = TurnResolutionCompleteEvent(gameId: 'g1', turnNumber: 5);
      expect(turn.gameId, 'g1');
      expect(turn.turnNumber, 5);
      expect(turn.turnNewsDigest, isNull);

      const combat = AppCombatResultEvent(
        provinceId: 'r1|p1',
        attackerId: 'A',
        defenderId: 'D',
        winnerId: 'A',
        turnNumber: 2,
        casualties: {'A': 1},
      );
      expect(combat.winnerId, 'A');
      expect(combat.casualties['A'], 1);

      const captured = AppProvinceCapturedEvent(
        provinceId: 'r1|p1',
        previousOwnerId: 'D',
        newOwnerId: 'A',
        turnNumber: 2,
      );
      expect(captured.newOwnerId, 'A');

      const required = OvertureRequiredEvent(overtures: []);
      expect(required.overtures, isEmpty);
    });
  });

  group('SessionCommandEvent payloads', () {
    test('debug spawn and credit events carry fields', () {
      const spawn = SpawnDebugCivilianAtCapitalEvent(
        humanPlayerId: 'p1',
        unitType: 'farmer',
        count: 3,
      );
      expect(spawn.unitType, 'farmer');
      expect(spawn.count, 3);

      const credit = CreditDebugTreasuryEvent(
        humanPlayerId: 'p1',
        requestedAmount: 100,
        creditedAmount: 90,
      );
      expect(credit.creditedAmount, 90);
    });

    test('FlipDebugProvinceOwnershipEvent asserts exclusive target form', () {
      expect(
        () => FlipDebugProvinceOwnershipEvent(humanPlayerId: 'p1'),
        throwsA(isA<AssertionError>()),
      );
      const valid = FlipDebugProvinceOwnershipEvent(
        humanPlayerId: 'p1',
        fullProvinceId: 'r1|p1',
      );
      expect(valid.fullProvinceId, 'r1|p1');
    });

    test('remaining session command payloads carry fields', () {
      expect(
        RemovePendingWorkOrderRequestedEvent(playerId: 'p1', index: 2).index,
        2,
      );
      expect(
        NavalSplitFleetRequestedEvent(
          humanPlayerId: 'p1',
          originalFleetId: 'f1',
          shipInstanceIdsToNewFleet: const ['ship_1'],
        ).originalFleetId,
        'f1',
      );
      expect(
        NavalTransferShipsRequestedEvent(
          humanPlayerId: 'p1',
          sourceFleetId: 'f1',
          targetFleetId: 'f2',
          shipInstanceIdsToTransfer: const ['ship_1'],
        ).targetFleetId,
        'f2',
      );
      expect(
        NavalMoveFleetRequestedEvent(
          humanPlayerId: 'p1',
          moveOrder: const NavalMoveOrder(
            fleetId: 'f1',
            destinationSeaZoneId: 'sz1',
          ),
        ).moveOrder.fleetId,
        'f1',
      );
      expect(
        ArmyCombineRequestedEvent(
          humanPlayerId: 'p1',
          armyIds: const ['a1'],
        ).armyIds,
        ['a1'],
      );
      expect(
        ArmySplitRequestedEvent(
          humanPlayerId: 'p1',
          sourceArmyId: 'a1',
          unitIdsToMove: const ['u1'],
        ).sourceArmyId,
        'a1',
      );
      expect(
        ArmyMoveRequestedEvent(
          humanPlayerId: 'p1',
          moveOrder: const ArmyMoveOrder(
            armyId: 'a1',
            destinationProvinceId: 'r1|p1',
          ),
          declareWarTargetFactionId: 'B',
        ).declareWarTargetFactionId,
        'B',
      );
      expect(
        const SpawnDebugRegimentAtCapitalEvent(
          humanPlayerId: 'p1',
          regimentTypeId: 'line_infantry',
        ).regimentTypeId,
        'line_infantry',
      );
      expect(
        const SpawnDebugShipAtCapitalHomeFleetEvent(
          humanPlayerId: 'p1',
          shipTypeId: 'carrack',
        ).shipTypeId,
        'carrack',
      );
      expect(
        const CreditDebugWorkerPoolEvent(
          humanPlayerId: 'p1',
          workerTierId: 'peasants',
          requestedAmount: 5,
          creditedAmount: 5,
        ).workerTierId,
        'peasants',
      );
      expect(
        const CreditDebugStockpileCommodityEvent(
          humanPlayerId: 'p1',
          commodityId: 'grain',
          requestedAmount: 5,
          creditedAmount: 5,
        ).commodityId,
        'grain',
      );
      expect(
        const RevealDebugProvinceEvent(
          humanPlayerId: 'p1',
          target: 'r1|p1',
          targetIsFullProvinceId: true,
        ).targetIsFullProvinceId,
        isTrue,
      );
      expect(const SetObserveModeOffEvent(), isA<SessionCommandEvent>());
      expect(const SetObserveModeGlobalEvent(), isA<SessionCommandEvent>());
      expect(
        const SetObserveModePlayerEvent(targetPlayerId: 'p2').targetPlayerId,
        'p2',
      );
      expect(
        AppendDiplomaticOrderRequestedEvent(
          playerId: 'p1',
          order: const DiplomaticOrder(
            type: DiplomaticOrderType.offerPeace,
            targetFactionId: 'B',
          ),
        ).order.targetFactionId,
        'B',
      );
      expect(
        RemoveDiplomaticOrderRequestedEvent(
          playerId: 'p1',
          type: DiplomaticOrderType.alliance,
          targetFactionId: 'B',
        ).type,
        DiplomaticOrderType.alliance,
      );
      expect(
        const NegotiationMoodUpdateEvent(
          leaderId: 'v',
          currentMood: 'neutral',
          offerQualityDelta: 0.2,
          stallCounter: 1,
          seed: 7,
        ).durationMs,
        1200,
      );
    });
  });
}
