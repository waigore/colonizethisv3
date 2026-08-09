import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
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
      expect(
        const OpenMapTileDetailEvent(tileKey: 'r1|p1|0|0').tileKey,
        'r1|p1|0|0',
      );
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

    test(
      'StartTargetSelectionEvent forwards completion and cancel callbacks',
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
      },
    );
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
          orderKind: OrderKind.move,
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
      expect(
        const AppOverseasProfitCreditedEvent(
          playerId: 'gp1',
          totalTreasuryCredit: 75,
          creditCount: 2,
          turnNumber: 3,
        ).totalTreasuryCredit,
        75,
      );
      expect(
        const AppMarketTurnSummaryEvent(
          playerId: 'gp1',
          totalSpent: 240,
          totalReceived: 160,
          carryForwardOrderCount: 2,
          turnNumber: 3,
        ).carryForwardOrderCount,
        2,
      );
    });
  });
}
