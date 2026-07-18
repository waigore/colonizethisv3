/// Diplomatic history event models. SPEC/program/diplomacy-resolution.md.
///
/// Concern split from former monolithic `diplomacy.dart` (Refs #4068).

import '../model_collection_equality.dart';
import 'overtures.dart';

/// Primary type for a diplomatic history event. SPEC/program/diplomacy-resolution.md.
enum DiplomaticEventType {
  declareWar,
  peace,
  allianceFormed,
  allianceBroken,
  ftpFormed,
  ftpBroken,
  overtureAccepted,
  overtureRejected,
  joinEmpireResolved,
  grantAidApplied,
  subsidySet,
  subsidyUpdated,
  subsidyCancelled,

  /// A boycott was established against a Great Power (Refs #3753 R6).
  boycottSet,

  /// A boycott was removed (voluntary revoke or auto-cancel on war,
  /// Refs #3753 R6).
  boycottRevoked,
  interventionIntervene,
  interventionDoNothing,
  interventionProtest,
  agreementsClearedOnWar,

  /// Ally accepted call to arms: entered war with aggressor. SPEC/game/diplomacy.md.
  callToArmsAccepted,

  /// Ally refused call to arms: broke alliance obligations with defender. SPEC/game/diplomacy.md.
  callToArmsRefused,
}

/// Diplomatic history event stored on Game.diplomaticHistoryEvents.
class DiplomaticEvent {
  const DiplomaticEvent({
    required this.turn,
    required this.intraTurnIndex,
    required this.type,
    required this.participants,
    this.fromFactionId,
    this.toFactionId,
    this.overtureStage,
    this.amount,
    this.reason,
    this.wasAiInitiator = false,
  });

  final int turn;
  final int intraTurnIndex;
  final DiplomaticEventType type;
  final Set<String> participants;
  final String? fromFactionId;
  final String? toFactionId;
  final OvertureStage? overtureStage;
  final int? amount;
  final String? reason;
  final bool wasAiInitiator;

  Map<String, dynamic> toJson() => {
    'turn': turn,
    'intraTurnIndex': intraTurnIndex,
    'type': type.name,
    'participants': participants.toList(),
    if (fromFactionId != null) 'fromFactionId': fromFactionId,
    if (toFactionId != null) 'toFactionId': toFactionId,
    if (overtureStage != null) 'overtureStage': overtureStage!.name,
    if (amount != null) 'amount': amount,
    if (reason != null) 'reason': reason,
    if (wasAiInitiator) 'wasAiInitiator': wasAiInitiator,
  };

  static DiplomaticEvent fromJson(Map<String, dynamic> json) {
    final participantsList = json['participants'] as List<dynamic>? ?? [];
    return DiplomaticEvent(
      turn: (json['turn'] as num).toInt(),
      intraTurnIndex: (json['intraTurnIndex'] as num).toInt(),
      type: DiplomaticEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DiplomaticEventType.declareWar,
      ),
      participants: participantsList.map((e) => e.toString()).toSet(),
      fromFactionId: json['fromFactionId'] as String?,
      toFactionId: json['toFactionId'] as String?,
      overtureStage: json['overtureStage'] != null
          ? OvertureStage.values.firstWhere(
              (e) => e.name == json['overtureStage'],
              orElse: () => OvertureStage.none,
            )
          : null,
      amount: json['amount'] as int?,
      reason: json['reason'] as String?,
      wasAiInitiator: json['wasAiInitiator'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiplomaticEvent &&
          turn == other.turn &&
          intraTurnIndex == other.intraTurnIndex &&
          type == other.type &&
          modelSetEquals(participants, other.participants) &&
          fromFactionId == other.fromFactionId &&
          toFactionId == other.toFactionId &&
          overtureStage == other.overtureStage &&
          amount == other.amount &&
          reason == other.reason &&
          wasAiInitiator == other.wasAiInitiator;

  @override
  int get hashCode => Object.hash(
    turn,
    intraTurnIndex,
    type,
    Object.hashAll(participants),
    fromFactionId,
    toFactionId,
    overtureStage,
    amount,
    reason,
    wasAiInitiator,
  );
}
