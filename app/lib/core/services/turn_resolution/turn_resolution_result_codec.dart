import 'dart:convert';

import 'package:colonizethis_turn/colonizethis_turn.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// JSON codec for [TurnResolutionResult] isolate handoff (Refs #3878).
int safeTurnResolutionJsonUtf8Bytes(Object? value) {
  try {
    return utf8.encode(jsonEncode(value)).length;
  } catch (_) {
    return -1;
  }
}

String turnResolutionResultTypeName(TurnResolutionResult result) {
  return switch (result) {
    TurnResolutionComplete() => 'complete',
    TurnResolutionPendingOvertures() => 'pendingOvertures',
    TurnResolutionPendingFtp() => 'pendingFtp',
    TurnResolutionPendingIntervention() => 'pendingIntervention',
    TurnResolutionPendingCallToArms() => 'pendingCallToArms',
  };
}

Map<String, Object?> encodeTurnResolutionResult(TurnResolutionResult result) {
  switch (result) {
    case TurnResolutionComplete():
      return {'type': 'complete', 'game': result.game.toJson()};
    case TurnResolutionPendingOvertures():
      return {
        'type': 'pendingOvertures',
        'game': result.game.toJson(),
        'pendingOvertures': result.pendingOvertures
            .map(
              (offer) => {
                'offererGpId': offer.offererGpId,
                'targetFactionId': offer.targetFactionId,
                'stage': offer.stage.name,
              },
            )
            .toList(growable: false),
      };
    case TurnResolutionPendingFtp():
      return {
        'type': 'pendingFtp',
        'game': result.game.toJson(),
        'pendingFtpOffers': result.pendingFtpOffers
            .map(
              (offer) => {
                'proposerGpId': offer.proposerGpId,
                'targetGpId': offer.targetGpId,
              },
            )
            .toList(growable: false),
      };
    case TurnResolutionPendingIntervention():
      return {
        'type': 'pendingIntervention',
        'game': result.game.toJson(),
        'pendingInterventions': result.pendingInterventions
            .map(
              (prompt) => {
                'aggressorGpId': prompt.aggressorGpId,
                'defenderMinorOrTribeId': prompt.defenderMinorOrTribeId,
                'interveningGpId': prompt.interveningGpId,
              },
            )
            .toList(growable: false),
      };
    case TurnResolutionPendingCallToArms():
      return {
        'type': 'pendingCallToArms',
        'game': result.game.toJson(),
        'pendingCallToArms': result.pendingCallToArms
            .map(
              (pending) => {
                'allyGpId': pending.allyGpId,
                'defenderGpId': pending.defenderGpId,
                'aggressorGpId': pending.aggressorGpId,
              },
            )
            .toList(growable: false),
      };
  }
}

TurnResolutionResult decodeTurnResolutionResult(Map<String, dynamic> json) {
  final game = Game.fromJson(
    Map<String, dynamic>.from(json['game'] as Map<Object?, Object?>),
  );
  final type = json['type'] as String;
  switch (type) {
    case 'complete':
      return TurnResolutionComplete(game);
    case 'pendingOvertures':
      final list = (json['pendingOvertures'] as List<dynamic>)
          .map(
            (entry) =>
                Map<String, dynamic>.from(entry as Map<Object?, Object?>),
          )
          .map(
            (entry) => OvertureOffer(
              offererGpId: entry['offererGpId'] as String,
              targetFactionId: entry['targetFactionId'] as String,
              stage: OvertureStage.values.byName(entry['stage'] as String),
            ),
          )
          .toList(growable: false);
      return TurnResolutionPendingOvertures(game: game, pendingOvertures: list);
    case 'pendingFtp':
      final ftpList = (json['pendingFtpOffers'] as List<dynamic>)
          .map(
            (entry) =>
                Map<String, dynamic>.from(entry as Map<Object?, Object?>),
          )
          .map(
            (entry) => FtpOffer(
              proposerGpId: entry['proposerGpId'] as String,
              targetGpId: entry['targetGpId'] as String,
            ),
          )
          .toList(growable: false);
      return TurnResolutionPendingFtp(game: game, pendingFtpOffers: ftpList);
    case 'pendingIntervention':
      final list = (json['pendingInterventions'] as List<dynamic>)
          .map(
            (entry) =>
                Map<String, dynamic>.from(entry as Map<Object?, Object?>),
          )
          .map(
            (entry) => InterventionPrompt(
              aggressorGpId: entry['aggressorGpId'] as String,
              defenderMinorOrTribeId: entry['defenderMinorOrTribeId'] as String,
              interveningGpId: entry['interveningGpId'] as String,
            ),
          )
          .toList(growable: false);
      return TurnResolutionPendingIntervention(
        game: game,
        pendingInterventions: list,
      );
    case 'pendingCallToArms':
      final list = (json['pendingCallToArms'] as List<dynamic>)
          .map(
            (entry) =>
                Map<String, dynamic>.from(entry as Map<Object?, Object?>),
          )
          .map(
            (entry) => CallToArmsPending(
              allyGpId: entry['allyGpId'] as String,
              defenderGpId: entry['defenderGpId'] as String,
              aggressorGpId: entry['aggressorGpId'] as String,
            ),
          )
          .toList(growable: false);
      return TurnResolutionPendingCallToArms(
        game: game,
        pendingCallToArms: list,
      );
    default:
      throw StateError('Unknown turn resolution result type: $type');
  }
}
