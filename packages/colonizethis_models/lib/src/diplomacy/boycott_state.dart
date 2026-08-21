/// Active boycott state between Great Powers.
/// SPEC/game/diplomacy.md (Refs #3753, #4571).

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
