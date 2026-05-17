/// Proportional per-continent budget from province counts. Refs #2489 (D13).

/// Allocates [totalBudget] across continents proportional to province counts in
/// [provincesByContinent]. Rounding remainder is applied to continent 0; if
/// rounding overshoots [totalBudget], continent 0 is reduced.
List<int> allocateBudgetByProvinceCount({
  required int totalBudget,
  required Map<int, List<String>> provincesByContinent,
  required int numContinents,
}) {
  if (numContinents <= 0) return const [];
  final totalProvinces = provincesByContinent.values.fold<int>(
    0,
    (sum, list) => sum + list.length,
  );
  if (totalProvinces == 0) {
    return List.filled(numContinents, 0);
  }
  final budget = List<int>.filled(numContinents, 0);
  var allocated = 0;
  for (var c = 0; c < numContinents; c++) {
    final pc = provincesByContinent[c]!.length;
    budget[c] = (totalBudget * pc / totalProvinces).round();
    allocated += budget[c];
  }
  if (allocated > totalBudget) {
    budget[0] -= allocated - totalBudget;
  } else if (allocated < totalBudget) {
    budget[0] += totalBudget - allocated;
  }
  return budget;
}
