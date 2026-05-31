import 'diplomacy.dart';
import 'model_validation_exception.dart';
import 'province_id.dart';
import 'worker_tier.dart';
import 'world_market.dart';

/// Per-player orders for the current turn.
/// SPEC/game/world-model.
/// SPEC/program/orders.md
class Orders {
  const Orders({
    this.moveOrdersByPlayerId = const {},
    this.armyMoveOrdersByPlayerId = const {},
    this.buildUnitOrdersByPlayerId = const {},
    this.workOrdersByPlayerId = const {},
    this.recruitWorkerOrdersByPlayerId = const {},
    this.diplomaticOrdersByPlayerId = const {},
    this.researchOrdersByPlayerId = const {},
    this.navalMoveOrdersByPlayerId = const {},
    this.navalMissionOrdersByPlayerId = const {},
    this.tradeOrdersByPlayerId = const {},
  });

  /// Player id -> list of move orders.
  final Map<String, List<MoveOrder>> moveOrdersByPlayerId;

  /// Player id -> land army move orders. SPEC/game/military-armies.md.
  final Map<String, List<ArmyMoveOrder>> armyMoveOrdersByPlayerId;

  /// Player id -> list of build-unit orders.
  final Map<String, List<BuildUnitOrder>> buildUnitOrdersByPlayerId;

  /// Player id -> list of work orders.
  final Map<String, List<WorkOrder>> workOrdersByPlayerId;

  /// Player id -> list of worker recruit / train orders.
  ///
  /// Single order type per SPEC/game/workers-and-population.md §
  /// Recruiting, Training, and Disbanding: the UI may surface "Recruit" and
  /// "Train" as separate controls but both emit a [RecruitWorkerOrder] with
  /// `targetTier` set. Applied in Build / work (phase 12) before
  /// [BuildUnitOrder].
  final Map<String, List<RecruitWorkerOrder>> recruitWorkerOrdersByPlayerId;

  /// Player id -> list of diplomatic orders. Phase 4.
  final Map<String, List<DiplomaticOrder>> diplomaticOrdersByPlayerId;

  /// Player id -> list of research orders. Phase 5.
  final Map<String, List<ResearchOrder>> researchOrdersByPlayerId;

  /// Player id -> list of naval move orders. Phase 5. SPEC/program/naval-movement-resolution.md.
  final Map<String, List<NavalMoveOrder>> navalMoveOrdersByPlayerId;

  /// Player id -> list of naval mission orders. Phase 6.
  final Map<String, List<NavalMissionOrder>> navalMissionOrdersByPlayerId;

  /// Player id -> list of world-market trade orders (bids and offers).
  /// Resolved in Phase 13 World Market. SPEC/program/world-market-resolution.md,
  /// SPEC/game/world-market.md.
  final Map<String, List<TradeOrder>> tradeOrdersByPlayerId;

