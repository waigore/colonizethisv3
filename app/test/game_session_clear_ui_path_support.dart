// Fake GameService and session fixtures for session-clear UI path tests (Refs #3989, #4305).

import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/offline_queue_provider.dart';
import 'package:colonizethis_app/providers/production_allocation_provider.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

class UiPathGameService extends GameService {
  UiPathGameService(super.box, super.adapter);

  GameSaveSession? sessionToLoad;
  List<LoadableSaveEntry> entries = const [];
  bool autoSaveValid = false;

  @override
  List<LoadableSaveEntry> listLoadableSaves() => entries;

  @override
  bool hasValidAutoSave() => autoSaveValid;

  @override
  GameSaveSession? loadGameSession(String gameId) =>
      sessionToLoad != null && sessionToLoad!.game.id == gameId
      ? sessionToLoad
      : null;

  @override
  GameSaveSession? loadAutoSaveSession() =>
      autoSaveValid ? sessionToLoad : null;
}

Orders uiPathDraftOrders({required String unitType}) => Orders(
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

GameSaveSession uiPathSessionB({
  required String id,
  required String unitType,
  required Map<String, int> desired,
}) {
  return GameSaveSession(
    game: Game(
      id: id,
      worldState: const WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 3),
        oldWorld: RegionData(),
        newWorld: RegionData(),
      ),
      players: const [
        Player(id: 'england', displayName: 'England', isHuman: true),
      ],
    ),
    draftOrders: uiPathDraftOrders(unitType: unitType),
    productionDesiredOutputByRecipe: desired,
    displayName: 'Save $id',
  );
}

Future<void> uiPathPumpFrames(WidgetTester tester, {int count = 8}) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void uiPathDirtySessionA(ProviderContainer container) {
  final gameA = Game(
    id: 'save_a',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: const [
      Player(id: 'england', displayName: 'England', isHuman: true),
    ],
  );
  container.read(currentGameProvider.notifier).setGame(gameA);
  container
      .read(currentOrdersProvider.notifier)
      .replaceAll(uiPathDraftOrders(unitType: 'farmer'));
  container
      .read(productionDesiredOutputProvider.notifier)
      .replaceAll(const {'grain': 9});
  container.read(tribeFirstContactHeraldQueueProvider.notifier).enqueue(
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

void uiPathExpectSessionBProviders(
  ProviderContainer container, {
  required String gameId,
  required String unitType,
  required Map<String, int> desired,
}) {
  expect(container.read(currentGameProvider)?.id, gameId);
  expect(
    container
        .read(currentOrdersProvider)
        .buildUnitOrdersByPlayerId['england']!
        .single
        .unitType,
    unitType,
  );
  expect(container.read(productionDesiredOutputProvider), desired);
  expect(container.read(tribeFirstContactHeraldQueueProvider), isEmpty);
  expect(container.read(pendingDiplomacyProvider), isNull);
  expect(container.read(tribeFirstContactHeraldsShownProvider), isEmpty);
  expect(container.read(gameIdsWithIntroShownProvider), isEmpty);
  expect(container.read(offlineQueueProvider), isEmpty);
}
