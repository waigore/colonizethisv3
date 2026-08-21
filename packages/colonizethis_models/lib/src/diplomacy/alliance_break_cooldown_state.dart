/// Bilateral post-break overture cooldown for a Great Power pair.
/// SPEC/game/diplomacy.md (Refs #3811, #4571).

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
