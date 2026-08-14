/// Named information-layer flags for the empire map.
///
/// Paint predicates and the stacked-layers cycle use these flags as the
/// single source of truth (Refs #4388). Roads never paint without
/// improvements (`paintsRoads`).
class MapBaseLayerFlags {
  const MapBaseLayerFlags({
    required this.showResources,
    required this.showImprovements,
    required this.showRoads,
  });

  static const MapBaseLayerFlags terrainOnly = MapBaseLayerFlags(
    showResources: false,
    showImprovements: false,
    showRoads: false,
  );

  static const MapBaseLayerFlags resourcesOnly = MapBaseLayerFlags(
    showResources: true,
    showImprovements: false,
    showRoads: false,
  );

  static const MapBaseLayerFlags resourcesAndImprovements = MapBaseLayerFlags(
    showResources: true,
    showImprovements: true,
    showRoads: false,
  );

  static const MapBaseLayerFlags fullDetail = MapBaseLayerFlags(
    showResources: true,
    showImprovements: true,
    showRoads: true,
  );

  final bool showResources;
  final bool showImprovements;
  final bool showRoads;

  /// Road/rail sprites paint only when both flags are on.
  bool get paintsRoads => showRoads && showImprovements;

  bool get isCyclePreset =>
      this == terrainOnly ||
      this == resourcesOnly ||
      this == resourcesAndImprovements ||
      this == fullDetail;

  /// Four-preset cycle; non-preset dialog combinations jump to terrain-only.
  MapBaseLayerFlags get cycled {
    if (this == terrainOnly) return resourcesOnly;
    if (this == resourcesOnly) return resourcesAndImprovements;
    if (this == resourcesAndImprovements) return fullDetail;
    if (this == fullDetail) return terrainOnly;
    return terrainOnly;
  }

  /// Player-facing combination for tooltip/semantics (roads follow [paintsRoads]).
  MapMarksCombination get combination {
    final roads = paintsRoads;
    if (!showResources && !showImprovements) {
      return MapMarksCombination.terrainOnly;
    }
    if (showResources && !showImprovements) {
      return MapMarksCombination.resources;
    }
    if (showResources && showImprovements && !roads) {
      return MapMarksCombination.resourcesAndImprovements;
    }
    if (showResources && showImprovements && roads) {
      return MapMarksCombination.fullDetail;
    }
    if (!showResources && showImprovements && !roads) {
      return MapMarksCombination.improvements;
    }
    return MapMarksCombination.improvementsAndRoads;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapBaseLayerFlags &&
          showResources == other.showResources &&
          showImprovements == other.showImprovements &&
          showRoads == other.showRoads;

  @override
  int get hashCode => Object.hash(showResources, showImprovements, showRoads);
}

/// Tooltip/semantics combination names for [MapBaseLayerFlags].
enum MapMarksCombination {
  terrainOnly,
  resources,
  resourcesAndImprovements,
  fullDetail,
  improvements,
  improvementsAndRoads,
}
