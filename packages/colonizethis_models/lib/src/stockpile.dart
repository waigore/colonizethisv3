/// Centralized commodity storage for a player.
/// SPEC/game/stockpiles-and-production.md
/// SPEC/program/economy-models.md
///
/// Models a national **strategic** resource pool; warehouse logistics are not
/// simulated. Quantities are unbounded (no storage cap) aside from [int] range.
///
/// Map of commodity id → quantity, where [CommodityId] is the canonical string
/// id from `SPEC/game/commodity-catalog.md`.
typedef CommodityId = String;

class Stockpile {
  const Stockpile({this.quantities = const {}});

  /// Commodity quantities keyed by canonical commodity id.
  final Map<CommodityId, int> quantities;

  static const empty = Stockpile();

  /// Returns the quantity for a given [commodityId], or 0 if absent.
  int quantityOf(CommodityId commodityId) => quantities[commodityId] ?? 0;

  /// Returns a fresh **mutable** copy of [quantities].
  ///
  /// Canonical clone for snapshot boundaries that need to mutate the result in
  /// place (e.g. incremental candidate validation deducting work costs). This
  /// is the single sanctioned replacement for the raw
  /// `Map<String, int>.from(stockpile.quantities)` pattern; it deliberately
  /// returns a growable, modifiable map rather than an unmodifiable view.
  Map<CommodityId, int> copyQuantities() => Map<CommodityId, int>.from(quantities);

  /// Returns a new [Stockpile] with [delta] applied for [commodityId].
  ///
  /// Negative deltas are allowed; quantities are clamped at 0.
  Stockpile applyDelta(CommodityId commodityId, int delta) {
    if (delta == 0) return this;
    final current = quantityOf(commodityId);
    final next = current + delta;
    final clamped = next < 0 ? 0 : next;
    if (clamped == current) return this;

    final updated = Map<CommodityId, int>.from(quantities);
    if (clamped == 0) {
      updated.remove(commodityId);
    } else {
      updated[commodityId] = clamped;
    }
    return Stockpile(quantities: updated);
  }

  /// Returns a new [Stockpile] with [other] merged in (summing quantities).
  Stockpile merge(Stockpile other) {
    if (other.quantities.isEmpty) return this;
    if (quantities.isEmpty) return other;
    final merged = Map<CommodityId, int>.from(quantities);
    for (final entry in other.quantities.entries) {
      final current = merged[entry.key] ?? 0;
      merged[entry.key] = current + entry.value;
    }
    return Stockpile(quantities: merged);
  }

  Map<String, dynamic> toJson() => {'quantities': quantities};

  static Stockpile fromJson(Map<String, dynamic> json) {
    final raw = json['quantities'];
    if (raw is! Map<dynamic, dynamic>) {
      return const Stockpile();
    }
    final map = <CommodityId, int>{};
    raw.forEach((key, value) {
      final id = key.toString();
      final qty = value is int ? value : int.tryParse(value.toString()) ?? 0;
      if (qty > 0) {
        map[id] = qty;
      }
    });
    return Stockpile(quantities: Map.unmodifiable(map));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Stockpile &&
          runtimeType == other.runtimeType &&
          _mapEquals(quantities, other.quantities);

  @override
  int get hashCode => Object.hashAll(
    quantities.entries
        .map((e) => Object.hash(e.key, e.value))
        .toList(growable: false),
  );

  static bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}
