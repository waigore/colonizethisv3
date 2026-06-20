import 'dart:async';

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('AppEventBus', () {
    tearDown(AppEventBus.reset);

    test('singleton factory returns the same instance', () {
      final a = AppEventBus();
      final b = AppEventBus();
      expect(identical(a, b), isTrue);
      AppEventBus.reset();
      expect(identical(AppEventBus(), a), isFalse);
    });

    test('create returns a fresh, non-singleton bus', () {
      final fresh = AppEventBus.create();
      expect(identical(fresh, AppEventBus()), isFalse);
      fresh.dispose();
    });

    test('on<T> filters the broadcast stream by event type', () async {
      final bus = AppEventBus.create();
      final actions = <UIActionEvent>[];
      final system = <UISystemEvent>[];
      final subA = bus.uiActionEvents.listen(actions.add);
      final subS = bus.uiSystemEvents.listen(system.add);

      bus.emit(const ClosePanelEvent());
      bus.emit(const ShowSnackBarEvent(message: 'hi'));
      bus.emit(const PopNavigationEvent());

      await Future<void>.delayed(Duration.zero);

      expect(actions, hasLength(2));
      expect(actions.whereType<ClosePanelEvent>(), hasLength(1));
      expect(system, hasLength(1));
      expect(system.single, isA<ShowSnackBarEvent>());

      await subA.cancel();
      await subS.cancel();
      bus.dispose();
    });

    test('typed accessors expose category sub-streams', () async {
      final bus = AppEventBus.create();
      final sessionEvents = <SessionCommandEvent>[];
      final gameEvents = <GameToUIEvent>[];
      final dialogueEvents = <DialogueEvent>[];
      final moodEvents = <PortraitMoodEvent>[];
      final subSession = bus.sessionCommandEvents.listen(sessionEvents.add);
      final subGame = bus.gameToUIEvents.listen(gameEvents.add);
      final subDialogue = bus.dialogueEvents.listen(dialogueEvents.add);
      final subMood = bus.portraitMoodEvents.listen(moodEvents.add);

      bus.emit(CancelInProgressCivilianWorkRequestedEvent(unitId: 'u1'));
      bus.emit(const SaveGameCompleteEvent(gameId: 'g1'));
      bus.emit(const DialogueEvent(
        leaderId: 'victoria',
        category: 'greeting',
        situation: 'meet',
        era: 'industrial',
      ));
      bus.emit(const PortraitMoodEvent(
        leaderId: 'victoria',
        fromMood: 'neutral',
        toMood: 'pleased',
      ));

      await Future<void>.delayed(Duration.zero);

      expect(sessionEvents, hasLength(1));
      expect(gameEvents, hasLength(1));
      expect(dialogueEvents, hasLength(1));
      expect(moodEvents, hasLength(1));

      await subSession.cancel();
      await subGame.cancel();
      await subDialogue.cancel();
      await subMood.cancel();
      bus.dispose();
    });
  });

  group('DialogueEvent', () {
    test('toJson omits empty optionals and round-trips', () {
      const event = DialogueEvent(
        leaderId: 'napoleon',
        category: 'taunt',
        situation: 'war',
        era: 'napoleonic',
      );
      final json = event.toJson();
      expect(json.containsKey('mood'), isFalse);
      expect(json.containsKey('variables'), isFalse);

      final restored = DialogueEvent.fromJson(json);
      expect(restored.leaderId, 'napoleon');
      expect(restored.category, 'taunt');
      expect(restored.situation, 'war');
      expect(restored.era, 'napoleonic');
      expect(restored.mood, isNull);
      expect(restored.variables, isEmpty);
    });

    test('toJson/fromJson round-trips mood and variables', () {
      const event = DialogueEvent(
        leaderId: 'victoria',
        category: 'greeting',
        situation: 'peace',
        era: 'industrial',
        mood: 'pleased',
        variables: {'rival': 'France'},
      );
      final restored = DialogueEvent.fromJson(event.toJson());
      expect(restored.mood, 'pleased');
      expect(restored.variables, {'rival': 'France'});
    });
  });

  group('PortraitMoodEvent', () {
    test('toJson/fromJson round-trips all fields', () {
      const event = PortraitMoodEvent(
        leaderId: 'victoria',
        fromMood: 'neutral',
        toMood: 'angry',
        durationMs: 800,
      );
      final restored = PortraitMoodEvent.fromJson(event.toJson());
      expect(restored.leaderId, 'victoria');
      expect(restored.fromMood, 'neutral');
      expect(restored.toMood, 'angry');
      expect(restored.durationMs, 800);
    });

    test('fromJson defaults durationMs to zero', () {
      final restored = PortraitMoodEvent.fromJson({
        'leaderId': 'v',
        'fromMood': 'a',
        'toMood': 'b',
      });
      expect(restored.durationMs, 0);
    });
  });

  group('DefaultDialogueEventBus', () {
    test('publish delivers to subscribers and unsubscribe stops delivery',
        () async {
      final bus = DefaultDialogueEventBus();
      final received = <DialogueEvent>[];
      final unsubscribe = bus.subscribe<DialogueEvent>(received.add);

      bus.publish(const DialogueEvent(
        leaderId: 'v',
        category: 'c',
        situation: 's',
        era: 'e',
      ));
      await Future<void>.delayed(Duration.zero);
      expect(received, hasLength(1));

      unsubscribe();
      bus.publish(const DialogueEvent(
        leaderId: 'v2',
        category: 'c',
        situation: 's',
        era: 'e',
      ));
      await Future<void>.delayed(Duration.zero);
      expect(received, hasLength(1));

      bus.dispose();
    });

    test('events stream exposes published events', () async {
      final bus = DefaultDialogueEventBus();
      final future = bus.events.first;
      bus.publish(const DialogueEvent(
        leaderId: 'leader',
        category: 'c',
        situation: 's',
        era: 'e',
      ));
      final event = await future;
      expect(event.leaderId, 'leader');
      bus.dispose();
    });
  });

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
          moveOrder:
              const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sz1'),
        ).moveOrder.fleetId,
        'f1',
      );
      expect(
        ArmyCombineRequestedEvent(humanPlayerId: 'p1', armyIds: const ['a1'])
            .armyIds,
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

  group('remaining UIActionEvent payloads', () {
    test('no-argument requests instantiate as UIActionEvent', () {
      for (final event in const <UIActionEvent>[
        NavigateToShellEvent(),
        PopNavigationEvent(),
        ClosePanelEvent(),
        OpenPauseMenuPanelEvent(),
        RequestExitToMainMenuFlowEvent(),
        OpenMilitaryUnitsPanelEvent(),
        OpenNavalUnitsPanelEvent(),
        ToggleDebugConsolePanelEvent(),
        OpenDebugConsolePanelEvent(),
        CloseDebugConsolePanelEvent(),
        CancelTargetSelectionEvent(),
      ]) {
        expect(event, isA<UIActionEvent>());
      }
    });

    test('parameterized requests carry their fields', () {
      expect(const OpenMapTileDetailEvent(tileKey: 'r1|p1|0|0').tileKey,
          'r1|p1|0|0');
      expect(
        const RequestRegionMapCameraCenterWorldEvent(
          regionId: 'r1',
          worldCenterX: 1.5,
          worldCenterY: 2.5,
        ).worldCenterX,
        1.5,
      );
      expect(
        const RequestRegionMapCameraPanWorldDeltaEvent(
          regionId: 'r1',
          worldDx: 3,
          worldDy: -4,
        ).worldDy,
        -4,
      );
      expect(
        const RequestRegionMapSetZoomMultiplierEvent(
          regionId: 'r1',
          zoomMultiplier: 2,
        ).zoomMultiplier,
        2,
      );
      expect(
        const StartCivilianWorkTargetSelectionEvent(
          unitId: 'u1',
          workTarget: 'build_farm',
        ).workTarget,
        'build_farm',
      );
      expect(const UnitsPanelClosedEvent('naval').panel, 'naval');
      expect(
        StartTargetSelectionEvent(unitId: 'u1', action: 'move').action,
        'move',
      );
      expect(const OpenProvinceDetailPanelEvent('r1|p1').provinceId, 'r1|p1');
      expect(
        const GrantOrSubsidySubmittedEvent(
          targetFactionId: 'B',
          amount: 10,
          isSubsidy: true,
        ).isSubsidy,
        isTrue,
      );
    });

    test('StartTargetSelectionEvent forwards completion and cancel callbacks',
        () {
      String? completed;
      var cancelled = false;
      final event = StartTargetSelectionEvent(
        unitId: 'u1',
        action: 'move',
        onComplete: (p) => completed = p,
        onCancel: () => cancelled = true,
      );
      event.onComplete?.call('r1|p1');
      event.onCancel?.call();
      expect(completed, 'r1|p1');
      expect(cancelled, isTrue);
    });
  });

  group('remaining GameToUIEvent payloads', () {
    test('mirror and required events carry their fields', () {
      expect(const NewGameCreatedEvent(gameId: 'g1').gameId, 'g1');
      expect(const InterventionRequiredEvent(prompts: []).prompts, isEmpty);
      expect(const CallToArmsRequiredEvent(pending: []).pending, isEmpty);
      expect(
        const AppNavalCombatResultEvent(
          seaZoneId: 'sz1',
          side1OwnerId: 'A',
          side2OwnerId: 'B',
          outcomeName: 'decisive',
          turnNumber: 3,
          winnerOwnerId: 'A',
        ).winnerOwnerId,
        'A',
      );
      expect(
        const AppDiplomacyChangeEvent(
          actorId: 'A',
          targetId: 'B',
          changeType: 'war',
          turnNumber: 3,
        ).changeType,
        'war',
      );
      expect(
        const AppResearchCompleteEvent(
          playerId: 'A',
          techId: 'steam',
          turnNumber: 3,
        ).techId,
        'steam',
      );
      expect(
        const AppVictorySetEvent(
          winnerPlayerId: 'A',
          victoryType: 'domination',
          turnNumber: 3,
        ).victoryType,
        'domination',
      );
      expect(
        const AppOrderRejectedEvent(
          playerId: 'A',
          orderSummary: 'move u1',
          reasonCode: 'no_path',
        ).reasonCode,
        'no_path',
      );
      expect(
        const AppWorkOrderCompletedEvent(
          playerId: 'A',
          unitId: 'u1',
          workTarget: 'build_farm',
          targetTileKey: 'r1|p1|0|0',
          provinceId: 'r1|p1',
          turnNumber: 3,
        ).workTarget,
        'build_farm',
      );
      expect(
        const AppPlayerProvinceDiscoveredEvent(
          playerId: 'A',
          provinceId: 'r1|p1',
          turnNumber: 3,
        ).provinceId,
        'r1|p1',
      );
      expect(
        const AppPlayerSeaZoneDiscoveredEvent(
          playerId: 'A',
          seaZoneId: 'sz1',
          turnNumber: 3,
        ).seaZoneId,
        'sz1',
      );
      expect(
        const AppOvertureAdvancedEvent(
          offererGpId: 'gp1',
          targetFactionId: 'mn1',
          newStage: 'embassy',
          turnNumber: 3,
        ).newStage,
        'embassy',
      );
    });
  });
}
