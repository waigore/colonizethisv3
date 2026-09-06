import 'dart:io';

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'app_test_hive_harness.dart';
import 'game_service_event_emission_fixtures.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> box;
  late GameSaveAdapter adapter;
  Directory? hiveDir;

  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('ct_game_service_test_');
    hiveDir = dir;
    box = await openAppTestHiveBox(suiteId: 'game_service', directory: dir);
    adapter = GameSaveAdapter();
  });

  tearDownAll(() async {
    await box.clear();
    await box.close();
    final dir = hiveDir;
    if (dir != null && dir.existsSync()) {
      try {
        await dir.delete(recursive: true);
      } on Object {
        // Best-effort temp cleanup.
      }
    }
  });

  group('GameService event emission', () {
    test(
      'AppEventBus emits OvertureRequiredEvent synchronously and listener receives it',
      () async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        final received = <AppEvent>[];
        bus.on<OvertureRequiredEvent>().listen(received.add);

        bus.emit(
          OvertureRequiredEvent(
            overtures: [
              OvertureOffer(
                offererGpId: 'gp2',
                targetFactionId: 'gp1',
                stage: OvertureStage.tradeConsulate,
              ),
            ],
          ),
        );

        await pumpEventQueue();
        expect(received, hasLength(1));
      },
    );

    test(
      'runTurnResolution returns TurnResolutionPendingOvertures and emits OvertureRequiredEvent',
      () async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        final service = PendingOverturesGameService(box, adapter);
        service.eventBus = bus;

        final game = Game(
          id: 'g_overture_test',
          worldState: const WorldState(
            turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(),
            newWorld: RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
          ],
        );

        final received = <AppEvent>[];
        bus.on<OvertureRequiredEvent>().listen(received.add);

        final result = service.runTurnResolution(game);

        await pumpEventQueue();
        expect(result, isA<TurnResolutionPendingOvertures>());
        expect(received, hasLength(1));
        final event = received.first as OvertureRequiredEvent;
        expect(event.overtures, hasLength(1));
        final offer = event.overtures.first as OvertureOffer;
        expect(offer.offererGpId, 'gp2');
        expect(offer.stage, OvertureStage.tradeConsulate);
      },
    );

    test(
      'runTurnResolution with null eventBus does not throw when result is pending',
      () {
        final service = PendingOverturesGameService(box, adapter);
        service.eventBus = null;

        final game = Game(
          id: 'g_null_bus_test',
          worldState: const WorldState(
            turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(),
            newWorld: RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
          ],
        );

        expect(() => service.runTurnResolution(game), returnsNormally);
      },
    );
  });
}
