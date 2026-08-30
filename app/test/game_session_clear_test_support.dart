// Session-clear Hive/provider fixtures (Refs #4606 Slice D).
// SPEC/program/save-load-session-clear.md.

import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/offline_queue_provider.dart';
import 'package:colonizethis_app/providers/production_allocation_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

GameSetupConfig sessionClearConfig({required int seed}) => GameSetupConfig(
  selectedGreatPowerIds: ['england'],
  continentCount: 1,
  minorNationCount: 0,
  tribeCount: 1,
  numProvincesOldWorld: 3,
  numProvincesNewWorld: 2,
  seed: seed,
);

Orders sessionClearDraftOrders({required String unitType}) => Orders(
  buildUnitOrdersByPlayerId: {
    'england': [
      BuildUnitOrder(
        unitType: unitType,
        isMilitary: false,
        spawnProvinceId: 'oldWorld|p0',
      ),
    ],
  },
);

void dirtySessionA(ProviderContainer container, Game gameA) {
  container.read(currentGameProvider.notifier).setGame(gameA);
  container
      .read(currentOrdersProvider.notifier)
      .replaceAll(sessionClearDraftOrders(unitType: 'farmer'));
  container.read(productionDesiredOutputProvider.notifier).replaceAll(const {
    'grain': 9,
  });
  container
      .read(tribeFirstContactHeraldQueueProvider.notifier)
      .enqueue(
        const TribeFirstContactHeraldPayload(
          tribeId: 'tribe_from_a',
          tribeName: 'From A',
          capitalName: 'A Cap',
        ),
      );
  container.read(pendingDiplomacyProvider.notifier).setOvertures(const [
    OvertureOffer(
      offererGpId: 'england',
      targetFactionId: 'from_a',
      stage: OvertureStage.embassy,
    ),
  ]);
  container
      .read(tribeFirstContactHeraldsShownProvider.notifier)
      .markShown(gameA.id, 'tribe_from_a');
  container.read(gameIdsWithIntroShownProvider.notifier).markShown(gameA.id);
  container.read(offlineQueueProvider.notifier).enqueueAll([Object()]);
}

void expectCleanOfABleed(ProviderContainer container, GameService service) {
  expect(container.read(tribeFirstContactHeraldQueueProvider), isEmpty);
  expect(container.read(pendingDiplomacyProvider), isNull);
  expect(container.read(tribeFirstContactHeraldsShownProvider), isEmpty);
  expect(container.read(gameIdsWithIntroShownProvider), isEmpty);
  expect(container.read(offlineQueueProvider), isEmpty);
  expect(service.turnTraceSessionCount, 0);
}
