import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'alliance_break_cooldown.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_relation_updates.dart';
import 'diplomacy_shared_helpers.dart';
import 'overture_resolver.dart';

/// Applies a voluntary alliance break: unified penalties, `allianceBroken`
/// history, and a one-turn bilateral overture cooldown. Idempotent when no
/// formal alliance exists. Shared by diplomacy-phase resolution and the human
/// panel immediate-break path (Refs #3811).
Game applyVoluntaryAllianceBreak(
  Game game, {
  required String breakerId,
  required String brokenWithAllyId,
  required int turn,
  required DiplomacyFactionMembership factionMembership,
  IntraTurnEventTally? eventTally,
}) {
  if (!factionMembership.isGreatPower(brokenWithAllyId)) return game;

  final rel = getRelation(game, breakerId, brokenWithAllyId);
  if (rel == null || !rel.formalAlliance) return game;

  final otherGpIds = otherRelatedGreatPowerIds(
    game,
    breakerId,
    {brokenWithAllyId},
  );
  final relations = applyAllianceBreakPenalties(
    relations: game.diplomacyRelations,
    breakerId: breakerId,
    brokenWithAllyId: brokenWithAllyId,
    otherGpIds: otherGpIds,
    turn: turn,
  );
  var next = game.copyWith(diplomacyRelations: relations);
  next = logDiplomaticEvent(
    next,
    turn,
    DiplomaticEventType.allianceBroken,
    {breakerId, brokenWithAllyId},
    fromFactionId: breakerId,
    toFactionId: brokenWithAllyId,
    wasAiInitiator: isAiControlledForEvidence(next, breakerId),
    eventTally: eventTally,
    logMessage: 'diplomacy break alliance $breakerId-$brokenWithAllyId (voluntary)',
  );
  return next.copyWith(
    allianceBreakCooldowns: upsertAllianceBreakCooldown(
      next.allianceBreakCooldowns,
      breakerId,
      brokenWithAllyId,
      turn,
    ),
  );
}

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

      game = applyVoluntaryAllianceBreak(
        game,
        breakerId: gpId,
        brokenWithAllyId: targetId,
        turn: turn,
        factionMembership: factionMembership,
        eventTally: eventTally,
      );
    }
  }
  return game;
}
