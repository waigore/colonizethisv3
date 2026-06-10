/// Funding level for research per slot. Maps to treasury cost and research
/// points per turn. SPEC/program/research-resolution.md
enum ResearchFundingLevel { none, low, medium, high, maximum }

/// Per-slot research assignment. Phase 5.
class ResearchOrder {
  const ResearchOrder({
    required this.slotIndex,
    required this.techId,
    required this.funding,
  });

  /// Zero-based slot index (0..N-1).
  final int slotIndex;

  /// Tech id to research in this slot. Empty string = cancel slot.
  final String techId;

  /// Funding level for this slot.
  final ResearchFundingLevel funding;

  Map<String, dynamic> toJson() => {
    'slotIndex': slotIndex,
    'techId': techId,
    'funding': funding.name,
  };

  static ResearchOrder fromJson(Map<String, dynamic> json) {
    final fundingRaw =
        json['funding'] as String? ?? ResearchFundingLevel.none.name;
    final funding = ResearchFundingLevel.values.firstWhere(
      (e) => e.name == fundingRaw,
      orElse: () => ResearchFundingLevel.none,
    );
    return ResearchOrder(
      slotIndex: (json['slotIndex'] as num).toInt(),
      techId: json['techId'] as String? ?? '',
      funding: funding,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResearchOrder &&
          runtimeType == other.runtimeType &&
          slotIndex == other.slotIndex &&
          techId == other.techId &&
          funding == other.funding;

  @override
  int get hashCode => Object.hash(slotIndex, techId, funding);
}