  Map<String, dynamic> toJson() => {
    'moveOrdersByPlayerId': moveOrdersByPlayerId.map(
      (playerId, orders) =>
          MapEntry(playerId, orders.map((o) => o.toJson()).toList()),
    ),
    if (armyMoveOrdersByPlayerId.isNotEmpty)
      'armyMoveOrdersByPlayerId': armyMoveOrdersByPlayerId.map(
        (playerId, orders) =>
            MapEntry(playerId, orders.map((o) => o.toJson()).toList()),
      ),
    'buildUnitOrdersByPlayerId': buildUnitOrdersByPlayerId.map(
      (playerId, orders) =>
          MapEntry(playerId, orders.map((o) => o.toJson()).toList()),
    ),
    'workOrdersByPlayerId': workOrdersByPlayerId.map(
      (playerId, orders) =>
          MapEntry(playerId, orders.map((o) => o.toJson()).toList()),
    ),
    if (diplomaticOrdersByPlayerId.isNotEmpty)
      'diplomaticOrdersByPlayerId': diplomaticOrdersByPlayerId.map(
        (playerId, orders) =>
            MapEntry(playerId, orders.map((o) => o.toJson()).toList()),
      ),
    if (researchOrdersByPlayerId.isNotEmpty)
      'researchOrdersByPlayerId': researchOrdersByPlayerId.map(
        (playerId, orders) =>
            MapEntry(playerId, orders.map((o) => o.toJson()).toList()),
      ),
    if (navalMoveOrdersByPlayerId.isNotEmpty)
      'navalMoveOrdersByPlayerId': navalMoveOrdersByPlayerId.map(
        (playerId, orders) =>
            MapEntry(playerId, orders.map((o) => o.toJson()).toList()),
      ),
    if (navalMissionOrdersByPlayerId.isNotEmpty)
      'navalMissionOrdersByPlayerId': navalMissionOrdersByPlayerId.map(
        (playerId, orders) =>
            MapEntry(playerId, orders.map((o) => o.toJson()).toList()),
      ),
    if (recruitWorkerOrdersByPlayerId.isNotEmpty)
      'recruitWorkerOrdersByPlayerId': recruitWorkerOrdersByPlayerId.map(
        (playerId, orders) =>
            MapEntry(playerId, orders.map((o) => o.toJson()).toList()),
      ),
    if (tradeOrdersByPlayerId.isNotEmpty)
      'tradeOrdersByPlayerId': tradeOrdersByPlayerId.map(
        (playerId, orders) =>
            MapEntry(playerId, orders.map((o) => o.toJson()).toList()),
      ),
  };

