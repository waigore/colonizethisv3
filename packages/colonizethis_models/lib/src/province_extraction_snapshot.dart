/// Last-turn province Extraction display snapshot. Refs #4002.
///
/// SPEC: SPEC/program/province-extraction-snapshot.md
library;

/// Per-commodity totals for one province's last Extraction-phase snapshot.
class ProvinceExtractionCommodityTotals {
  const ProvinceExtractionCommodityTotals({
    required this.effective,
    required this.full,
    this.tileKeys = const [],
  });

  /// Applied extraction units attributed to the province for this commodity.
  final int effective;

  /// Production sum (transport/town caps not applied) for contributing tiles.
  /// Capital grain bonus uses full == effective.
  final int full;

  /// Deterministically ordered tile keys that contributed to full or effective.
  final List<String> tileKeys;

  Map<String, dynamic> toJson() => {
    'effective': effective,
    'full': full,
    if (tileKeys.isNotEmpty) 'tileKeys': tileKeys,
  };

  static ProvinceExtractionCommodityTotals fromJson(Map<String, dynamic> json) {
    final keysRaw = json['tileKeys'];
    final tileKeys = keysRaw is List<Object?>
        ? keysRaw.map((e) => e.toString()).toList()
        : const <String>[];
    return ProvinceExtractionCommodityTotals(
      effective: (json['effective'] as num?)?.toInt() ?? 0,
      full: (json['full'] as num?)?.toInt() ?? 0,
      tileKeys: tileKeys,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProvinceExtractionCommodityTotals &&
          effective == other.effective &&
          full == other.full &&
          _listEquals(tileKeys, other.tileKeys);

  @override
  int get hashCode => Object.hash(effective, full, Object.hashAll(tileKeys));

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Last-turn Extraction snapshot for one province.
class ProvinceExtractionSnapshot {
  const ProvinceExtractionSnapshot({
    required this.ownerId,
    this.byCommodity = const {},
  });

  /// Province owner id at snapshot write time.
  final String ownerId;

  /// Commodity id → totals.
  final Map<String, ProvinceExtractionCommodityTotals> byCommodity;

  Map<String, dynamic> toJson() => {
    'ownerId': ownerId,
    'byCommodity': {
      for (final e in byCommodity.entries) e.key: e.value.toJson(),
    },
  };

  static ProvinceExtractionSnapshot fromJson(Map<String, dynamic> json) {
    final byRaw = json['byCommodity'];
    final byCommodity = <String, ProvinceExtractionCommodityTotals>{};
    if (byRaw is Map<Object?, Object?>) {
      byRaw.forEach((key, value) {
        if (value is Map<Object?, Object?>) {
          byCommodity[key
              .toString()] = ProvinceExtractionCommodityTotals.fromJson(
            Map<String, dynamic>.from(value),
          );
        }
      });
    }
    return ProvinceExtractionSnapshot(
      ownerId: json['ownerId']?.toString() ?? '',
      byCommodity: byCommodity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProvinceExtractionSnapshot &&
          ownerId == other.ownerId &&
          _mapEquals(byCommodity, other.byCommodity);

  @override
  int get hashCode => Object.hash(
    ownerId,
    Object.hashAll(byCommodity.entries.map((e) => Object.hash(e.key, e.value))),
  );

  static bool _mapEquals(
    Map<String, ProvinceExtractionCommodityTotals> a,
    Map<String, ProvinceExtractionCommodityTotals> b,
  ) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}

/// Returns [snapshot] only when [currentOwnerId] matches [snapshot.ownerId].
ProvinceExtractionSnapshot? provinceExtractionSnapshotForDisplay({
  required ProvinceExtractionSnapshot? snapshot,
  required String? currentOwnerId,
}) {
  if (snapshot == null || currentOwnerId == null) return null;
  if (snapshot.ownerId != currentOwnerId) return null;
  return snapshot;
}
