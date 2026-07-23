// Shared models for [TechTreeWidget] graph layout and node state.
// De-parted wave-9 cluster (Refs #4117).

/// Node position for layout. Exposed for tests (column rule: A→B→C and A→C ⇒
/// gap between A and C).
class TechNodePosition {
  const TechNodePosition({
    required this.techId,
    required this.x,
    required this.y,
    required this.layer,
  });

  final String techId;
  final double x;
  final double y;
  final int layer;
}

/// Visual state for a single tech-tree node.
class TechNodeState {
  const TechNodeState({
    required this.researched,
    required this.inProgress,
    required this.available,
  });

  final bool researched;
  final bool inProgress;
  final bool available;
}
