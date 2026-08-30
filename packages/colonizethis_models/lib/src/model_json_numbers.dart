/// Shared JSON number coercion for model `fromJson` helpers (Refs #4571).
///
/// Collapses duplicated local `intOrZero` / `doubleOrZero` closures under
/// `world_market/` into one SoT next to [model_collection_equality].

/// Parses [value] as an int, or `0` when null/unparseable.
int modelJsonIntOrZero(Object? value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

/// Parses [value] as a double, or `0.0` when null/unparseable.
double modelJsonDoubleOrZero(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}
