import 'orders.dart' show ResearchFundingLevel;

/// Persisted occupancy of a single research slot.
///
/// Durable record of which tech occupies a slot and at which
/// [ResearchFundingLevel]. Distinct from the per-turn
/// `Orders.researchOrdersByPlayerId` (the transient UI mutation surface): the
/// resolver persists surviving slot assignments back onto
/// `Player.researchSlotAssignments` so an in-progress tech keeps its slot
/// across turns and save/load. SPEC/game/research-state.md § Slot Occupancy
/// Persistence.
class ResearchSlotAssignment {
  const ResearchSlotAssignment({
    required this.techId,
    this.funding = ResearchFundingLevel.none,
  });

  /// Tech id occupying the slot. Empty is treated as an invalid assignment by
  /// [Player] deserialization and dropped.
  final String techId;

  /// Funding level applied to this slot. Persists until changed or cancelled.
  final ResearchFundingLevel funding;

  Map<String, dynamic> toJson() => {'techId': techId, 'funding': funding.name};

  /// Builds a [ResearchSlotAssignment] from [json]. Missing/unknown `funding`
  /// defaults to [ResearchFundingLevel.none]; missing `techId` becomes an empty
  /// string (callers drop empty-tech assignments).
  static ResearchSlotAssignment fromJson(Map<String, dynamic> json) {
    final fundingRaw =
        json['funding'] as String? ?? ResearchFundingLevel.none.name;
    final funding = ResearchFundingLevel.values.firstWhere(
      (e) => e.name == fundingRaw,
      orElse: () => ResearchFundingLevel.none,
    );
    return ResearchSlotAssignment(
      techId: json['techId'] as String? ?? '',
      funding: funding,
    );
  }

  ResearchSlotAssignment copyWith({
    String? techId,
    ResearchFundingLevel? funding,
  }) {
    return ResearchSlotAssignment(
      techId: techId ?? this.techId,
      funding: funding ?? this.funding,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResearchSlotAssignment &&
          runtimeType == other.runtimeType &&
          techId == other.techId &&
          funding == other.funding;

  @override
  int get hashCode => Object.hash(techId, funding);
}
