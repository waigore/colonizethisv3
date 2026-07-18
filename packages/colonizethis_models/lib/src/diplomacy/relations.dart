/// Diplomacy relation models. SPEC/game/diplomacy.md, diplomacy-resolution.md.
///
/// Concern split from former monolithic `diplomacy.dart` (Refs #4068).

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
  ///
  /// **War invariant:** `formalAlliance == true` must never coexist with
  /// [RelationState.atWar]. Every transition to war clears this flag, and
  /// [fromJson] normalizes it away for any at-war pair on load.
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

  static DiplomacyRelation fromJson(Map<String, dynamic> json) {
    final state = RelationState.values.firstWhere(
      (e) => e.name == json['state'],
      orElse: () => RelationState.atPeace,
    );
    return DiplomacyRelation(
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
      state: state,
      sinceTurn: json['sinceTurn'] as int? ?? 0,
      lastInteractionTurn: json['lastInteractionTurn'] as int? ?? 0,
      // War invariant (SPEC/game/diplomacy.md § Alliances): a formal alliance
      // can never coexist with war. Drop the flag on load for any at-war pair so
      // an invalid legacy save normalizes to the consistent state.
      formalAlliance:
          json['formalAlliance'] == true && state != RelationState.atWar,
    );
  }
}
