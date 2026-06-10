import '../model_validation_exception.dart';
import '../province_id.dart';
import '../worker_tier.dart';

/// Build a new unit for a player.
/// SPEC/program/orders.md
class BuildUnitOrder {
  const BuildUnitOrder({
    required this.unitType,
    required this.isMilitary,
    required this.spawnProvinceId,
  });

  final String unitType;
  final bool isMilitary;
  final String spawnProvinceId;

  Map<String, dynamic> toJson() => {
    'unitType': unitType,
    'isMilitary': isMilitary,
    'spawnProvinceId': spawnProvinceId,
  };

  static BuildUnitOrder fromJson(Map<String, dynamic> json) {
    final spawnProvinceId = ProvinceId.requirePrefixed(
      json['spawnProvinceId'] as String,
      fieldName: 'BuildUnitOrder.spawnProvinceId',
    );
    return BuildUnitOrder(
      unitType: json['unitType'] as String,
      isMilitary: json['isMilitary'] as bool? ?? false,
      spawnProvinceId: spawnProvinceId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BuildUnitOrder &&
          runtimeType == other.runtimeType &&
          unitType == other.unitType &&
          isMilitary == other.isMilitary &&
          spawnProvinceId == other.spawnProvinceId;

  @override
  int get hashCode => Object.hash(unitType, isMilitary, spawnProvinceId);
}

/// Recruit or train a worker into the player's WorkerPool.
///
/// One queued order increments the target tier by one. Non-peasant tiers
/// additionally consume one peasant (the "train" mapping per SPEC); UI may
/// expose distinct Recruit and Train controls per tier but both emit this
/// order type.
///
/// Resolved in Build / work (phase 12) before [BuildUnitOrder] per
/// SPEC/program/turn-resolution-phase-details.md § Build / work.
///
/// SPEC/game/workers-and-population.md § Recruiting, Training, and
/// Disbanding (authoritative cost table and rejection vocabulary).
/// SPEC/program/orders.md § Order Types.
class RecruitWorkerOrder {
  const RecruitWorkerOrder({required this.targetTier});

  /// Worker tier to add to the pool.
  final WorkerTier targetTier;

  Map<String, dynamic> toJson() => {'targetTier': targetTier.id};

  static RecruitWorkerOrder fromJson(Map<String, dynamic> json) {
    final raw = json['targetTier'];
    if (raw is! String || raw.isEmpty) {
      throw ModelValidationException(
        'RecruitWorkerOrder requires non-empty targetTier id',
      );
    }
    final tier = WorkerTier.tryFromId(raw);
    if (tier == null) {
      throw ModelValidationException(
        'RecruitWorkerOrder has unknown targetTier id: "$raw"',
      );
    }
    return RecruitWorkerOrder(targetTier: tier);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecruitWorkerOrder &&
          runtimeType == other.runtimeType &&
          targetTier == other.targetTier;

  @override
  int get hashCode => Object.hash(runtimeType, targetTier);
}
