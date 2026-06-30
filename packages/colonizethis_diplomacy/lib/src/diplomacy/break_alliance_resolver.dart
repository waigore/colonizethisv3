import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_relation_updates.dart';
import 'diplomacy_shared_helpers.dart';
import 'overture_resolver.dart';

/// Resolves voluntary `breakAlliance` diplomatic orders (R11).
///
/// For each order whose issuer holds a **formal alliance** with a Great Power
/// target, this clears the alliance flag and applies the unified
/// alliance-break penalty (−[allianceBreakAllyScorePenalty] to the broken-with
/// ally and −[allianceBreakOtherGpScorePenalty] to every other Great Power the
/// breaker has a relation with), then appends an `allianceBroken` event.
///
/// Only the presence of the `formalAlliance` flag matters. Because entering war
/// clears the pair's `formalAlliance` (war invariant — a treaty cannot coexist
/// with war), an at-war pair holds no treaty and a break order against it is a
/// no-op here. Orders against non-GP targets or pairs without a formal alliance
/// are ignored (validation already rejects them; resolution re-checks for
/// safety). SPEC/game/diplomacy.md § Alliances; SPEC/program/diplomacy-resolution.md.
Game processBreakAlliances(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn, {
  required DiplomacyFactionMembership factionMembership,
  IntraTurnEventTally? eventTally,
}) {
  for (final entry in diploByPlayer.entries) {
    final gpId = entry.key;
    if (!factionMembership.isGreatPower(gpId)) continue;
    for (final order in entry.value) {
      if (order.type != DiplomaticOrderType.breakAlliance) continue;
      final targetId = order.targetFactionId;
      if (!factionMembership.isGreatPower(targetId)) continue;

      final rel = getRelation(game, gpId, targetId);
      if (rel == null || !rel.formalAlliance) continue;

      final otherGpIds = otherRelatedGreatPowerIds(game, gpId, {targetId});
      final relations = applyAllianceBreakPenalties(
        relations: game.diplomacyRelations,
        breakerId: gpId,
        brokenWithAllyId: targetId,
        otherGpIds: otherGpIds,
        turn: turn,
      );
      game = game.copyWith(diplomacyRelations: relations);
      game = logDiplomaticEvent(
        game,
        turn,
        DiplomaticEventType.allianceBroken,
        {gpId, targetId},
        fromFactionId: gpId,
        toFactionId: targetId,
        wasAiInitiator: isAiControlledForEvidence(game, gpId),
        eventTally: eventTally,
        logMessage: 'diplomacy break alliance $gpId-$targetId (voluntary)',
      );
    }
  }
  return game;
}
