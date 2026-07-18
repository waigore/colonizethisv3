/// Subsidy, colony, alliance-break cooldown, and boycott state models.
/// SPEC/game/diplomacy.md (Refs #3753, #3811).
///
/// Concern split from former monolithic `diplomacy.dart` (Refs #4068).

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

  SubsidyState copyWith({String? payerId, String? targetId, int? percent}) =>
      SubsidyState(
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

/// Bilateral post-break overture cooldown for a Great Power pair (Refs #3811).
///
/// Recorded when a voluntary alliance break resolves; active only while
/// `sinceTurn == currentTurn`. Clears from turn `T+1` onward. Both directions
/// of the pair are blocked from initiating overture-class diplomatic orders.
/// SPEC/game/diplomacy.md § Alliances; SPEC/program/orders.md.
class AllianceBreakCooldownState {
  const AllianceBreakCooldownState({
    required this.factionId1,
    required this.factionId2,
    required this.sinceTurn,
  });

  /// Canonical sorted faction ids for the pair (`factionId1` ≤ `factionId2`).
  final String factionId1;
  final String factionId2;

  /// Turn the voluntary break occurred (cooldown active for this turn only).
  final int sinceTurn;

  AllianceBreakCooldownState copyWith({
    String? factionId1,
    String? factionId2,
    int? sinceTurn,
  }) => AllianceBreakCooldownState(
    factionId1: factionId1 ?? this.factionId1,
    factionId2: factionId2 ?? this.factionId2,
    sinceTurn: sinceTurn ?? this.sinceTurn,
  );

  Map<String, dynamic> toJson() => {
    'factionId1': factionId1,
    'factionId2': factionId2,
    'sinceTurn': sinceTurn,
  };

  static AllianceBreakCooldownState fromJson(Map<String, dynamic> json) =>
      AllianceBreakCooldownState(
        factionId1: json['factionId1'] as String,
        factionId2: json['factionId2'] as String,
        sinceTurn: json['sinceTurn'] as int? ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AllianceBreakCooldownState &&
          factionId1 == other.factionId1 &&
          factionId2 == other.factionId2 &&
          sinceTurn == other.sinceTurn;

  @override
  int get hashCode => Object.hash(factionId1, factionId2, sinceTurn);
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

  BoycottState copyWith({String? gpId, String? targetGpId, int? sinceTurn}) =>
      BoycottState(
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
