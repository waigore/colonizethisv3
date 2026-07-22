import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

Game? applyCombatModeChoiceToGame(Game? currentGame, CombatMode chosenMode) {
  if (currentGame == null) {
    return null;
  }
  if (currentGame.defaultCombatMode == chosenMode) {
    return currentGame;
  }
  return currentGame.copyWith(defaultCombatMode: chosenMode);
}

Orders mergeTrainCivilianOrdersForPlayer({
  required Orders current,
  required Game game,
  required String humanPlayerId,
  required List<BuildUnitOrder> newFromDialog,
}) => _mergeTrainBuildOrdersForPlayer(
  current: current,
  game: game,
  humanPlayerId: humanPlayerId,
  newFromDialog: newFromDialog,
  isDialogManaged: (order, capital, catalogIds) =>
      !order.isMilitary &&
      catalogIds.contains(order.unitType) &&
      capital != null &&
      order.spawnProvinceId == capital,
  catalogIds: CivilianEconomyCatalog.byId.keys.toSet(),
);

Orders mergeTrainMilitaryOrdersForPlayer({
  required Orders current,
  required Game game,
  required String humanPlayerId,
  required List<BuildUnitOrder> newFromDialog,
}) => _mergeTrainBuildOrdersForPlayer(
  current: current,
  game: game,
  humanPlayerId: humanPlayerId,
  newFromDialog: newFromDialog,
  isDialogManaged: (order, capital, catalogIds) =>
      order.isMilitary &&
      catalogIds.contains(order.unitType) &&
      capital != null &&
      order.spawnProvinceId == capital,
  catalogIds: RegimentEconomyCatalog.byId.keys.toSet(),
);

Orders mergeTrainNavalOrdersForPlayer({
  required Orders current,
  required Game game,
  required String humanPlayerId,
  required List<BuildUnitOrder> newFromDialog,
}) => _mergeTrainBuildOrdersForPlayer(
  current: current,
  game: game,
  humanPlayerId: humanPlayerId,
  newFromDialog: newFromDialog,
  isDialogManaged: (order, capital, catalogIds) =>
      !order.isMilitary &&
      catalogIds.contains(order.unitType) &&
      capital != null &&
      order.spawnProvinceId == capital,
  catalogIds: ShipEconomyCatalog.byId.keys.toSet(),
);

Orders _mergeTrainBuildOrdersForPlayer({
  required Orders current,
  required Game game,
  required String humanPlayerId,
  required List<BuildUnitOrder> newFromDialog,
  required bool Function(
    BuildUnitOrder order,
    String? capital,
    Set<String> catalogIds,
  )
  isDialogManaged,
  required Set<String> catalogIds,
}) {
  final capital = game.playerById(humanPlayerId)?.capitalProvinceId;
  final existingList =
      current.buildUnitOrdersByPlayerId[humanPlayerId] ??
      const <BuildUnitOrder>[];
  final kept = <BuildUnitOrder>[];
  for (final order in existingList) {
    if (isDialogManaged(order, capital, catalogIds)) {
      continue;
    }
    kept.add(order);
  }
  return current.copyWith(
    buildUnitOrdersByPlayerId: {
      ...current.buildUnitOrdersByPlayerId,
      humanPlayerId: [...kept, ...newFromDialog],
    },
  );
}

({Game? game, String? message}) applyBreakAllianceImmediately({
  required Game? currentGame,
  required BreakAllianceImmediatelyEvent event,
}) {
  if (currentGame == null) {
    return (game: null, message: 'Break Alliance ignored: no active game.');
  }
  final game = currentGame;
  if (game.worldState.turnState.phase != TurnPhase.orders) {
    return (
      game: null,
      message:
          'Break Alliance rejected: allowed only during human Orders phase.',
    );
  }

  final rel = getRelation(game, event.playerId, event.targetFactionId);
  if (!(rel?.formalAlliance ?? false)) {
    return (
      game: null,
      message: 'Break Alliance rejected: no formal alliance with that faction.',
    );
  }

  final membership = DiplomacyFactionMembership.from(game);
  final turn = game.worldState.turnState.turnNumber;
  final next = applyVoluntaryAllianceBreak(
    game,
    breakerId: event.playerId,
    brokenWithAllyId: event.targetFactionId,
    turn: turn,
    factionMembership: membership,
  );
  if (identical(next, game)) {
    return (
      game: null,
      message: 'Break Alliance rejected: no formal alliance with that faction.',
    );
  }
  return (
    game: next,
    message: 'Alliance with ${event.targetFactionId} broken.',
  );
}
