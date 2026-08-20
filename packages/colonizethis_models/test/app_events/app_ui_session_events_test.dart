import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/session_command_event_cases.dart';

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
        spyOnly: true,
        relocateShortcutTargetTileKey: 'r1|p1|2|2',
        counterSpyShortcutTargetTileKey: 'r1|p1|0|0',
      );
      expect(civilians.tileScopeTileKey, 'r1|p1|1|1');
      expect(civilians.explorerOnly, isTrue);
      expect(civilians.builderOnly, isFalse);
      expect(civilians.spyOnly, isTrue);
      expect(civilians.relocateShortcutTargetTileKey, 'r1|p1|2|2');
      expect(civilians.counterSpyShortcutTargetTileKey, 'r1|p1|0|0');
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

    test(
      'DevelopmentDisconnectedAssignDialogEvent invokes its result callback',
      () {
        DevelopmentDisconnectedAssignChoice? answer;
        final event = DevelopmentDisconnectedAssignDialogEvent(
          roadFirstEnabled: true,
          onResult: (v) => answer = v,
        );
        expect(event.roadFirstEnabled, isTrue);
        event.result(DevelopmentDisconnectedAssignChoice.roadFirst);
        expect(answer, DevelopmentDisconnectedAssignChoice.roadFirst);
      },
    );

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
        outcomeName: 'attackerVictory',
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
      expect(
        FlipDebugProvinceOwnershipEvent(
          humanPlayerId: 'p1',
          fullProvinceId: 'r1|p1',
        ).fullProvinceId,
        'r1|p1',
      );
    });

    test('remaining session command payloads carry fields', () {
      expectSessionCommandPayloadCases();
    });
  });
}