  static Orders fromJson(Map<String, dynamic> json) {
    final moveRaw =
        json['moveOrdersByPlayerId'] as Map<dynamic, dynamic>? ?? {};
    final moveByPlayerId = <String, List<MoveOrder>>{};
    moveRaw.forEach((key, value) {
      final playerId = key.toString();
      final list = (value as List<dynamic>? ?? [])
          .map(
            (e) => MoveOrder.fromJson(
              Map<String, dynamic>.from(e as Map<Object?, Object?>),
            ),
          )
          .toList();
      moveByPlayerId[playerId] = list;
    });

    final armyMoveRaw =
        json['armyMoveOrdersByPlayerId'] as Map<dynamic, dynamic>? ?? {};
    final armyMoveByPlayerId = <String, List<ArmyMoveOrder>>{};
    armyMoveRaw.forEach((key, value) {
      final playerId = key.toString();
      final list = (value as List<dynamic>? ?? [])
          .map(
            (e) => ArmyMoveOrder.fromJson(
              Map<String, dynamic>.from(e as Map<Object?, Object?>),
            ),
          )
          .toList();
      armyMoveByPlayerId[playerId] = list;
    });

    final buildRaw =
        json['buildUnitOrdersByPlayerId'] as Map<dynamic, dynamic>? ?? {};
    final buildByPlayerId = <String, List<BuildUnitOrder>>{};
    buildRaw.forEach((key, value) {
      final playerId = key.toString();
      final list = (value as List<dynamic>? ?? [])
          .map(
            (e) => BuildUnitOrder.fromJson(
              Map<String, dynamic>.from(e as Map<Object?, Object?>),
            ),
          )
          .toList();
      buildByPlayerId[playerId] = list;
    });

    final workRaw =
        json['workOrdersByPlayerId'] as Map<dynamic, dynamic>? ?? {};
    final workByPlayerId = <String, List<WorkOrder>>{};
    workRaw.forEach((key, value) {
      final playerId = key.toString();
      final list = (value as List<dynamic>? ?? [])
          .map(
            (e) => WorkOrder.fromJson(
              Map<String, dynamic>.from(e as Map<Object?, Object?>),
            ),
          )
          .toList();
      workByPlayerId[playerId] = list;
    });

    final diploRaw =
        json['diplomaticOrdersByPlayerId'] as Map<dynamic, dynamic>? ?? {};
    final diploByPlayerId = <String, List<DiplomaticOrder>>{};
    diploRaw.forEach((key, value) {
      final playerId = key.toString();
      final list = (value as List<dynamic>? ?? [])
          .map(
            (e) => DiplomaticOrder.fromJson(
              Map<String, dynamic>.from(e as Map<Object?, Object?>),
            ),
          )
          .toList();
      diploByPlayerId[playerId] = list;
    });

    final researchRaw =
        json['researchOrdersByPlayerId'] as Map<dynamic, dynamic>? ?? {};
    final researchByPlayerId = <String, List<ResearchOrder>>{};
    researchRaw.forEach((key, value) {
      final playerId = key.toString();
      final list = (value as List<dynamic>? ?? [])
          .map(
            (e) => ResearchOrder.fromJson(
              Map<String, dynamic>.from(e as Map<Object?, Object?>),
            ),
          )
          .toList();
      researchByPlayerId[playerId] = list;
    });

    final navalRaw =
        json['navalMoveOrdersByPlayerId'] as Map<dynamic, dynamic>? ?? {};
    final navalByPlayerId = <String, List<NavalMoveOrder>>{};
    navalRaw.forEach((key, value) {
      final playerId = key.toString();
      final list = (value as List<dynamic>? ?? [])
          .map(
            (e) => NavalMoveOrder.fromJson(
              Map<String, dynamic>.from(e as Map<Object?, Object?>),
            ),
          )
          .toList();
      navalByPlayerId[playerId] = list;
    });

    final missionRaw =
        json['navalMissionOrdersByPlayerId'] as Map<dynamic, dynamic>? ?? {};
    final missionByPlayerId = <String, List<NavalMissionOrder>>{};
    missionRaw.forEach((key, value) {
      final playerId = key.toString();
      final list = (value as List<dynamic>? ?? [])
          .map(
            (e) => NavalMissionOrder.fromJson(
              Map<String, dynamic>.from(e as Map<Object?, Object?>),
            ),
          )
          .toList();
      missionByPlayerId[playerId] = list;
    });

    final recruitWorkerRaw =
        json['recruitWorkerOrdersByPlayerId'] as Map<dynamic, dynamic>? ?? {};
    final recruitWorkerByPlayerId = <String, List<RecruitWorkerOrder>>{};
    recruitWorkerRaw.forEach((key, value) {
      final playerId = key.toString();
      final list = (value as List<dynamic>? ?? [])
          .map(
            (e) => RecruitWorkerOrder.fromJson(
              Map<String, dynamic>.from(e as Map<Object?, Object?>),
            ),
          )
          .toList();
      recruitWorkerByPlayerId[playerId] = list;
    });

    final tradeRaw =
        json['tradeOrdersByPlayerId'] as Map<dynamic, dynamic>? ?? {};
    final tradeByPlayerId = <String, List<TradeOrder>>{};
    tradeRaw.forEach((key, value) {
      final playerId = key.toString();
      final list = (value as List<dynamic>? ?? [])
          .map(
            (e) => TradeOrder.fromJson(
              Map<String, dynamic>.from(e as Map<Object?, Object?>),
            ),
          )
          .toList();
      tradeByPlayerId[playerId] = list;
    });

    return Orders(
      moveOrdersByPlayerId: moveByPlayerId,
      armyMoveOrdersByPlayerId: armyMoveByPlayerId,
      buildUnitOrdersByPlayerId: buildByPlayerId,
      workOrdersByPlayerId: workByPlayerId,
      recruitWorkerOrdersByPlayerId: recruitWorkerByPlayerId,
      diplomaticOrdersByPlayerId: diploByPlayerId,
      researchOrdersByPlayerId: researchByPlayerId,
      navalMoveOrdersByPlayerId: navalByPlayerId,
      navalMissionOrdersByPlayerId: missionByPlayerId,
      tradeOrdersByPlayerId: tradeByPlayerId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Orders &&
          runtimeType == other.runtimeType &&
          _mapEquals(moveOrdersByPlayerId, other.moveOrdersByPlayerId) &&
          _mapEquals(
            armyMoveOrdersByPlayerId,
            other.armyMoveOrdersByPlayerId,
          ) &&
          _mapEquals(
            buildUnitOrdersByPlayerId,
            other.buildUnitOrdersByPlayerId,
          ) &&
          _mapEquals(workOrdersByPlayerId, other.workOrdersByPlayerId) &&
          _mapEquals(
            diplomaticOrdersByPlayerId,
            other.diplomaticOrdersByPlayerId,
          ) &&
          _mapEquals(
            researchOrdersByPlayerId,
            other.researchOrdersByPlayerId,
          ) &&
          _mapEquals(
            navalMoveOrdersByPlayerId,
            other.navalMoveOrdersByPlayerId,
          ) &&
          _mapEquals(
            navalMissionOrdersByPlayerId,
            other.navalMissionOrdersByPlayerId,
          ) &&
          _mapEquals(
            recruitWorkerOrdersByPlayerId,
            other.recruitWorkerOrdersByPlayerId,
          ) &&
          _mapEquals(
            tradeOrdersByPlayerId,
            other.tradeOrdersByPlayerId,
          );

  @override
  int get hashCode => Object.hash(
    runtimeType,
    Object.hashAll(
      moveOrdersByPlayerId.entries.map((e) => Object.hashAll(e.value)),
    ),
    Object.hashAll(
      armyMoveOrdersByPlayerId.entries.map((e) => Object.hashAll(e.value)),
    ),
    Object.hashAll(
      buildUnitOrdersByPlayerId.entries.map((e) => Object.hashAll(e.value)),
    ),
    Object.hashAll(
      workOrdersByPlayerId.entries.map((e) => Object.hashAll(e.value)),
    ),
    Object.hashAll(
      diplomaticOrdersByPlayerId.entries.map((e) => Object.hashAll(e.value)),
    ),
    Object.hashAll(
      researchOrdersByPlayerId.entries.map((e) => Object.hashAll(e.value)),
    ),
    Object.hashAll(
      navalMoveOrdersByPlayerId.entries.map((e) => Object.hashAll(e.value)),
    ),
    Object.hashAll(
      navalMissionOrdersByPlayerId.entries.map((e) => Object.hashAll(e.value)),
    ),
    Object.hashAll(
      recruitWorkerOrdersByPlayerId.entries.map((e) => Object.hashAll(e.value)),
    ),
    Object.hashAll(
      tradeOrdersByPlayerId.entries.map((e) => Object.hashAll(e.value)),
    ),
  );

  Orders copyWith({
    Map<String, List<MoveOrder>>? moveOrdersByPlayerId,
    Map<String, List<ArmyMoveOrder>>? armyMoveOrdersByPlayerId,
    Map<String, List<BuildUnitOrder>>? buildUnitOrdersByPlayerId,
    Map<String, List<WorkOrder>>? workOrdersByPlayerId,
    Map<String, List<RecruitWorkerOrder>>? recruitWorkerOrdersByPlayerId,
    Map<String, List<DiplomaticOrder>>? diplomaticOrdersByPlayerId,
    Map<String, List<ResearchOrder>>? researchOrdersByPlayerId,
    Map<String, List<NavalMoveOrder>>? navalMoveOrdersByPlayerId,
    Map<String, List<NavalMissionOrder>>? navalMissionOrdersByPlayerId,
    Map<String, List<TradeOrder>>? tradeOrdersByPlayerId,
  }) => Orders(
    moveOrdersByPlayerId: moveOrdersByPlayerId ?? this.moveOrdersByPlayerId,
    armyMoveOrdersByPlayerId:
        armyMoveOrdersByPlayerId ?? this.armyMoveOrdersByPlayerId,
    buildUnitOrdersByPlayerId:
        buildUnitOrdersByPlayerId ?? this.buildUnitOrdersByPlayerId,
    workOrdersByPlayerId: workOrdersByPlayerId ?? this.workOrdersByPlayerId,
    recruitWorkerOrdersByPlayerId:
        recruitWorkerOrdersByPlayerId ?? this.recruitWorkerOrdersByPlayerId,
    diplomaticOrdersByPlayerId:
        diplomaticOrdersByPlayerId ?? this.diplomaticOrdersByPlayerId,
    researchOrdersByPlayerId:
        researchOrdersByPlayerId ?? this.researchOrdersByPlayerId,
    navalMoveOrdersByPlayerId:
        navalMoveOrdersByPlayerId ?? this.navalMoveOrdersByPlayerId,
    navalMissionOrdersByPlayerId:
        navalMissionOrdersByPlayerId ?? this.navalMissionOrdersByPlayerId,
    tradeOrdersByPlayerId:
        tradeOrdersByPlayerId ?? this.tradeOrdersByPlayerId,
  );

  static bool _mapEquals<K, V>(Map<K, List<V>> a, Map<K, List<V>> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final otherList = b[entry.key];
      if (otherList == null || otherList.length != entry.value.length) {
        return false;
      }
      for (var i = 0; i < entry.value.length; i++) {
        if (entry.value[i] != otherList[i]) return false;
      }
    }
    return true;
  }
}

/// Move a civilian land unit to a destination **land tile**.
/// Serialized form is [destinationTileKey] only; enclosing province is derived.
/// SPEC/program/orders.md; SPEC/game (issue #1877 civilian tile moves).
class MoveOrder {
  const MoveOrder({required this.unitId, required this.destinationTileKey});

