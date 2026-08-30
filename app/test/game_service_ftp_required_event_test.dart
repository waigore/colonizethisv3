import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/core/services/game_service/game_service_turn_resume.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'app_test_hive_harness.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> box;
  late GameSaveAdapter adapter;

  setUpAll(() async {
    box = await openAppTestHiveBox(suiteId: 'ftp_required_event');
    adapter = GameSaveAdapter();
  });

  test(
    'TurnResolutionPendingFtp emits FtpRequiredEvent on AppEventBus',
    () async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final service = GameService(box, adapter);
      service.eventBus = bus;

      const game = Game(
        id: 'g_ftp_event',
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: [
          Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
        ],
      );

      final received = <AppEvent>[];
      bus.on<FtpRequiredEvent>().listen(received.add);

      gameServiceEmitTurnResolutionEvents(
        service,
        const TurnResolutionPendingFtp(
          game: game,
          pendingFtpOffers: [FtpOffer(proposerGpId: 'gp2', targetGpId: 'gp1')],
        ),
      );

      await pumpEventQueue();
      expect(received, hasLength(1));
      final event = received.first as FtpRequiredEvent;
      expect(event.offers, hasLength(1));
      final offer = event.offers.first as FtpOffer;
      expect(offer.proposerGpId, 'gp2');
    },
  );
}
