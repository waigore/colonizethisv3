/// Overture stage models. SPEC/game/diplomacy.md.
///
/// Concern split from former monolithic `diplomacy.dart` (Refs #4068).

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
