import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'diplomacy_event_logging.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_relation_updates.dart';
import 'diplomacy_shared_helpers.dart';

/// Process GrantAid orders: deduct payer treasury and apply the fixed relation
/// modifier (+5 per grant, clamped). Requires an Embassy (R2). Amount must be a
/// positive multiple of [grantAidAmountStep]. SPEC/game/diplomacy.md § Diplomatic
/// Order Types (Refs #4130 slice C).
Game applyGrantAidOrders(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn, {
  IntraTurnEventTally? eventTally,
}) {
  var players = game.players;
  // Stable id → row index while [players] order/count is unchanged (Refs #2394).
  final playerIndexById = indexByKey(players, (p) => p.id);
  // Pair-key index built once for the phase; grant-aid upserts are amortized
  // O(1) instead of rebuilding the index per order (Refs #3419 step 5).
  final relationsIndex = RelationUpsertIndex(game.diplomacyRelations);

  for (final entry in diploByPlayer.entries) {
    final gpId = entry.key;
    final player = game.playerById(gpId);
    if (player == null) continue;

    for (final order in entry.value) {
      if (order.type != DiplomaticOrderType.grantAid) continue;
      final amount = order.amount ?? 0;
      if (amount > 0 && amount % grantAidAmountStep != 0) {
        throw StateError(
          'GrantAid at resolution must be a positive multiple of '
          '£$grantAidAmountStep (was $amount)',
        );
      }
      if (amount <= 0 || player.treasury < amount) continue;
      if (amount < grantAidAmountStep || amount % grantAidAmountStep != 0) {
        continue;
      }

      final targetId = order.targetFactionId;
      final overture = getOverture(game, gpId, targetId);
      if (overture == null || !overture.hasEmbassy) continue;

      players = debitPlayerTreasury(
        players,
        playerIndexById[gpId] ?? -1,
        amount,
      );

      relationsIndex.upsert(
        gpId,
        targetId,
        grantAidRelationUpdater(gpId, targetId, turn),
      );
      game = game.copyWith(
        players: players,
        diplomacyRelations: committedRelations(relationsIndex),
      );
      game = logDiplomaticEvent(
        game,
        turn,
        DiplomaticEventType.grantAidApplied,
        {gpId, targetId},
        fromFactionId: gpId,
        toFactionId: targetId,
        amount: amount,
        wasAiInitiator: isAiControlledForEvidence(game, gpId),
        eventTally: eventTally,
        logMessage: 'diplomacy GrantAid $gpId -> $targetId amount $amount',
      );
    }
  }

  return game;
}
