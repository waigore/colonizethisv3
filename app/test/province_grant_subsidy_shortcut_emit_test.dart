// Pins MAP20001 Political Grant Aid / Set Subsidy dialog/remove (Refs #4761).

import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart'
    show grantOrSubsidyDialogId;
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_shortcuts.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'province_detail_overlay_host_support_fixtures.dart';
import 'province_grant_subsidy_shortcut_fixtures.dart';

void main() {
  suppressLogsForTests();

  ProvinceDetailShortcutCallbacks callbacksFor({
    required Game game,
    required AppEventBus bus,
    bool grantPending = false,
    bool subsidyPending = false,
  }) => provinceDetailCallbacks(
    game: game,
    selectedTileKey: kGrantSubsidyTileKey,
    exploreEnabled: false,
    prospectEnabled: false,
    buildImprovementEnabled: false,
    buildRoadEnabled: false,
    buildFortEnabled: false,
    buildPortEnabled: false,
    purchaseLandEnabled: false,
    provinceId: kGrantSubsidyProvinceId,
    grantAidEnabled: true,
    grantAidPending: grantPending,
    grantAidOwnerId: kGrantSubsidyMinorId,
    setSubsidyEnabled: true,
    setSubsidyPending: subsidyPending,
    setSubsidyOwnerId: kGrantSubsidyMinorId,
    combinedTopology: kGrantSubsidyTopology,
    bus: bus,
  );

  test('Grant Aid tap emits OpenDialogEvent without append', () async {
    final game = buildGrantSubsidyShortcutGame(ownerId: kGrantSubsidyMinorId);
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);
    final dialogFuture = bus.on<OpenDialogEvent>().first.timeout(
      const Duration(seconds: 2),
    );
    final appends = <AppendDiplomaticOrderRequestedEvent>[];
    final sub = bus.on<AppendDiplomaticOrderRequestedEvent>().listen(
      appends.add,
    );
    addTearDown(sub.cancel);
    final callbacks = callbacksFor(game: game, bus: bus);
    expect(callbacks.onGrantAidTap, isNotNull);
    callbacks.onGrantAidTap!();
    final event = await dialogFuture;
    expect(event.dialogId, grantOrSubsidyDialogId);
    expect(event.params?['targetFactionId'], kGrantSubsidyMinorId);
    expect(event.params?['isSubsidy'], isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(appends, isEmpty);
  });

  test('Set Subsidy tap emits OpenDialogEvent with isSubsidy true', () async {
    final game = buildGrantSubsidyShortcutGame(ownerId: kGrantSubsidyMinorId);
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);
    final dialogFuture = bus.on<OpenDialogEvent>().first.timeout(
      const Duration(seconds: 2),
    );
    final callbacks = callbacksFor(game: game, bus: bus);
    callbacks.onSetSubsidyTap!();
    final event = await dialogFuture;
    expect(event.dialogId, grantOrSubsidyDialogId);
    expect(event.params?['isSubsidy'], isTrue);
  });

  test('pending Grant Aid tap removes only that order', () async {
    final game = buildGrantSubsidyShortcutGame(ownerId: kGrantSubsidyMinorId);
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);
    final removeFuture = bus
        .on<RemoveDiplomaticOrderRequestedEvent>()
        .first
        .timeout(const Duration(seconds: 2));
    final callbacks = callbacksFor(game: game, bus: bus, grantPending: true);
    callbacks.onGrantAidTap!();
    final remove = await removeFuture;
    expect(remove.targetFactionId, kGrantSubsidyMinorId);
    expect(remove.type, DiplomaticOrderType.grantAid);
  });

  test('pending Set Subsidy tap removes only that order', () async {
    final game = buildGrantSubsidyShortcutGame(ownerId: kGrantSubsidyMinorId);
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);
    final removeFuture = bus
        .on<RemoveDiplomaticOrderRequestedEvent>()
        .first
        .timeout(const Duration(seconds: 2));
    final callbacks = callbacksFor(game: game, bus: bus, subsidyPending: true);
    callbacks.onSetSubsidyTap!();
    final remove = await removeFuture;
    expect(remove.targetFactionId, kGrantSubsidyMinorId);
    expect(remove.type, DiplomaticOrderType.setSubsidy);
  });
}
