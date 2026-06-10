part of '../orders.dart';

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

/// Funding level for research per slot. Maps to treasury cost and research
/// points per turn. SPEC/program/research-resolution.md
enum ResearchFundingLevel { none, low, medium, high, maximum }

/// Per-slot research assignment. Phase 5.
class ResearchOrder {
  const ResearchOrder({
    required this.slotIndex,
    required this.techId,
    required this.funding,
  });

  /// Zero-based slot index (0..N-1).
  final int slotIndex;

  /// Tech id to research in this slot. Empty string = cancel slot.
  final String techId;

  /// Funding level for this slot.
  final ResearchFundingLevel funding;

  Map<String, dynamic> toJson() => {
    'slotIndex': slotIndex,
    'techId': techId,
    'funding': funding.name,
  };

  static ResearchOrder fromJson(Map<String, dynamic> json) {
    final fundingRaw =
        json['funding'] as String? ?? ResearchFundingLevel.none.name;
    final funding = ResearchFundingLevel.values.firstWhere(
      (e) => e.name == fundingRaw,
      orElse: () => ResearchFundingLevel.none,
    );
    return ResearchOrder(
      slotIndex: (json['slotIndex'] as num).toInt(),
      techId: json['techId'] as String? ?? '',
      funding: funding,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResearchOrder &&
          runtimeType == other.runtimeType &&
          slotIndex == other.slotIndex &&
          techId == other.techId &&
          funding == other.funding;

  @override
  int get hashCode => Object.hash(slotIndex, techId, funding);
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
