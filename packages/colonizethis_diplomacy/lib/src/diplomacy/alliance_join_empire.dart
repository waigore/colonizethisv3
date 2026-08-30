import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'diplomacy_event_logging.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_shared_helpers.dart';
import 'faction_absorption_engine.dart';

/// Target GP is nearly defeated for Join Empire when it has at most three
/// provinces and does not own its original capital province.
bool isGreatPowerNearlyDefeatedForJoinEmpire(
  Game game,
  String gpId, {
  DiplomacyFactionMembership? factionMembership,
}) {
  final isGp =
      factionMembership?.isGreatPower(gpId) ?? isGreatPower(game, gpId);
  if (!isGp) return false;
  final capId = game.playerById(gpId)?.capitalProvinceId;
  if (capId == null) return false;
  final capProv = game.worldState.tryGetProvince(capId);
  if (capProv == null || capProv.ownerId == gpId) return false;
  return provinceCountOwnedBy(game, gpId) <= 3;
}

Game resolveJoinEmpireColony(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn, {
  IntraTurnEventTally? eventTally,
}) {
  var factionMembership = DiplomacyFactionMembership.from(game);
  for (final entry in diploByPlayer.entries) {
    for (final order in entry.value) {
      final previous = game;
      game = _resolveJoinEmpireOrderIfApplicable(
        game,
        entry.key,
        order,
        turn,
        factionMembership,
        eventTally: eventTally,
      );
      if (!identical(game, previous)) {
        factionMembership = DiplomacyFactionMembership.from(game);
      }
    }
  }
  return game;
}

Game _resolveJoinEmpireOrderIfApplicable(
  Game game,
  String gpId,
  DiplomaticOrder order,
  int turn,
  DiplomacyFactionMembership factionMembership, {
  IntraTurnEventTally? eventTally,
}) {
  if (order.type != DiplomaticOrderType.establishOverture ||
      order.overtureStage != OvertureStage.joinEmpire) {
    return game;
  }
  final targetId = order.targetFactionId;
  final player = game.playerById(gpId);
  if (player == null ||
      getOverture(game, gpId, targetId)?.stage != OvertureStage.nap) {
    return game;
  }
  if ((getRelation(game, gpId, targetId)?.score ?? relationScoreNeutral) <
      relationScoreMinFriendly) {
    return game;
  }
  if (factionMembership.isMinorOrTribe(targetId)) {
    return _resolveJoinEmpireMinorOrTribe(
      game,
      gpId,
      targetId,
      player,
      turn,
      eventTally: eventTally,
    );
  }
  if (!factionMembership.isGreatPower(targetId)) return game;
  return _resolveJoinEmpireGreatPower(
    game,
    gpId,
    targetId,
    player,
    turn,
    factionMembership,
    eventTally: eventTally,
  );
}

Game _resolveJoinEmpireMinorOrTribe(
  Game game,
  String gpId,
  String targetId,
  Player player,
  int turn, {
  IntraTurnEventTally? eventTally,
}) {
  final cost = joinEmpireCostForMinorOrTribe(game, targetId);
  if (player.treasury < cost) return game;
  final isTribe = game.tribes.any((tribe) => tribe.id == targetId);
  var next = isTribe
      ? markTribeAsColony(game, gpId, targetId, turn)
      : absorbMinorOrTribeIntoGp(game, gpId, targetId, turn);
  return logDiplomaticEvent(
    next,
    turn,
    DiplomaticEventType.joinEmpireResolved,
    {gpId, targetId},
    fromFactionId: gpId,
    toFactionId: targetId,
    overtureStage: OvertureStage.joinEmpire,
    amount: cost,
    wasAiInitiator: isAiControlledForEvidence(next, gpId),
    eventTally: eventTally,
    logMessage: isTribe
        ? 'diplomacy join empire (colony) $gpId $targetId cost=$cost'
        : 'diplomacy join empire $gpId $targetId cost=$cost',
  );
}

Game _resolveJoinEmpireGreatPower(
  Game game,
  String gpId,
  String targetId,
  Player player,
  int turn,
  DiplomacyFactionMembership factionMembership, {
  IntraTurnEventTally? eventTally,
}) {
  if (player.techUnlocked?[kTechIdEmpireBuilding] != true ||
      !isGreatPowerNearlyDefeatedForJoinEmpire(
        game,
        targetId,
        factionMembership: factionMembership,
      )) {
    return game;
  }
  final cost = joinEmpireCostForMinorOrTribe(game, targetId);
  if (player.treasury < cost) return game;
  final next = absorbGreatPowerIntoGp(game, gpId, targetId);
  return logDiplomaticEvent(
    next,
    turn,
    DiplomaticEventType.joinEmpireResolved,
    {gpId, targetId},
    fromFactionId: gpId,
    toFactionId: targetId,
    overtureStage: OvertureStage.joinEmpire,
    amount: cost,
    wasAiInitiator: isAiControlledForEvidence(next, gpId),
    eventTally: eventTally,
    logMessage: 'diplomacy join empire GP $gpId absorbs $targetId cost=$cost',
  );
}

Game absorbMinorOrTribeIntoGp(
  Game game,
  String gpId,
  String targetId,
  int turn,
) => FactionAbsorptionEngine.absorbMinorOrTribeIntoGp(
  game,
  gpId,
  targetId,
  turn,
);

Game absorbGreatPowerIntoGp(Game game, String gpId, String targetGpId) =>
    FactionAbsorptionEngine.absorbGreatPowerIntoGp(game, gpId, targetGpId);

Game markTribeAsColony(Game game, String gpId, String tribeId, int turn) =>
    FactionAbsorptionEngine.markTribeAsColony(game, gpId, tribeId, turn);
