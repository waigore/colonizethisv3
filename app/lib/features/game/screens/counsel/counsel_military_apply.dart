// Military Counsel Agree apply handlers. SPEC/ui/counsel-panel.md (Refs #4307).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart'
    show
        MilitaryCounselRecommendation,
        MilitaryCounselRecommendationKind,
        militaryCounselGreedyAffordableBuildCount;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show
        ArmyMovePickerDestination,
        IncrementalCandidateValidator,
        applyArmyMoveOrderForPlayer,
        armyMovePickerDestinations,
        armyMovePlayerOwnedProvinceIds,
        ordersWithAppendedDiplomaticOrder,
        suggestBuildOrders;
import 'package:colonizethis_world/colonizethis_world.dart';

/// Whether [unitType] can still be raised [count] times given economy and orders.
bool militaryCounselTrainStillAffordable({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
  required String unitType,
  required int count,
}) {
  final affordable = militaryCounselAffordableBuildCountForType(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
    topology: topology,
    unitType: unitType,
  );
  return affordable >= count;
}

/// Recomputes greedy affordable count for [unitType] against current draft.
int militaryCounselAffordableBuildCountForType({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
  required String unitType,
}) {
  final player = game.playerById(playerId);
  if (player == null) return 0;
  final capitalId = player.capitalProvinceId;
  if (capitalId == null) return 0;

  final view = buildPlayerView(game, topology, playerId);
  final suggestions = suggestBuildOrders(view, game, topology, currentOrders);
  if (!suggestions.any((order) => order.unitType == unitType)) return 0;

  final category = buildUnitCategoryForUnitType(unitType);
  final isMilitary = category == BuildUnitCategory.military;
  final template = BuildUnitOrder(
    unitType: unitType,
    isMilitary: isMilitary,
    spawnProvinceId: capitalId,
  );
  return militaryCounselGreedyAffordableBuildCount(
    player: player,
    template: template,
    currentOrders: currentOrders,
  );
}

/// Appends [count] build orders for [unitType] when still affordable; else null.
Orders? militaryCounselOrdersAfterTrainAgree({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
  required String unitType,
  required int count,
}) {
  if (count <= 0) return null;
  if (!militaryCounselTrainStillAffordable(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
    topology: topology,
    unitType: unitType,
    count: count,
  )) {
    return null;
  }

  final player = game.playerById(playerId);
  final capitalId = player?.capitalProvinceId;
  if (player == null || capitalId == null) return null;

  final category = buildUnitCategoryForUnitType(unitType);
  final isMilitary = category == BuildUnitCategory.military;
  final existing =
      currentOrders.buildUnitOrdersByPlayerId[playerId] ??
      const <BuildUnitOrder>[];
  final appended = <BuildUnitOrder>[
    for (var i = 0; i < count; i++)
      BuildUnitOrder(
        unitType: unitType,
        isMilitary: isMilitary,
        spawnProvinceId: capitalId,
      ),
  ];
  return currentOrders.copyWith(
    buildUnitOrdersByPlayerId: {
      ...currentOrders.buildUnitOrdersByPlayerId,
      playerId: [...existing, ...appended],
    },
  );
}

/// Resolves a still-valid invasion destination for [recommendation], if any.
ArmyMovePickerDestination? militaryCounselInvadeDestinationForRecommendation({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
  required MilitaryCounselRecommendation recommendation,
}) {
  if (recommendation.kind != MilitaryCounselRecommendationKind.invade) {
    return null;
  }
  final armyId = recommendation.armyId;
  final destinationId = recommendation.destinationProvinceId;
  if (armyId == null || destinationId == null) return null;

  Army? army;
  for (final candidate in game.worldState.armies) {
    if (candidate.id == armyId) {
      army = candidate;
      break;
    }
  }
  if (army == null || army.ownerId != playerId || army.isHomeArmy) {
    return null;
  }

  final view = buildPlayerView(game, topology, playerId);
  final sharedValidator = IncrementalCandidateValidator.forPlayer(
    game: game,
    topology: topology,
    playerId: playerId,
    basePrefix: currentOrders,
  );
  final destinations = armyMovePickerDestinations(
    game: game,
    topology: topology,
    playerId: playerId,
    army: army,
    currentOrders: currentOrders,
    playerOwnedFullProvinceIds: armyMovePlayerOwnedProvinceIds(
      game: game,
      playerId: playerId,
      view: view,
    ),
    sharedCandidateValidator: sharedValidator,
  );
  for (final entry in destinations) {
    if (entry.fullProvinceId == destinationId && !entry.isPlayerOwned) {
      return entry;
    }
  }
  return null;
}

/// Stages army move and optional declare-war for a validated invasion destination.
Orders militaryCounselOrdersAfterInvadeAgree({
  required Orders currentOrders,
  required String playerId,
  required String armyId,
  required ArmyMovePickerDestination destination,
}) {
  var next = currentOrders;
  final warTarget = destination.requiresDeclareWarOnConfirm
      ? destination.ownerFactionId
      : null;
  if (warTarget != null) {
    final diploList =
        next.diplomaticOrdersByPlayerId[playerId] ?? const <DiplomaticOrder>[];
    final hasDeclare = diploList.any(
      (d) =>
          d.type == DiplomaticOrderType.declareWar &&
          d.targetFactionId == warTarget,
    );
    if (!hasDeclare) {
      next = ordersWithAppendedDiplomaticOrder(
        next,
        playerId,
        DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: warTarget,
        ),
      );
    }
  }
  return applyArmyMoveOrderForPlayer(
    next,
    playerId,
    ArmyMoveOrder(
      armyId: armyId,
      destinationProvinceId: destination.fullProvinceId,
    ),
  );
}
