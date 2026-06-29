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
    this.formalAlliance = false,
  });

  final String factionId1;
  final String factionId2;

  /// Decimal relation score in `[0, 100]`. Stored as `num` so the resolver can
  /// hold fractional values (0.1 precision) introduced by per-turn decay and
  /// the additive-scaled trade-deal boost; integer values represent whole
  /// scores. Threshold comparisons operate on the raw decimal.
  /// SPEC/game/diplomacy.md § Relation Model.
  final num score;
  final RelationLevel level;
  final RelationState state;
  final int sinceTurn;
  final int lastInteractionTurn;

  /// Persisted **formal alliance** (treaty) flag for this GP–GP pair.
  ///
  /// Set true when an `Alliance` diplomatic order resolves (`allianceFormed`)
  /// and cleared on `allianceBroken` (e.g. a Call to Arms refusal). This is the
  /// authoritative mutual-defence gate: the informal [level] `allied` band
  /// (relation score 76–100) must NOT trigger Call to Arms by itself.
  /// SPEC/game/diplomacy.md § Alliances.
  final bool formalAlliance;

  bool get atWar => state == RelationState.atWar;
  bool get atPeace => state == RelationState.atPeace;

  /// True when this relation row includes [nationId] as either party.
  bool involvesNation(String nationId) =>
      factionId1 == nationId || factionId2 == nationId;

  DiplomacyRelation copyWith({
    String? factionId1,
    String? factionId2,
    num? score,
    RelationLevel? level,
    RelationState? state,
    int? sinceTurn,
    int? lastInteractionTurn,
    bool? formalAlliance,
  }) => DiplomacyRelation(
    factionId1: factionId1 ?? this.factionId1,
    factionId2: factionId2 ?? this.factionId2,
    score: score ?? this.score,
    level: level ?? this.level,
    state: state ?? this.state,
    sinceTurn: sinceTurn ?? this.sinceTurn,
    lastInteractionTurn: lastInteractionTurn ?? this.lastInteractionTurn,
    formalAlliance: formalAlliance ?? this.formalAlliance,
  );

  Map<String, dynamic> toJson() => {
    'factionId1': factionId1,
    'factionId2': factionId2,
    // Serialize the decimal form (× 1.0) so save/load round-trips the decimal
    // symmetrically with `fromJson`: a whole score of 50 persists as `50.0`,
    // not `50`, keeping load → re-encode byte-stable.
    // SPEC/game/diplomacy.md § Relation Model.
    'score': score.toDouble(),
    'level': level.name,
    'state': state.name,
    'sinceTurn': sinceTurn,
    'lastInteractionTurn': lastInteractionTurn,
    if (formalAlliance) 'formalAlliance': formalAlliance,
  };

  static DiplomacyRelation fromJson(Map<String, dynamic> json) =>
      DiplomacyRelation(
        factionId1: json['factionId1'] as String,
        factionId2: json['factionId2'] as String,
        // Decimal migration (SPEC/game/diplomacy.md § Relation Model): legacy
        // saves stored an integer score; load it as a decimal (× 1.0) so all
        // downstream threshold comparisons use the raw decimal value.
        score: (json['score'] as num?)?.toDouble() ?? 50,
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
        formalAlliance: json['formalAlliance'] == true,
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

  /// Voluntarily break an existing formal alliance with a Great Power. Applies
  /// the unified alliance-break penalty. SPEC/game/diplomacy.md § Alliances.
  breakAlliance,
  establishOverture,
  establishFtp,
  grantAid,
  setSubsidy,

  /// Boycott another Great Power on behalf of the issuer's colonies: blocks all
  /// trade between the target GP and every Tribe that is a colony of the issuer
  /// (Refs #3753 R6). SPEC/game/diplomacy.md § GP–Tribe Rules (Boycott).
  boycott,

  /// Remove an active boycott the issuer holds against a Great Power
  /// (Refs #3753 R6). SPEC/game/diplomacy.md § GP–Tribe Rules (Boycott).
  revokeBoycott,
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

/// Debug-console `/set_diplomacy` mutation actions. Debug tool only: maps to a
/// direct `Game`-state diplomacy mutation, bypassing normal turn resolution.
/// SPEC/ui/debug-console-panel.md, SPEC/program/debug-console-internals.md.
enum DebugDiplomacyAction {
  war,
  peace,
  alliance,
  noAlliance,
  consulate,
  embassy,
  nap,
  joinEmpire,
  clearOverture,
  ftp,
  noFtp,
}

/// Command-keyword binding for [DebugDiplomacyAction] (`/set_diplomacy`).
extension DebugDiplomacyActionTokens on DebugDiplomacyAction {
  /// Canonical lowercase command keyword (e.g. `no_alliance`, `join_empire`).
  String get keyword => switch (this) {
    DebugDiplomacyAction.war => 'war',
    DebugDiplomacyAction.peace => 'peace',
    DebugDiplomacyAction.alliance => 'alliance',
    DebugDiplomacyAction.noAlliance => 'no_alliance',
    DebugDiplomacyAction.consulate => 'consulate',
    DebugDiplomacyAction.embassy => 'embassy',
    DebugDiplomacyAction.nap => 'nap',
    DebugDiplomacyAction.joinEmpire => 'join_empire',
    DebugDiplomacyAction.clearOverture => 'clear_overture',
    DebugDiplomacyAction.ftp => 'ftp',
    DebugDiplomacyAction.noFtp => 'no_ftp',
  };

  /// Resolves a case-insensitive command keyword to its action, or `null`.
  static DebugDiplomacyAction? fromKeyword(String input) {
    final normalized = input.trim().toLowerCase();
    for (final action in DebugDiplomacyAction.values) {
      if (action.keyword == normalized) {
        return action;
      }
    }
    return null;
  }

  /// All supported keywords in stable ascending order (for `/help`).
  static List<String> get sortedKeywords =>
      DebugDiplomacyAction.values.map((a) => a.keyword).toList()..sort();
}

/// Subsidy percentage model (Refs #3753 R3). A subsidy is expressed as a whole
/// percentage in 5-point increments, from [kSubsidyPercentMin] (5%) to
/// [kSubsidyPercentMax] (20%). The legacy £/turn (`amountPerTurn`) model is
/// dropped: subsidies no longer charge a per-turn treasury payment; their
/// effect is a world-market price discount/surcharge plus a scaled trade-deal
/// relation boost. SPEC/game/diplomacy.md § Diplomatic Order Types.
const int kSubsidyPercentMin = 5;

/// Maximum subsidy percentage (Refs #3753 R3).
const int kSubsidyPercentMax = 20;

/// Subsidy percentage step / increment (Refs #3753 R3).
const int kSubsidyPercentStep = 5;

/// Default subsidy percentage used by the UI stepper and AI suggestion
/// (Refs #3753 R3) — the minimum, 5%.
const int kSubsidyPercentDefault = kSubsidyPercentMin;

/// True when [percent] is a valid subsidy percentage: within
/// `[kSubsidyPercentMin, kSubsidyPercentMax]` and a multiple of
/// [kSubsidyPercentStep]. SPEC/game/diplomacy.md § Diplomatic Order Types.
bool isValidSubsidyPercent(int percent) =>
    percent >= kSubsidyPercentMin &&
    percent <= kSubsidyPercentMax &&
    percent % kSubsidyPercentStep == 0;

/// Ongoing percentage subsidy from a Great Power to a Minor/Tribe.
/// SPEC/game/diplomacy.md § Diplomatic Order Types (Refs #3753 R3). Subsidies
/// only exist from a GP to a Minor or Tribe (no GP→GP subsidies); see the
/// save-load migration in `Game.fromJson`.
class SubsidyState {
  const SubsidyState({
    required this.payerId,
    required this.targetId,
    required this.percent,
  });

  final String payerId;
  final String targetId;

  /// Subsidy percentage (5–20, step 5). SPEC/game/diplomacy.md § Diplomatic
  /// Order Types (Refs #3753 R3).
  final int percent;

  SubsidyState copyWith({
    String? payerId,
    String? targetId,
    int? percent,
  }) => SubsidyState(
    payerId: payerId ?? this.payerId,
    targetId: targetId ?? this.targetId,
    percent: percent ?? this.percent,
  );

  Map<String, dynamic> toJson() => {
    'payerId': payerId,
    'targetId': targetId,
    'percent': percent,
  };

  /// Parses a [SubsidyState]. Legacy saves storing only the £/turn
  /// `amountPerTurn` field (no `percent`) decode to `percent = 0`, which the
  /// `Game.fromJson` migration drops (Refs #3753 R3 — old subsidies are cleared
  /// on load; the player re-establishes them under the percent model).
  static SubsidyState fromJson(Map<String, dynamic> json) => SubsidyState(
    payerId: json['payerId'] as String,
    targetId: json['targetId'] as String,
    percent: (json['percent'] as num?)?.toInt() ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubsidyState &&
          payerId == other.payerId &&
          targetId == other.targetId &&
          percent == other.percent;

  @override
  int get hashCode => Object.hash(payerId, targetId, percent);
}

/// Records that a Tribe has become a colony of a Great Power via a Tribe
/// `Join Empire` overture. Unlike Minor absorption, the colony Tribe remains in
/// the game (still listed under `Game.tribes`, provinces/fleets not transferred).
/// SPEC/game/diplomacy.md § GP–Minor/Tribe Rules (Join Empire → colony).
class ColonyState {
  const ColonyState({
    required this.tribeId,
    required this.colonyOfGpId,
    required this.sinceTurn,
  });

  /// Tribe faction id that is now a colony.
  final String tribeId;

  /// Great Power id that owns the colony (the Tribe's suzerain).
  final String colonyOfGpId;

  /// Turn the colony relationship was established.
  final int sinceTurn;

  ColonyState copyWith({
    String? tribeId,
    String? colonyOfGpId,
    int? sinceTurn,
  }) => ColonyState(
    tribeId: tribeId ?? this.tribeId,
    colonyOfGpId: colonyOfGpId ?? this.colonyOfGpId,
    sinceTurn: sinceTurn ?? this.sinceTurn,
  );

  Map<String, dynamic> toJson() => {
    'tribeId': tribeId,
    'colonyOfGpId': colonyOfGpId,
    'sinceTurn': sinceTurn,
  };

  static ColonyState fromJson(Map<String, dynamic> json) => ColonyState(
    tribeId: json['tribeId'] as String,
    colonyOfGpId: json['colonyOfGpId'] as String,
    sinceTurn: json['sinceTurn'] as int? ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColonyState &&
          tribeId == other.tribeId &&
          colonyOfGpId == other.colonyOfGpId &&
          sinceTurn == other.sinceTurn;

  @override
  int get hashCode => Object.hash(tribeId, colonyOfGpId, sinceTurn);
}

/// Active boycott of a Great Power by a colony-holding Great Power
/// (Refs #3753 R6). While present, all trade between [targetGpId] and every
/// Tribe that is a colony of [gpId] is blocked. Keyed by the `(gpId,
/// targetGpId)` pair (one active record per pair); the affected colony set is
/// derived from `Game.colonyStates` at enforcement time. SPEC/game/diplomacy.md
/// § GP–Tribe Rules (Boycott).
class BoycottState {
  const BoycottState({
    required this.gpId,
    required this.targetGpId,
    required this.sinceTurn,
  });

  /// Great Power that issued the boycott (must hold at least one colony).
  final String gpId;

  /// Great Power being boycotted (trade blocked with [gpId]'s colonies).
  final String targetGpId;

  /// Turn the boycott was established.
  final int sinceTurn;

  BoycottState copyWith({
    String? gpId,
    String? targetGpId,
    int? sinceTurn,
  }) => BoycottState(
    gpId: gpId ?? this.gpId,
    targetGpId: targetGpId ?? this.targetGpId,
    sinceTurn: sinceTurn ?? this.sinceTurn,
  );

  Map<String, dynamic> toJson() => {
    'gpId': gpId,
    'targetGpId': targetGpId,
    'sinceTurn': sinceTurn,
  };

  static BoycottState fromJson(Map<String, dynamic> json) => BoycottState(
    gpId: json['gpId'] as String,
    targetGpId: json['targetGpId'] as String,
    sinceTurn: json['sinceTurn'] as int? ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoycottState &&
          gpId == other.gpId &&
          targetGpId == other.targetGpId &&
          sinceTurn == other.sinceTurn;

  @override
  int get hashCode => Object.hash(gpId, targetGpId, sinceTurn);
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
