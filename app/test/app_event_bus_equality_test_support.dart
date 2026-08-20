// Event equality pins for AppEventBus tests (Refs #4352).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

void registerAppEventBusEqualityTests() {
  group('UIActionEvent equality', () {
    test('OpenDialogEvent equal for same id and params', () {
      expect(
        const OpenDialogEvent('settings', {'tab': 'audio'}),
        const OpenDialogEvent('settings', {'tab': 'audio'}),
      );
      expect(
        const OpenDialogEvent('settings', {'tab': 'audio'}),
        isNot(const OpenDialogEvent('settings', {'tab': 'video'})),
      );
      expect(
        const OpenDialogEvent('settings'),
        const OpenDialogEvent('settings'),
      );
    });

    test('ConfirmDialogEvent equal for same params', () {
      expect(
        const ConfirmDialogEvent(title: 'a', message: 'b'),
        const ConfirmDialogEvent(title: 'a', message: 'b'),
      );
    });

    test('NavigateToRouteEvent equal for same route and args', () {
      expect(
        const NavigateToRouteEvent('/game', {'key': 'value'}),
        const NavigateToRouteEvent('/game', {'key': 'value'}),
      );
    });

    test('OpenPanelEvent equal for same panelId and params', () {
      expect(
        const OpenPanelEvent('pause_menu', {'a': 1}),
        const OpenPanelEvent('pause_menu', {'a': 1}),
      );
    });

    test('OpenPauseMenuPanelEvent equality', () {
      expect(const OpenPauseMenuPanelEvent(), const OpenPauseMenuPanelEvent());
    });

    test('NavigateToShellEvent equality', () {
      expect(const NavigateToShellEvent(), const NavigateToShellEvent());
    });

    test('CombatModeChosenEvent equality', () {
      expect(
        const CombatModeChosenEvent(CombatMode.quickBattle),
        const CombatModeChosenEvent(CombatMode.quickBattle),
      );
    });

    test('LocateMapTileEvent locates tile only (no panel close on event)', () {
      const e = LocateMapTileEvent(tileKey: 'oldWorld|1,1', regionId: 'oldWorld');
      expect(e.tileKey, 'oldWorld|1,1');
      expect(e.regionId, 'oldWorld');
    });

    test('RequestRegionMapSetZoomMultiplierEvent carries region and multiplier', () {
      const e = RequestRegionMapSetZoomMultiplierEvent(
        regionId: 'oldWorld',
        zoomMultiplier: 2.25,
      );
      expect(e.regionId, 'oldWorld');
      expect(e.zoomMultiplier, 2.25);
    });

    test('StartTargetSelectionEvent equal for same params', () {
      expect(
        const StartTargetSelectionEvent(unitId: 'u1', action: 'move'),
        const StartTargetSelectionEvent(unitId: 'u1', action: 'move'),
      );
    });

    test('GrantOrSubsidySubmittedEvent equal for same params', () {
      expect(
        const GrantOrSubsidySubmittedEvent(
          targetFactionId: 'gp2',
          amount: 500,
          isSubsidy: false,
        ),
        const GrantOrSubsidySubmittedEvent(
          targetFactionId: 'gp2',
          amount: 500,
          isSubsidy: false,
        ),
      );
      expect(
        const GrantOrSubsidySubmittedEvent(
          targetFactionId: 'gp2',
          amount: 500,
          isSubsidy: false,
        ),
        isNot(
          const GrantOrSubsidySubmittedEvent(
            targetFactionId: 'gp2',
            amount: 500,
            isSubsidy: true,
          ),
        ),
      );
    });

    test('NegotiationMoodUpdateEvent equal for same params', () {
      expect(
        const NegotiationMoodUpdateEvent(
          leaderId: 'ai1',
          currentMood: 'considering',
          offerQualityDelta: 0.4,
          stallCounter: 1,
          seed: 7,
        ),
        const NegotiationMoodUpdateEvent(
          leaderId: 'ai1',
          currentMood: 'considering',
          offerQualityDelta: 0.4,
          stallCounter: 1,
          seed: 7,
        ),
      );
      expect(
        const NegotiationMoodUpdateEvent(
          leaderId: 'ai1',
          currentMood: 'considering',
          offerQualityDelta: 0.4,
          stallCounter: 1,
          seed: 7,
        ),
        isNot(
          const NegotiationMoodUpdateEvent(
            leaderId: 'ai1',
            currentMood: 'considering',
            offerQualityDelta: -0.4,
            stallCounter: 1,
            seed: 7,
          ),
        ),
      );
    });
  });

  group('UISystemEvent equality', () {
    test('ShowSnackBarEvent equal for same params', () {
      expect(
        const ShowSnackBarEvent(message: 'saved'),
        const ShowSnackBarEvent(message: 'saved'),
      );
    });

    test('NotifyEvent equal for same params', () {
      expect(
        const NotifyEvent(
          title: 'Research',
          body: 'Complete',
          priority: NotifyPriority.high,
        ),
        const NotifyEvent(
          title: 'Research',
          body: 'Complete',
          priority: NotifyPriority.high,
        ),
      );
    });

    test('ShowOverlayEvent equal for same id and params', () {
      expect(
        const ShowOverlayEvent(overlayId: 'loading', params: {'spin': true}),
        const ShowOverlayEvent(overlayId: 'loading', params: {'spin': true}),
      );
    });
  });

  group('GameToUIEvent equality', () {
    test('TurnResolutionCompleteEvent equal for same fields', () {
      expect(
        const TurnResolutionCompleteEvent(gameId: 'g1', turnNumber: 5),
        const TurnResolutionCompleteEvent(gameId: 'g1', turnNumber: 5),
      );
      expect(
        const TurnResolutionCompleteEvent(gameId: 'g1', turnNumber: 5),
        isNot(const TurnResolutionCompleteEvent(gameId: 'g1', turnNumber: 6)),
      );
    });

    test('SaveGameCompleteEvent equal for same gameId', () {
      expect(
        const SaveGameCompleteEvent(gameId: 'game_123'),
        const SaveGameCompleteEvent(gameId: 'game_123'),
      );
    });

    test('NewGameCreatedEvent equal for same gameId', () {
      expect(
        const NewGameCreatedEvent(gameId: 'game_456'),
        const NewGameCreatedEvent(gameId: 'game_456'),
      );
    });

    test('AppCombatResultEvent equal for same fields', () {
      expect(
        const AppCombatResultEvent(
          provinceId: 'oldWorld|1',
          attackerId: 'gp1',
          defenderId: 'gp2',
          outcomeName: 'attackerVictory',
          winnerId: 'gp1',
          turnNumber: 5,
        ),
        const AppCombatResultEvent(
          provinceId: 'oldWorld|1',
          attackerId: 'gp1',
          defenderId: 'gp2',
          outcomeName: 'attackerVictory',
          winnerId: 'gp1',
          turnNumber: 5,
        ),
      );
      expect(
        const AppCombatResultEvent(
          provinceId: 'oldWorld|1',
          attackerId: 'gp1',
          defenderId: 'gp2',
          outcomeName: 'attackerVictory',
          winnerId: 'gp1',
          turnNumber: 5,
        ),
        isNot(
          const AppCombatResultEvent(
            provinceId: 'oldWorld|2',
            attackerId: 'gp1',
            defenderId: 'gp2',
            outcomeName: 'attackerVictory',
            winnerId: 'gp1',
            turnNumber: 5,
          ),
        ),
      );
    });

    test('AppNavalCombatResultEvent equal for same fields', () {
      expect(
        const AppNavalCombatResultEvent(
          seaZoneId: 's1',
          side1OwnerId: 'gp1',
          side2OwnerId: 'gp2',
          outcomeName: 'draw',
          turnNumber: 2,
          winnerOwnerId: null,
        ),
        const AppNavalCombatResultEvent(
          seaZoneId: 's1',
          side1OwnerId: 'gp1',
          side2OwnerId: 'gp2',
          outcomeName: 'draw',
          turnNumber: 2,
          winnerOwnerId: null,
        ),
      );
      expect(
        const AppNavalCombatResultEvent(
          seaZoneId: 's1',
          side1OwnerId: 'gp1',
          side2OwnerId: 'gp2',
          outcomeName: 'draw',
          turnNumber: 2,
        ),
        isNot(
          const AppNavalCombatResultEvent(
            seaZoneId: 's2',
            side1OwnerId: 'gp1',
            side2OwnerId: 'gp2',
            outcomeName: 'draw',
            turnNumber: 2,
          ),
        ),
      );
    });

    test('AppProvinceCapturedEvent equal for same fields', () {
      expect(
        const AppProvinceCapturedEvent(
          provinceId: 'newWorld|3',
          previousOwnerId: 'gp2',
          newOwnerId: 'gp1',
          turnNumber: 7,
        ),
        const AppProvinceCapturedEvent(
          provinceId: 'newWorld|3',
          previousOwnerId: 'gp2',
          newOwnerId: 'gp1',
          turnNumber: 7,
        ),
      );
      expect(
        const AppProvinceCapturedEvent(
          provinceId: 'newWorld|3',
          previousOwnerId: 'gp2',
          newOwnerId: 'gp1',
          turnNumber: 7,
        ),
        isNot(
          const AppProvinceCapturedEvent(
            provinceId: 'newWorld|3',
            previousOwnerId: 'gp1',
            newOwnerId: 'gp2',
            turnNumber: 7,
          ),
        ),
      );
    });

    test('AppDiplomacyChangeEvent equal for same fields', () {
      expect(
        const AppDiplomacyChangeEvent(
          actorId: 'gp1',
          targetId: 'gp2',
          changeType: 'declare_war',
          turnNumber: 3,
        ),
        const AppDiplomacyChangeEvent(
          actorId: 'gp1',
          targetId: 'gp2',
          changeType: 'declare_war',
          turnNumber: 3,
        ),
      );
    });

    test('AppResearchCompleteEvent equal for same fields', () {
      expect(
        const AppResearchCompleteEvent(
          playerId: 'gp1',
          techId: 'tech_naval',
          turnNumber: 10,
        ),
        const AppResearchCompleteEvent(
          playerId: 'gp1',
          techId: 'tech_naval',
          turnNumber: 10,
        ),
      );
    });

    test('AppVictorySetEvent equal for same fields', () {
      expect(
        const AppVictorySetEvent(
          winnerPlayerId: 'gp1',
          victoryType: 'military',
          turnNumber: 50,
        ),
        const AppVictorySetEvent(
          winnerPlayerId: 'gp1',
          victoryType: 'military',
          turnNumber: 50,
        ),
      );
    });

    test('AppOrderRejectedEvent equal for same fields', () {
      expect(
        const AppOrderRejectedEvent(
          playerId: 'gp1',
          orderKind: OrderKind.work,
          orderSummary: 'Build road',
          reasonCode: 'insufficient_treasury',
        ),
        const AppOrderRejectedEvent(
          playerId: 'gp1',
          orderKind: OrderKind.work,
          orderSummary: 'Build road',
          reasonCode: 'insufficient_treasury',
        ),
      );
    });
  });
}
