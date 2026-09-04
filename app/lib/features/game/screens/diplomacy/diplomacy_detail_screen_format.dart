import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart'
    show getRelation, relationScoreToDisplayLabel;
import 'package:colonizethis_world/colonizethis_world.dart' show Game, GamePlayerLookup;

import 'package:colonizethis_models/colonizethis_models.dart';

/// Human-readable sentence for a diplomatic event. Unknown factions shown as "Unknown faction".
String formatDiplomaticEvent(
  DiplomaticEvent e,
  Game game,
  String humanPlayerId,
) {
  String name(String factionId) {
    if (factionId == humanPlayerId) return 'We';
    if (getRelation(game, humanPlayerId, factionId) == null) {
      return 'Unknown faction';
    }
    final p = game.playerById(factionId);
    if (p != null) return p.displayName;
    for (final m in game.minorNations) {
      if (m.id == factionId) return m.displayName ?? factionId;
    }
    for (final t in game.tribes) {
      if (t.id == factionId) return t.displayName ?? factionId;
    }
    return factionId;
  }

  final from = e.fromFactionId != null ? name(e.fromFactionId!) : null;
  final to = e.toFactionId != null ? name(e.toFactionId!) : null;
  final stage = e.overtureStage != null
      ? overtureLabel(e.overtureStage!)
      : null;

  switch (e.type) {
    case DiplomaticEventType.declareWar:
      return '${from ?? 'Unknown'} declared war on ${to ?? 'Unknown'}.';
    case DiplomaticEventType.peace:
      return '${from ?? 'Unknown'} made peace with ${to ?? 'Unknown'}.';
    case DiplomaticEventType.allianceFormed:
      return '${from ?? 'Unknown'} formed an alliance with ${to ?? 'Unknown'}.';
    case DiplomaticEventType.allianceBroken:
      return 'Alliance between ${from ?? 'Unknown'} and ${to ?? 'Unknown'} ended.';
    case DiplomaticEventType.overtureAccepted:
      return '${from ?? 'Unknown'} established ${stage ?? 'overture'} with ${to ?? 'Unknown'}.';
    case DiplomaticEventType.overtureRejected:
      return '${to ?? 'Unknown'} rejected ${stage ?? 'overture'} from ${from ?? 'Unknown'}.';
    case DiplomaticEventType.joinEmpireResolved:
      return formatJoinEmpireResolvedSentence(
        game: game,
        fromLabel: from ?? 'Unknown',
        toLabel: to ?? 'Unknown',
        toFactionId: e.toFactionId,
      );
    case DiplomaticEventType.grantAidApplied:
      final amt = e.amount ?? 0;
      return '${from ?? 'Unknown'} granted £$amt aid to ${to ?? 'Unknown'}.';
    case DiplomaticEventType.subsidySet:
      return '${from ?? 'Unknown'} set subsidy of ${e.amount ?? 0}% to ${to ?? 'Unknown'}.';
    case DiplomaticEventType.subsidyUpdated:
      return '${from ?? 'Unknown'} updated subsidy to ${e.amount ?? 0}% to ${to ?? 'Unknown'}.';
    case DiplomaticEventType.subsidyCancelled:
      return 'Subsidy ${from ?? 'Unknown'} → ${to ?? 'Unknown'} ended (${e.reason ?? 'cancelled'}).';
    case DiplomaticEventType.boycottSet:
      return '${from ?? 'Unknown'} began a boycott against ${to ?? 'Unknown'}.';
    case DiplomaticEventType.boycottRevoked:
      return 'Boycott by ${from ?? 'Unknown'} against ${to ?? 'Unknown'} ended (${e.reason ?? 'revoked'}).';
    case DiplomaticEventType.interventionIntervene:
      return '${from ?? 'Unknown'} intervened in war (against ${to ?? 'Unknown'}).';
    case DiplomaticEventType.interventionDoNothing:
      return '${from ?? 'Unknown'} did not intervene (against ${to ?? 'Unknown'}).';
    case DiplomaticEventType.interventionProtest:
      return '${from ?? 'Unknown'} protested (against ${to ?? 'Unknown'}).';
    case DiplomaticEventType.agreementsClearedOnWar:
      return 'Overtures between ${from ?? 'Unknown'} and ${to ?? 'Unknown'} ended due to war.';
    case DiplomaticEventType.callToArmsAccepted:
      return '${from ?? 'Unknown'} joined the war against ${to ?? 'Unknown'} (call to arms).';
    case DiplomaticEventType.callToArmsRefused:
      return '${from ?? 'Unknown'} refused call to arms; alliance with ${to ?? 'Unknown'} ended.';
    case DiplomaticEventType.ftpFormed:
      return '${from ?? 'Unknown'} established a free trade partnership with ${to ?? 'Unknown'}.';
    case DiplomaticEventType.ftpBroken:
      return 'Free trade partnership between ${from ?? 'Unknown'} and ${to ?? 'Unknown'} ended (${e.reason ?? 'cancelled'}).';
  }
}

String overtureLabel(OvertureStage s) {
  return switch (s) {
    OvertureStage.none => 'overture',
    OvertureStage.tradeConsulate => 'Trade Consulate',
    OvertureStage.embassy => 'Embassy',
    OvertureStage.nap => 'Non-Aggression Pact',
    OvertureStage.joinEmpire => 'Join Empire',
  };
}

/// Whether a Join Empire target resolved as a Tribe colony (land stays theirs).
///
/// Tribes remain on the map and appear in [Game.colonyStates]; absorbed
/// Minors/GPs leave the map. Used by history and Intelligence copy (Refs #4729).
bool isJoinEmpireColonyTarget(Game game, String? toFactionId) {
  if (toFactionId == null || toFactionId.isEmpty) return false;
  if (game.tribes.any((t) => t.id == toFactionId)) return true;
  return game.colonyStates.any((c) => c.tribeId == toFactionId);
}

/// Player-facing sentence for [DiplomaticEventType.joinEmpireResolved].
String formatJoinEmpireResolvedSentence({
  required Game game,
  required String fromLabel,
  required String toLabel,
  String? toFactionId,
}) {
  if (isJoinEmpireColonyTarget(game, toFactionId)) {
    return '$toLabel became a colony of $fromLabel (Join Empire); '
        'their land stayed theirs.';
  }
  return '$fromLabel absorbed $toLabel (Join Empire); '
      'their land, armies, and fleets transferred.';
}
