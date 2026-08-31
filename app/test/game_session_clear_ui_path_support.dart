// Fake GameService and session fixtures for session-clear UI path tests (Refs #3989, #4305).

import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
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
