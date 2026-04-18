/// Tech definition for the catalog. SPEC/game/tech-tree.md.
/// Used by tech_extraction.dart and tech_catalog.dart.

/// Simple tech definition used by the tech catalog.
/// Effects: regimentUnlockIds / shipUnlockIds = unit types this tech unlocks (buildability).
/// displayName: user-facing name for UI; when null, [techDisplayName] derives from id.
/// discoveryResourceIds: when non-null and non-empty, tech is researchable only if player has
/// revealed (and if prospect-required, prospected) at least one tile containing one of these
/// resource ids. SPEC/game/tech-tree-new-world.md.
class TechDefinition {
  const TechDefinition({
    required this.id,
    required this.era,
    required this.category,
    required this.cost,
    this.displayName,
    this.prerequisiteIds = const [],
    this.discoveryResourceIds,
    this.regimentUnlockIds = const [],
    this.shipUnlockIds = const [],
  });

  final String id;
  final int era;
  final String category;
  final int cost;

  /// User-facing display name for UI and tools. When null, [techDisplayName] uses title-case of id.
  final String? displayName;

  final List<String> prerequisiteIds;

  /// When non-null and non-empty, tech is researchable only if player has revealed (and if
  /// prospect-required, prospected) at least one tile containing at least one of these
  /// resource ids. Canonical list per plan; only discovery techs set this.
  final List<String>? discoveryResourceIds;

  /// Regiment ids this tech unlocks. SPEC/game/tech-tree-military.md.
  final List<String> regimentUnlockIds;

  /// Ship type ids this tech unlocks. SPEC/game/tech-tree-naval.md.
  final List<String> shipUnlockIds;
}
