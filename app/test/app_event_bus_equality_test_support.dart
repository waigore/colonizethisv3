// Event equality pins for AppEventBus tests (Refs #4352).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_event_bus_equality_game_to_ui.dart';

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
      const e = LocateMapTileEvent(
        tileKey: 'oldWorld|1,1',
        regionId: 'oldWorld',
      );
      expect(e.tileKey, 'oldWorld|1,1');
      expect(e.regionId, 'oldWorld');
    });

    test(
      'RequestRegionMapSetZoomMultiplierEvent carries region and multiplier',
      () {
        const e = RequestRegionMapSetZoomMultiplierEvent(
          regionId: 'oldWorld',
          zoomMultiplier: 2.25,
        );
        expect(e.regionId, 'oldWorld');
        expect(e.zoomMultiplier, 2.25);
      },
    );

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
  registerAppEventBusGameToUiEqualityTests();
}
