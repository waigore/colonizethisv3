/// Diplomacy models. SPEC/game/diplomacy.md, diplomacy-resolution.md.

/// Relation state per faction-pair.
enum RelationState { atPeace, atWar }

/// Relation level derived from score (0–25 Hostile, 26–50 Neutral, 51–75 Friendly, 76–100 Allied).
enum RelationLevel { hostile, neutral, friendly, allied }

/// Per faction-pair relation. Stored in world state; save/load.
class DiplomacyRelation {
  const DiplomacyRelation({
    required this.factionId1,
    required this.factionId2,
    this.score = 50,
    this.level = RelationLevel.neutral,
    this.state = RelationState.atPeace,
    this.sinceTurn = 0,
    this.lastInteractionTurn = 0,
  });

  final String factionId1;
  final String factionId2;
  final int score;
  final RelationLevel level;
  final RelationState state;
  final int sinceTurn;
  final int lastInteractionTurn;

  bool get atWar => state == RelationState.atWar;
  bool get atPeace => state == RelationState.atPeace;

  /// True when this relation row includes [nationId] as either party.
  bool involvesNation(String nationId) =>
      factionId1 == nationId || factionId2 == nationId;

  DiplomacyRelation copyWith({
    String? factionId1,
    String? factionId2,
    int? score,
    RelationLevel? level,
    RelationState? state,
    int? sinceTurn,
    int? lastInteractionTurn,
  }) => DiplomacyRelation(
    factionId1: factionId1 ?? this.factionId1,
    factionId2: factionId2 ?? this.factionId2,
    score: score ?? this.score,
    level: level ?? this.level,
    state: state ?? this.state,
    sinceTurn: sinceTurn ?? this.sinceTurn,
    lastInteractionTurn: lastInteractionTurn ?? this.lastInteractionTurn,
  );

  Map<String, dynamic> toJson() => {
    'factionId1': factionId1,
    'factionId2': factionId2,
    'score': score,
    'level': level.name,
    'state': state.name,
    'sinceTurn': sinceTurn,
    'lastInteractionTurn': lastInteractionTurn,
  };

  static DiplomacyRelation fromJson(Map<String, dynamic> json) =>
      DiplomacyRelation(
        factionId1: json['factionId1'] as String,
        factionId2: json['factionId2'] as String,
        score: json['score'] as int? ?? 50,
        level: RelationLevel.values.firstWhere(
          (e) => e.name == json['level'],
          orElse: () => RelationLevel.neutral,
        ),
        state: RelationState.values.firstWhere(
          (e) => e.name == json['state'],
          orElse: () => RelationState.atPeace,
        ),
        sinceTurn: json['sinceTurn'] as int? ?? 0,
        lastInteractionTurn: json['lastInteractionTurn'] as int? ?? 0,
      );
}

/// Overture stage per Minor/Tribe per GP.
enum OvertureStage { none, tradeConsulate, embassy, nap, joinEmpire }

/// Per Minor/Tribe per GP overture state.
class OvertureState {
  const OvertureState({
    required this.gpId,
    required this.targetId,
    this.stage = OvertureStage.none,
    this.sinceTurn = 0,
  });

  final String gpId;
  final String targetId;
  final OvertureStage stage;
  final int sinceTurn;

  bool get hasEmbassy =>
      stage == OvertureStage.embassy ||
      stage == OvertureStage.nap ||
      stage == OvertureStage.joinEmpire;
  bool get hasConsulate => stage != OvertureStage.none;

  OvertureState copyWith({
    String? gpId,
    String? targetId,
    OvertureStage? stage,
    int? sinceTurn,
  }) => OvertureState(
    gpId: gpId ?? this.gpId,
    targetId: targetId ?? this.targetId,
    stage: stage ?? this.stage,
    sinceTurn: sinceTurn ?? this.sinceTurn,
  );

  Map<String, dynamic> toJson() => {
    'gpId': gpId,
    'targetId': targetId,
    'stage': stage.name,
    'sinceTurn': sinceTurn,
  };

  static OvertureState fromJson(Map<String, dynamic> json) => OvertureState(
    gpId: json['gpId'] as String,
    targetId: json['targetId'] as String,
    stage: OvertureStage.values.firstWhere(
      (e) => e.name == json['stage'],
      orElse: () => OvertureStage.none,
    ),
    sinceTurn: json['sinceTurn'] as int? ?? 0,
  );
}

/// Diplomatic order types. SPEC/program/diplomacy-resolution.
enum DiplomaticOrderType {
  declareWar,
  offerPeace,
  alliance,
  establishOverture,
  establishFtp,
  grantAid,
  setSubsidy,
}

/// Base for diplomatic orders.
class DiplomaticOrder {
  const DiplomaticOrder({
    required this.type,
    required this.targetFactionId,
    this.amount,
    this.overtureStage,
  });

  final DiplomaticOrderType type;
  final String targetFactionId;
  final int? amount;
  final OvertureStage? overtureStage;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'targetFactionId': targetFactionId,
    if (amount != null) 'amount': amount,
    if (overtureStage != null) 'overtureStage': overtureStage!.name,
  };

  static DiplomaticOrder fromJson(Map<String, dynamic> json) => DiplomaticOrder(
    type: DiplomaticOrderType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => DiplomaticOrderType.declareWar,
    ),
    targetFactionId: json['targetFactionId'] as String,
    amount: json['amount'] as int?,
    overtureStage: json['overtureStage'] != null
        ? OvertureStage.values.firstWhere(
            (e) => e.name == json['overtureStage'],
            orElse: () => OvertureStage.none,
          )
        : null,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiplomaticOrder &&
          type == other.type &&
          targetFactionId == other.targetFactionId &&
          amount == other.amount &&
          overtureStage == other.overtureStage;

  @override
  int get hashCode => Object.hash(type, targetFactionId, amount, overtureStage);
}

/// Intervention choice when Minor with Embassy is attacked. SPEC/game/diplomacy.md.
enum InterventionChoice { intervene, doNothing, protest }

/// Ongoing subsidy from a GP to a Minor/Tribe. SPEC/game/diplomacy.md.
/// Each turn: payer loses amount, relation improves.
class SubsidyState {
  const SubsidyState({
    required this.payerId,
    required this.targetId,
    required this.amountPerTurn,
  });

  final String payerId;
  final String targetId;
  final int amountPerTurn;

  SubsidyState copyWith({
    String? payerId,
    String? targetId,
    int? amountPerTurn,
  }) => SubsidyState(
    payerId: payerId ?? this.payerId,
    targetId: targetId ?? this.targetId,
    amountPerTurn: amountPerTurn ?? this.amountPerTurn,
  );

  Map<String, dynamic> toJson() => {
    'payerId': payerId,
    'targetId': targetId,
    'amountPerTurn': amountPerTurn,
  };

  static SubsidyState fromJson(Map<String, dynamic> json) => SubsidyState(
    payerId: json['payerId'] as String,
    targetId: json['targetId'] as String,
    amountPerTurn: json['amountPerTurn'] as int,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubsidyState &&
          payerId == other.payerId &&
          targetId == other.targetId &&
          amountPerTurn == other.amountPerTurn;

  @override
  int get hashCode => Object.hash(payerId, targetId, amountPerTurn);
}

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
          _setEquals(participants, other.participants) &&
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

  static bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    for (final value in a) {
      if (!b.contains(value)) return false;
    }
    return true;
  }
}
