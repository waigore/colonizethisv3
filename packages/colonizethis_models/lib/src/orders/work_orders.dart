/// Order a unit to work (explore, build improvement, prospect).
/// Applies to civilian units only. SPEC/program/orders.md
class WorkOrder {
  const WorkOrder({
    required this.unitId,
    required this.target,
    required this.targetTileKey,
  });

  final String unitId;
  final String target;

  /// Tile key for the work target (format regionId|provinceId|x|y). For province-level actions (e.g. explore) a synthetic key may be used.
  final String targetTileKey;

  Map<String, dynamic> toJson() => {
    'unitId': unitId,
    'target': target,
    'targetTileKey': targetTileKey,
  };

  static WorkOrder fromJson(Map<String, dynamic> json) {
    return WorkOrder(
      unitId: json['unitId'] as String,
      target: json['target'] as String,
      targetTileKey: json['targetTileKey'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkOrder &&
          runtimeType == other.runtimeType &&
          unitId == other.unitId &&
          target == other.target &&
          targetTileKey == other.targetTileKey;

  @override
  int get hashCode => Object.hash(unitId, target, targetTileKey);
}
