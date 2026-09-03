import 'package:colonizethis_app/features/game/flame/caches/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_app/features/game/flame/overlays/game_map_narrow_detail_overlay.dart';
import 'package:colonizethis_app/features/game/flame/overlays/game_map_province_detail_side_panel.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_logic/ai_api.dart' show buildPlayerView;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'province_establish_consulate_shortcut_host_emit_support.dart';
import 'app_test_hive_harness.dart';

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'province_consulate_shortcut');
  });

  Future<AppEventBus> pumpHost(
    WidgetTester tester, {
    required ConsulateShortcutHostCase host,
    required Game game,
    Orders orders = const Orders(),
  }) async {
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);
    final view = buildPlayerView(
      game,
      consulateShortcutTopology,
      kConsulateShortcutHumanId,
    );
    final body = host.wide
        ? Center(
            child: SizedBox(
              width: 320,
              child: GameMapProvinceDetailSidePanel(
                game: game,
                region: consulateShortcutRegion(),
                humanPlayerId: kConsulateShortcutHumanId,
                playerView: view,
                workTargetSelectionCache: PerPlayerWorkTargetSelectionCache(),
              ),
            ),
          )
        : Align(
            alignment: Alignment.bottomCenter,
            child: GameMapNarrowDetailOverlaySlot(
              game: game,
              region: consulateShortcutRegion(),
              humanPlayerId: kConsulateShortcutHumanId,
              playerView: view,
              workTargetSelectionCache: PerPlayerWorkTargetSelectionCache(),
            ),
          );
    await pumpAppShell(
      tester,
      viewport: host.size,
      overrides: [
        gamesBoxProvider.overrideWith((ref) => gamesBox),
        gameServiceProvider.overrideWith(
          (ref) => ConsulateShortcutGameService(gamesBox, GameSaveAdapter()),
        ),
        appEventBusProvider.overrideWith((ref) => bus),
        currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
        currentOrdersProvider.overrideWith(() => CurrentOrdersNotifier(orders)),
      ],
      child: Scaffold(body: body),
    );
    final context = tester.element(find.byType(host.type));
    ProviderScope.containerOf(context)
        .read(mapProvincePanelProvider.notifier)
        .reportMapTileTapped(kConsulateShortcutTileKey);
    await tester.pumpAndSettle();
    return bus;
  }

  Finder action(String label) => find.byWidgetPredicate(
    (widget) => widget is CtActionTextButton && widget.label == label,
  );

  for (final host in kConsulateShortcutHosts) {
    testWidgets(
      '${host.wide ? 'wide' : 'narrow'} host emits confirm then appends Consulate',
      (tester) async {
        final bus = await pumpHost(
          tester,
          host: host,
          game: consulateShortcutGame(),
        );
        final confirmFuture = bus.on<ConfirmDialogEvent>().first.timeout(
          const Duration(seconds: 2),
        );
        final appendFuture = bus
            .on<AppendDiplomaticOrderRequestedEvent>()
            .first
            .timeout(const Duration(seconds: 2));

        final establish = action(l10n.provinceOverlay_establishConsulateAction);
        await tester.ensureVisible(establish);
        await tester.tap(establish);
        await tester.pump();
        final confirm = await confirmFuture;
        expect(confirm.message, contains('Cost:'));
        expect(confirm.message, contains('Effect:'));

        confirm.result(true);
        final append = await appendFuture;
        expect(append.playerId, kConsulateShortcutHumanId);
        expect(append.order.type, DiplomaticOrderType.establishOverture);
        expect(append.order.overtureStage, OvertureStage.tradeConsulate);
        expect(append.order.targetFactionId, kConsulateShortcutMinorId);
        expect(find.byType(host.type), findsOneWidget);
      },
    );
  }

  testWidgets('dismissing Consulate confirm appends nothing', (tester) async {
    final bus = await pumpHost(
      tester,
      host: kConsulateShortcutHosts.first,
      game: consulateShortcutGame(),
    );
    final confirms = <ConfirmDialogEvent>[];
    final appends = <AppendDiplomaticOrderRequestedEvent>[];
    final confirmSub = bus.on<ConfirmDialogEvent>().listen(confirms.add);
    final appendSub = bus.on<AppendDiplomaticOrderRequestedEvent>().listen(
      appends.add,
    );
    addTearDown(confirmSub.cancel);
    addTearDown(appendSub.cancel);

    await tester.tap(action(l10n.provinceOverlay_establishConsulateAction));
    await tester.pump();
    confirms.single.result(false);
    await tester.pump();
    expect(appends, isEmpty);
  });

  testWidgets('pending control emits remove without confirm', (tester) async {
    final bus = await pumpHost(
      tester,
      host: kConsulateShortcutHosts.first,
      game: consulateShortcutGame(),
      orders: consulateShortcutPending(),
    );
    final removes = <RemoveDiplomaticOrderRequestedEvent>[];
    final confirms = <ConfirmDialogEvent>[];
    final removeSub = bus.on<RemoveDiplomaticOrderRequestedEvent>().listen(
      removes.add,
    );
    final confirmSub = bus.on<ConfirmDialogEvent>().listen(confirms.add);
    addTearDown(removeSub.cancel);
    addTearDown(confirmSub.cancel);

    await tester.tap(
      action(l10n.provinceOverlay_cancelEstablishConsulateAction),
    );
    await tester.pump();
    expect(confirms, isEmpty);
    expect(removes, hasLength(1));
    expect(removes.single.playerId, kConsulateShortcutHumanId);
    expect(removes.single.type, DiplomaticOrderType.establishOverture);
    expect(removes.single.targetFactionId, kConsulateShortcutMinorId);
  });

  testWidgets(
    'disabled host control shows validator reason and emits nothing',
    (tester) async {
      final bus = await pumpHost(
        tester,
        host: kConsulateShortcutHosts.first,
        game: consulateShortcutGame(expertise: false),
      );
      final confirms = <ConfirmDialogEvent>[];
      final sub = bus.on<ConfirmDialogEvent>().listen(confirms.add);
      addTearDown(sub.cancel);
      final button = tester.widget<CtActionTextButton>(
        action(l10n.provinceOverlay_establishConsulateAction),
      );
      expect(button.enabled, isFalse);
      expect(button.tooltip, contains('Diplomatic Expertise'));
      expect(button.semanticLabel, contains('Diplomatic Expertise'));
      expect(confirms, isEmpty);
    },
  );
}
