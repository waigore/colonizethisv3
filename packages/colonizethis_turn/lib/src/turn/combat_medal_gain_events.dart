// Emits general medal-gain game events after land battles (Refs #4234).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'turn_event_sink.dart';

String? winnerGeneralIdForBattle(BattleContext ctx, String winnerId) {
  if (winnerId == ctx.defenderFactionId) {
    return ctx.defenderGeneralId;
  }
  for (final attacker in ctx.attackers) {
    if (attacker.factionId == winnerId) {
      return attacker.generalId;
    }
  }
  return null;
}

General? _generalById(Game game, String generalId) {
  for (final general in game.generals) {
    if (general.id == generalId) {
      return general;
    }
  }
  return null;
}

void emitGeneralMedalGainedIfAny({
  required Game gameBefore,
  required Game gameAfter,
  required BattleContext ctx,
  required String? winnerId,
  required int turn,
  required TurnEventSink sink,
}) {
  if (!sink.hasGameEvent || winnerId == null) {
    return;
  }
  final generalId = winnerGeneralIdForBattle(ctx, winnerId);
  if (generalId == null) {
    return;
  }
  final before = _generalById(gameBefore, generalId);
  final after = _generalById(gameAfter, generalId);
  if (before == null || after == null) {
    return;
  }
  if (after.medals <= before.medals) {
    return;
  }
  sink.emit(
    GeneralMedalGainedEvent(
      playerId: after.ownerId,
      generalId: generalId,
      provinceId: ctx.provinceId,
      newMedals: after.medals,
      turnNumber: turn,
    ),
  );
}
