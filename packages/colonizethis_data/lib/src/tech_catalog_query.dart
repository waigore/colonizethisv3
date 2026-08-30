/// Catalog query helpers over [techCatalog]. SPEC/game/tech-tree.md,
/// SPEC/game/research-state.md, SPEC/ui/tech-tree-widget.md.

import 'tech_catalog.dart';
import 'tech_definition.dart';

/// Full tech catalog (113 techs). Built from [buildTechCatalog].
final Map<String, TechDefinition> techCatalog = buildTechCatalog();

/// All tech ids (same for every player). Order = catalog insertion order.
final List<String> techIds = techCatalog.keys.toList();

TechDefinition? techById(String id) => techCatalog[id];

/// Humanized display name for a tech id. Uses catalog displayName when set; otherwise
/// title-case of id (e.g. road_construction → "Road Construction"). SPEC/ui/tech-tree-widget.md.
String techDisplayName(String id) {
  if (id.isEmpty) return id;
  final def = techCatalog[id];
  if (def?.displayName != null && def!.displayName!.isNotEmpty) {
    return def.displayName!;
  }
  return id
      .split('_')
      .map(
        (s) => s.isEmpty
            ? s
            : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}',
      )
      .join(' ');
}

/// Tech ids that the player can research next (all prerequisites in [techUnlocked], tech not yet unlocked).
/// When [hasDiscoveredResource] is null, discovery techs are treated as researchable (tests/contexts without game).
/// When provided, techs with [TechDefinition.discoveryResourceIds] are included only if
/// [hasDiscoveredResource](r) is true for at least one r in that list. SPEC/game/research-state.md.
Set<String> researchableTechIds(
  Map<String, bool>? techUnlocked, {
  bool Function(String resourceId)? hasDiscoveredResource,
}) {
  final unlocked = techUnlocked ?? const {};
  final result = <String>{};
  for (final tech in techCatalog.values) {
    if (unlocked[tech.id] == true) continue;
    final allPrereqsMet = tech.prerequisiteIds.every(
      (p) => unlocked[p] == true,
    );
    if (!allPrereqsMet) continue;
    final discoveryIds = tech.discoveryResourceIds;
    if (discoveryIds != null && discoveryIds.isNotEmpty) {
      if (hasDiscoveredResource == null) {
        result.add(tech.id);
        continue;
      }
      final anyDiscovered = discoveryIds.any((r) => hasDiscoveredResource(r));
      if (anyDiscovered) result.add(tech.id);
    } else {
      result.add(tech.id);
    }
  }
  return result;
}
