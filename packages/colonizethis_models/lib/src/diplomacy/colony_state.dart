/// Colony relationship state for a Tribe under a Great Power.
/// SPEC/game/diplomacy.md (Refs #3753, #4571).

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
