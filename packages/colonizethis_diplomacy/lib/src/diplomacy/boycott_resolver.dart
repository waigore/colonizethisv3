import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_shared_helpers.dart';
import 'diplomacy_event_logging.dart';

/// Resolves `boycott` and `revokeBoycott` diplomatic orders (Refs #3753 R6).
///
/// A boycott is keyed by the `(issuerGpId, targetGpId)` pair. A `boycott` order
/// is applied only when the issuer is a Great Power that holds at least one
/// colony, the target is **another** Great Power at peace with the issuer, and
/// no `(issuer, target)` boycott already exists. Applying a boycott also cancels
/// any active subsidy from the **target** GP to a Tribe that is a colony of the
/// **issuer** (R6.2). A `revokeBoycott` order removes an existing `(issuer,
/// target)` boycott.
///
/// Orders that no longer satisfy preconditions at resolution are ignored
/// (validation already rejects them; resolution re-checks for safety).
/// SPEC/program/diplomacy-resolution.md; SPEC/game/diplomacy.md § GP–Tribe Rules.
Game processBoycotts(
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
      switch (order.type) {
        case DiplomaticOrderType.boycott:
          game = _applyBoycott(
            game,
            gpId,
            order.targetFactionId,
            turn,
            factionMembership: factionMembership,
            eventTally: eventTally,
          );
        case DiplomaticOrderType.revokeBoycott:
          game = _revokeBoycott(
            game,
            gpId,
            order.targetFactionId,
            turn,
            eventTally: eventTally,
          );
        default:
          continue;
      }
    }
  }
  return game;
}

bool _hasBoycott(Game game, String gpId, String targetGpId) => game.boycottStates
    .any((b) => b.gpId == gpId && b.targetGpId == targetGpId);

Game _applyBoycott(
  Game game,
  String gpId,
  String targetGpId,
  int turn, {
  required DiplomacyFactionMembership factionMembership,
  IntraTurnEventTally? eventTally,
}) {
  if (gpId == targetGpId) return game;
  if (!factionMembership.isGreatPower(targetGpId)) return game;
  final holdsColony = game.colonyStates.any((c) => c.colonyOfGpId == gpId);
  if (!holdsColony) return game;
  final rel = getRelation(game, gpId, targetGpId);
  if (rel?.atWar ?? false) return game;
  if (_hasBoycott(game, gpId, targetGpId)) return game;

  game = game.copyWith(
    boycottStates: [
      ...game.boycottStates,
      BoycottState(gpId: gpId, targetGpId: targetGpId, sinceTurn: turn),
    ],
  );
  game = logDiplomaticEvent(
    game,
    turn,
    DiplomaticEventType.boycottSet,
    {gpId, targetGpId},
    fromFactionId: gpId,
    toFactionId: targetGpId,
    wasAiInitiator: isAiControlledForEvidence(game, gpId),
    eventTally: eventTally,
    logMessage: 'diplomacy boycott set $gpId vs $targetGpId',
  );

  // R6.2: cancel any active subsidy from the boycotted GP to one of the
  // issuer's colony Tribes.
  return _cancelTargetSubsidiesToColonies(
    game,
    gpId,
    targetGpId,
    turn,
    eventTally: eventTally,
  );
}

Game _revokeBoycott(
  Game game,
  String gpId,
  String targetGpId,
  int turn, {
  IntraTurnEventTally? eventTally,
}) {
  if (!_hasBoycott(game, gpId, targetGpId)) return game;
  game = game.copyWith(
    boycottStates: game.boycottStates
        .where((b) => !(b.gpId == gpId && b.targetGpId == targetGpId))
        .toList(),
  );
  return logDiplomaticEvent(
    game,
    turn,
    DiplomaticEventType.boycottRevoked,
    {gpId, targetGpId},
    fromFactionId: gpId,
    toFactionId: targetGpId,
    wasAiInitiator: isAiControlledForEvidence(game, gpId),
    eventTally: eventTally,
    logMessage: 'diplomacy boycott revoked $gpId vs $targetGpId',
  );
}

Game _cancelTargetSubsidiesToColonies(
  Game game,
  String gpId,
  String targetGpId,
  int turn, {
  IntraTurnEventTally? eventTally,
}) {
  final colonyTribeIds = <String>{
    for (final c in game.colonyStates)
      if (c.colonyOfGpId == gpId) c.tribeId,
  };
  if (colonyTribeIds.isEmpty) return game;

  final cancelled = game.subsidyStates
      .where(
        (s) => s.payerId == targetGpId && colonyTribeIds.contains(s.targetId),
      )
      .toList();
  if (cancelled.isEmpty) return game;

  game = game.copyWith(
    subsidyStates: game.subsidyStates
        .where(
          (s) =>
              !(s.payerId == targetGpId && colonyTribeIds.contains(s.targetId)),
        )
        .toList(),
  );
  for (final s in cancelled) {
    game = logDiplomaticEvent(
      game,
      turn,
      DiplomaticEventType.subsidyCancelled,
      {s.payerId, s.targetId},
      fromFactionId: s.payerId,
      toFactionId: s.targetId,
      reason: 'boycott',
      eventTally: eventTally,
      logMessage:
          'diplomacy subsidy cancelled by boycott ${s.payerId} -> ${s.targetId}',
    );
  }
  return game;
}

/// Auto-cancels any boycott whose `(gpId, targetGpId)` pair is now `AT_WAR`
/// (Refs #3753 R6.4) — the war rules already block trade. Appends a
/// `boycottRevoked` event per removed boycott. SPEC/game/diplomacy.md.
Game autoCancelBoycottsOnWar(
  Game game,
  int turn, {
  IntraTurnEventTally? eventTally,
}) {
  final toCancel = game.boycottStates
      .where((b) => getRelation(game, b.gpId, b.targetGpId)?.atWar ?? false)
      .toList();
  if (toCancel.isEmpty) return game;

  final cancelKeys = {for (final b in toCancel) '${b.gpId}\x1F${b.targetGpId}'};
  game = game.copyWith(
    boycottStates: game.boycottStates
        .where((b) => !cancelKeys.contains('${b.gpId}\x1F${b.targetGpId}'))
        .toList(),
  );
  for (final b in toCancel) {
    game = logDiplomaticEvent(
      game,
      turn,
      DiplomaticEventType.boycottRevoked,
      {b.gpId, b.targetGpId},
      fromFactionId: b.gpId,
      toFactionId: b.targetGpId,
      reason: 'war',
      wasAiInitiator: isAiControlledForEvidence(game, b.gpId),
      eventTally: eventTally,
      logMessage: 'diplomacy boycott auto-cancelled by war ${b.gpId} vs ${b.targetGpId}',
    );
  }
  return game;
}
