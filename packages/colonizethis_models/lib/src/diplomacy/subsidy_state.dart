/// Subsidy percentage constants, validation, and [SubsidyState].
/// SPEC/game/diplomacy.md (Refs #3753, #3811, #4571).

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
