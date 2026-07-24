import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_event_logging.dart';
import 'diplomacy_resolver.dart';
import 'war_resolver_declare_war.dart';
import 'war_resolver_offer_peace.dart';

Game processWarAndPeace(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn, {
  required DiplomacyFactionMembership factionMembership,
  void Function(DialogueEvent)? onDialogue,
  IntraTurnEventTally? eventTally,
}) {
  final peaceOffersByPairKey = peaceOfferPairKeysForGreatPowers(
    game,
    diploByPlayer,
    factionMembership,
  );
  return _runWarAndPeaceOrders(
    game,
    diploByPlayer,
    turn,
    peaceOffersByPairKey,
    factionMembership,
    onDialogue,
    eventTally,
  );
}

Game _runWarAndPeaceOrders(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn,
  Map<String, Set<String>> peaceOffersByPairKey,
  DiplomacyFactionMembership factionMembership,
  void Function(DialogueEvent)? onDialogue,
  IntraTurnEventTally? eventTally,
) {
  // Single per-phase relation index so each declare-war / offer-peace upsert is
  // amortized O(1) instead of rebuilding the pair-key index per order (Refs #3837).
  final relationsIndex = RelationUpsertIndex(game.diplomacyRelations);
  final warOrders = <({String gpId, DiplomaticOrder order})>[];
  final peaceOrders = <({String gpId, DiplomaticOrder order})>[];
  for (final entry in diploByPlayer.entries) {
    final gpId = entry.key;
    for (final order in entry.value) {
      if (order.type == DiplomaticOrderType.offerPeace) {
        peaceOrders.add((gpId: gpId, order: order));
      } else {
        warOrders.add((gpId: gpId, order: order));
      }
    }
  }
  for (final item in warOrders) {
    game = _applyWarPhaseOrder(
      game: game,
      relationsIndex: relationsIndex,
      gpId: item.gpId,
      order: item.order,
      turn: turn,
      peaceOffersByPairKey: peaceOffersByPairKey,
      factionMembership: factionMembership,
      onDialogue: onDialogue,
      eventTally: eventTally,
    );
  }
  for (final item in peaceOrders) {
    game = _applyWarPhaseOrder(
      game: game,
      relationsIndex: relationsIndex,
      gpId: item.gpId,
      order: item.order,
      turn: turn,
      peaceOffersByPairKey: peaceOffersByPairKey,
      factionMembership: factionMembership,
      onDialogue: onDialogue,
      eventTally: eventTally,
    );
  }
  return game;
}

Game _applyWarPhaseOrder({
  required Game game,
  required RelationUpsertIndex relationsIndex,
  required String gpId,
  required DiplomaticOrder order,
  required int turn,
  required Map<String, Set<String>> peaceOffersByPairKey,
  required DiplomacyFactionMembership factionMembership,
  void Function(DialogueEvent)? onDialogue,
  IntraTurnEventTally? eventTally,
}) {
  if (order.type == DiplomaticOrderType.declareWar) {
    return applyDeclareWarOrder(
      game: game,
      relationsIndex: relationsIndex,
      gpId: gpId,
      order: order,
      turn: turn,
      onDialogue: onDialogue,
      eventTally: eventTally,
    );
  }
  if (order.type == DiplomaticOrderType.offerPeace) {
    return applyOfferPeaceOrder(
      game: game,
      relationsIndex: relationsIndex,
      gpId: gpId,
      order: order,
      turn: turn,
      peaceOffersByPairKey: peaceOffersByPairKey,
      factionMembership: factionMembership,
      onDialogue: onDialogue,
      eventTally: eventTally,
    );
  }
  return game;
}
