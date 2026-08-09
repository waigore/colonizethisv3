/// Node position for tech tree layout. Exposed for tests (column rule:
/// A→B→C and A→C ⇒ gap between A and C).
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
