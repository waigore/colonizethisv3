// AppEventHandler combat-dialog routing pins (Refs #4352).
// SPEC: SPEC/program/app-event-bus.md.

import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler.dart';
import 'package:colonizethis_app/features/game/widgets/combat/combat_mode_choice_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/combat/quick_battle_result_dialog.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_event_handler_test_support.dart';

void main() {
  suppressLogsForTests();

  group('AppEventHandler combat dialogs', () {
    late AppEventBus bus;
    late GlobalKey<NavigatorState> navKey;
    late AppEventHandler handler;

    setUp(() {
      AppEventBus.reset();
      bus = AppEventBus.create();
      navKey = GlobalKey<NavigatorState>();
      handler = buildTestAppEventHandler(bus: bus, navigatorKey: navKey);
    });

    tearDown(() {
      handler.unbind();
      AppEventBus.reset();
    });

    testWidgets(
      'CombatModeChoiceDialog opened via OpenDialog emits CombatModeChosenEvent',
      (tester) async {
        handler = AppEventHandler(
          bus: bus,
          navigatorKey: navKey,
          dialogBuilders: {
            'combat_mode_choice': (ctx, params) => CombatModeChoiceDialog(
              bus: bus,
              provinceName: params?['provinceName'] as String? ?? '',
              isCapitalSiege: params?['isCapitalSiege'] as bool? ?? false,
            ),
          },
        );
        handler.bind();
        CombatModeChosenEvent? chosen;
        bus.on<CombatModeChosenEvent>().listen((e) => chosen = e);
        await pumpAppEventHandlerEmitButton(
          tester,
          navigatorKey: navKey,
          label: 'open',
          onPressed: () => bus.emit(
            const OpenDialogEvent('combat_mode_choice', {
              'provinceName': 'TestProv',
              'isCapitalSiege': false,
            }),
          ),
        );
        await tapAppEventHandlerLabel(tester, 'open');
        await tapAppEventHandlerLabel(tester, 'Quick Battle');
        expect(chosen?.mode, CombatMode.quickBattle);
        expect(find.text('Combat at TestProv'), findsNothing);
      },
    );

    testWidgets('OpenDialogEvent quick_battle_result shows dialog', (
      tester,
    ) async {
      handler = AppEventHandler(
        bus: bus,
        navigatorKey: navKey,
        dialogBuilders: {
          'quick_battle_result': (ctx, params) => QuickBattleResultDialog(
            result: params!['result'] as QuickBattleResult,
            attackerName: 'A',
            defenderName: 'D',
          ),
        },
      );
      handler.bind();
      final qb = QuickBattleResult(
        winner: QuickBattleWinner.attacker,
        attackerCasualties: const [],
        defenderCasualties: const [],
        provinceFlips: false,
      );
      await pumpAppEventHandlerEmitButton(
        tester,
        navigatorKey: navKey,
        label: 'open',
        onPressed: () =>
            bus.emit(OpenDialogEvent('quick_battle_result', {'result': qb})),
      );
      await tapAppEventHandlerLabel(tester, 'open');
      expect(find.textContaining('Battle Result'), findsOneWidget);
      expect(find.textContaining('A wins'), findsOneWidget);
    });
  });
}
