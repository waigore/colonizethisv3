// Pins MAP20001 Political Establish Embassy confirm/append/remove (Refs #4739).

import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_shortcuts.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'province_detail_overlay_host_support_fixtures.dart';
import 'province_establish_embassy_shortcut_fixtures.dart';

void main() {
  suppressLogsForTests();

  DiplomaticOrder embassyOrder() => const DiplomaticOrder(
    type: DiplomaticOrderType.establishOverture,
    targetFactionId: kEstablishEmbassyMinorId,
    overtureStage: OvertureStage.embassy,
  );

  ProvinceDetailShortcutCallbacks callbacksFor({
    required Game game,
    required AppEventBus bus,
    required bool pending,
  }) => provinceDetailCallbacks(
    game: game,
    selectedTileKey: kEstablishEmbassyTileKey,
    exploreEnabled: false,
    prospectEnabled: false,
    buildImprovementEnabled: false,
    buildRoadEnabled: false,
    buildFortEnabled: false,
    buildPortEnabled: false,
    purchaseLandEnabled: false,
    provinceId: kEstablishEmbassyProvinceId,
    establishEmbassyEnabled: true,
    establishEmbassyPending: pending,
    establishEmbassyOrder: embassyOrder(),
    establishEmbassyTargetName: 'Minor One',
    combinedTopology: kEstablishEmbassyTopology,
    bus: bus,
  );

  test('enabled tap emits Confirm then Append on confirm', () async {
    final game = buildEstablishEmbassyShortcutGame(
      ownerId: kEstablishEmbassyMinorId,
    );
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);
    final confirmFuture = bus.on<ConfirmDialogEvent>().first.timeout(
      const Duration(seconds: 2),
    );
    final appendFuture = bus
        .on<AppendDiplomaticOrderRequestedEvent>()
        .first
        .timeout(const Duration(seconds: 2));
    final callbacks = callbacksFor(game: game, bus: bus, pending: false);
    expect(callbacks.onEstablishEmbassyTap, isNotNull);
    callbacks.onEstablishEmbassyTap!();
    final confirm = await confirmFuture;
    confirm.result(true);
    final append = await appendFuture;
    expect(append.order.targetFactionId, kEstablishEmbassyMinorId);
    expect(append.order.overtureStage, OvertureStage.embassy);
  });

  test('pending tap emits RemoveDiplomaticOrderRequestedEvent', () async {
    final game = buildEstablishEmbassyShortcutGame(
      ownerId: kEstablishEmbassyMinorId,
    );
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);
    final removeFuture = bus
        .on<RemoveDiplomaticOrderRequestedEvent>()
        .first
        .timeout(const Duration(seconds: 2));
    final callbacks = callbacksFor(game: game, bus: bus, pending: true);
    expect(callbacks.onEstablishEmbassyTap, isNotNull);
    callbacks.onEstablishEmbassyTap!();
    final remove = await removeFuture;
    expect(remove.targetFactionId, kEstablishEmbassyMinorId);
    expect(remove.type, DiplomaticOrderType.establishOverture);
  });

  test('dismissed confirm appends nothing', () async {
    final game = buildEstablishEmbassyShortcutGame(
      ownerId: kEstablishEmbassyMinorId,
    );
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);
    final appends = <AppendDiplomaticOrderRequestedEvent>[];
    final sub = bus.on<AppendDiplomaticOrderRequestedEvent>().listen(
      appends.add,
    );
    addTearDown(sub.cancel);
    final confirmFuture = bus.on<ConfirmDialogEvent>().first.timeout(
      const Duration(seconds: 2),
    );
    final callbacks = callbacksFor(game: game, bus: bus, pending: false);
    callbacks.onEstablishEmbassyTap!();
    final confirm = await confirmFuture;
    confirm.result(false);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(appends, isEmpty);
  });
}
