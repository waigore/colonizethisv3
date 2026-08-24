/// Fully-fed unit count from consumed food vs demand.
///
/// Uses ceiling average demand per unit, then `consumed ~/ avg` clamped to
/// [count]. Shared by land military and navy consumption phases.
int fullyFedCountFromConsumed({
  required int consumed,
  required int totalDemand,
  required int count,
}) {
  if (totalDemand <= 0 || count <= 0) return 0;
  final avgFoodPerUnit = (totalDemand + count - 1) ~/ count;
  if (avgFoodPerUnit <= 0) return 0;
  final fed = consumed ~/ avgFoodPerUnit;
  return fed > count ? count : fed;
}