  final String unitId;

  /// Land tile key `regionId|localProvinceId|x|y`. Province id is derived from the first two segments.
  final String destinationTileKey;

  Map<String, dynamic> toJson() => {
    'unitId': unitId,
    'destinationTileKey': destinationTileKey,
  };

  static MoveOrder fromJson(Map<String, dynamic> json) {
    final unitId = json['unitId'] as String;
    final tile = json['destinationTileKey'] as String?;
    if (tile != null && tile.isNotEmpty) {
      return MoveOrder(unitId: unitId, destinationTileKey: tile);
    }
    final legacy = json['destinationProvinceId'] as String?;
    if (legacy != null && legacy.isNotEmpty) {
      if (!ProvinceId.isPrefixed(legacy)) {
        throw ModelValidationException(
          'MoveOrder legacy destinationProvinceId must be prefixed (regionId|localId): "$legacy"',
        );
      }
      final region = ProvinceId.regionIdFrom(legacy);
      final local = ProvinceId.localIdFrom(legacy);
      return MoveOrder(
        unitId: unitId,
        destinationTileKey: '$region|$local|0|0',
      );
    }
    throw ModelValidationException(
      'MoveOrder requires destinationTileKey (or legacy destinationProvinceId)',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoveOrder &&
          runtimeType == other.runtimeType &&
          unitId == other.unitId &&
          destinationTileKey == other.destinationTileKey;

  @override
  int get hashCode => Object.hash(unitId, destinationTileKey);
}

/// Move an army (all its regiments) to a province. SPEC/game/military-armies.md.
class ArmyMoveOrder {
  const ArmyMoveOrder({
    required this.armyId,
    required this.destinationProvinceId,
  });

  final String armyId;
  final String destinationProvinceId;

  Map<String, dynamic> toJson() => {
    'armyId': armyId,
    'destinationProvinceId': destinationProvinceId,
  };

  static ArmyMoveOrder fromJson(Map<String, dynamic> json) {
    final destinationProvinceId = ProvinceId.requirePrefixed(
      json['destinationProvinceId'] as String,
      fieldName: 'ArmyMoveOrder.destinationProvinceId',
    );
    return ArmyMoveOrder(
      armyId: json['armyId'] as String,
      destinationProvinceId: destinationProvinceId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArmyMoveOrder &&
          runtimeType == other.runtimeType &&
          armyId == other.armyId &&
          destinationProvinceId == other.destinationProvinceId;

  @override
  int get hashCode => Object.hash(armyId, destinationProvinceId);
}

/// Move a fleet to an adjacent sea zone or dock at a port. Phase 5. SPEC/program/naval-movement-resolution.md.
///
/// Exactly one of [destinationSeaZoneId] (move to sea) or [destinationPortProvinceId] (dock)
/// must be set. Backward compat: fromJson accepts legacy payloads with only destinationSeaZoneId.
class NavalMoveOrder {
  /// Exactly one of [destinationSeaZoneId] or [destinationPortProvinceId] must be set (enforced in [fromJson] and validation).
  const NavalMoveOrder({
    required this.fleetId,
    this.destinationSeaZoneId,
    this.destinationPortProvinceId,
  });

  final String fleetId;

  /// Non-null for "move to sea zone". Null when [destinationPortProvinceId] is set (dock).
  final String? destinationSeaZoneId;

  /// Non-null for "dock at province". Null when [destinationSeaZoneId] is set.
  final String? destinationPortProvinceId;

  /// True when this order is a dock (destination is a port province).
  bool get isDock =>
      destinationPortProvinceId != null &&
      destinationPortProvinceId!.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'fleetId': fleetId,
    if (destinationSeaZoneId != null)
      'destinationSeaZoneId': destinationSeaZoneId,
    if (destinationPortProvinceId != null)
      'destinationPortProvinceId': destinationPortProvinceId,
  };

  static NavalMoveOrder fromJson(Map<String, dynamic> json) {
    final portId = json['destinationPortProvinceId'] as String?;
    final seaId = json['destinationSeaZoneId'] as String?;
    final isDock = portId != null && portId.isNotEmpty;
    final String? destSea;
    final String? destPort;
    if (isDock) {
      destSea = null;
      destPort = portId;
    } else {
      if (seaId == null || seaId.isEmpty) {
        throw ModelValidationException(
          'destinationSeaZoneId required for move to sea',
        );
      }
      destSea = seaId;
      destPort = null;
    }
    return NavalMoveOrder(
      fleetId: json['fleetId'] as String,
      destinationSeaZoneId: destSea,
      destinationPortProvinceId: destPort,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavalMoveOrder &&
          runtimeType == other.runtimeType &&
          fleetId == other.fleetId &&
          destinationSeaZoneId == other.destinationSeaZoneId &&
          destinationPortProvinceId == other.destinationPortProvinceId;

  @override
  int get hashCode =>
      Object.hash(fleetId, destinationSeaZoneId, destinationPortProvinceId);
}

/// Assign a mission to a fleet (patrol, blockade, beachhead, defend). SPEC/program/naval-movement-resolution.md.
class NavalMissionOrder {
  const NavalMissionOrder({
    required this.fleetId,
    required this.mission,
    this.targetPortId,
    this.targetProvinceId,
  });

  final String fleetId;
  final String mission;
  final String? targetPortId;
  final String? targetProvinceId;

  Map<String, dynamic> toJson() => {
    'fleetId': fleetId,
    'mission': mission,
    if (targetPortId != null) 'targetPortId': targetPortId,
    if (targetProvinceId != null) 'targetProvinceId': targetProvinceId,
  };

  static NavalMissionOrder fromJson(Map<String, dynamic> json) {
    return NavalMissionOrder(
      fleetId: json['fleetId'] as String,
      mission: json['mission'] as String? ?? 'none',
      targetPortId: json['targetPortId'] as String?,
      targetProvinceId: json['targetProvinceId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavalMissionOrder &&
          runtimeType == other.runtimeType &&
          fleetId == other.fleetId &&
          mission == other.mission &&
          targetPortId == other.targetPortId &&
          targetProvinceId == other.targetProvinceId;

  @override
  int get hashCode =>
      Object.hash(fleetId, mission, targetPortId, targetProvinceId);
}

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
