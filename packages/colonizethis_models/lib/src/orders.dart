import 'diplomacy.dart';

/// Per-player orders for the current turn.
/// SPEC/game/world-model.
/// SPEC/program/orders.md
class Orders {
  const Orders({
    this.moveOrdersByPlayerId = const {},
    this.buildUnitOrdersByPlayerId = const {},
    this.workOrdersByPlayerId = const {},
    this.diplomaticOrdersByPlayerId = const {},
    this.researchOrdersByPlayerId = const {},
  });

  /// Player id -> list of move orders.
  final Map<String, List<MoveOrder>> moveOrdersByPlayerId;
  /// Player id -> list of build-unit orders.
  final Map<String, List<BuildUnitOrder>> buildUnitOrdersByPlayerId;
  /// Player id -> list of work orders.
  final Map<String, List<WorkOrder>> workOrdersByPlayerId;
  /// Player id -> list of diplomatic orders. Phase 4.
  final Map<String, List<DiplomaticOrder>> diplomaticOrdersByPlayerId;
  /// Player id -> list of research orders. Phase 5.
  final Map<String, List<ResearchOrder>> researchOrdersByPlayerId;

  Map<String, dynamic> toJson() => {
        'moveOrdersByPlayerId': moveOrdersByPlayerId.map(
          (playerId, orders) => MapEntry(
            playerId,
            orders.map((o) => o.toJson()).toList(),
          ),
        ),
        'buildUnitOrdersByPlayerId': buildUnitOrdersByPlayerId.map(
          (playerId, orders) => MapEntry(
            playerId,
            orders.map((o) => o.toJson()).toList(),
          ),
        ),
        'workOrdersByPlayerId': workOrdersByPlayerId.map(
          (playerId, orders) => MapEntry(
            playerId,
            orders.map((o) => o.toJson()).toList(),
          ),
        ),
        if (diplomaticOrdersByPlayerId.isNotEmpty)
          'diplomaticOrdersByPlayerId': diplomaticOrdersByPlayerId.map(
            (playerId, orders) => MapEntry(
              playerId,
              orders.map((o) => o.toJson()).toList(),
            ),
          ),
        if (researchOrdersByPlayerId.isNotEmpty)
          'researchOrdersByPlayerId': researchOrdersByPlayerId.map(
            (playerId, orders) => MapEntry(
              playerId,
              orders.map((o) => o.toJson()).toList(),
            ),
          ),
      };

  static Orders fromJson(Map<String, dynamic> json) {
    final moveRaw = json['moveOrdersByPlayerId'] as Map<dynamic, dynamic>? ?? {};
    final moveByPlayerId = <String, List<MoveOrder>>{};
    moveRaw.forEach((key, value) {
      final playerId = key.toString();
      final list = (value as List<dynamic>? ?? [])
          .map((e) => MoveOrder.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      moveByPlayerId[playerId] = list;
    });

    final buildRaw = json['buildUnitOrdersByPlayerId'] as Map<dynamic, dynamic>? ?? {};
    final buildByPlayerId = <String, List<BuildUnitOrder>>{};
    buildRaw.forEach((key, value) {
      final playerId = key.toString();
      final list = (value as List<dynamic>? ?? [])
          .map((e) => BuildUnitOrder.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      buildByPlayerId[playerId] = list;
    });

    final workRaw = json['workOrdersByPlayerId'] as Map<dynamic, dynamic>? ?? {};
    final workByPlayerId = <String, List<WorkOrder>>{};
    workRaw.forEach((key, value) {
      final playerId = key.toString();
      final list = (value as List<dynamic>? ?? [])
          .map((e) => WorkOrder.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      workByPlayerId[playerId] = list;
    });

    final diploRaw = json['diplomaticOrdersByPlayerId'] as Map<dynamic, dynamic>? ?? {};
    final diploByPlayerId = <String, List<DiplomaticOrder>>{};
    diploRaw.forEach((key, value) {
      final playerId = key.toString();
      final list = (value as List<dynamic>? ?? [])
          .map((e) => DiplomaticOrder.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      diploByPlayerId[playerId] = list;
    });

    final researchRaw = json['researchOrdersByPlayerId'] as Map<dynamic, dynamic>? ?? {};
    final researchByPlayerId = <String, List<ResearchOrder>>{};
    researchRaw.forEach((key, value) {
      final playerId = key.toString();
      final list = (value as List<dynamic>? ?? [])
          .map((e) => ResearchOrder.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      researchByPlayerId[playerId] = list;
    });

    return Orders(
      moveOrdersByPlayerId: moveByPlayerId,
      buildUnitOrdersByPlayerId: buildByPlayerId,
      workOrdersByPlayerId: workByPlayerId,
      diplomaticOrdersByPlayerId: diploByPlayerId,
      researchOrdersByPlayerId: researchByPlayerId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Orders &&
          runtimeType == other.runtimeType &&
          _mapEquals(moveOrdersByPlayerId, other.moveOrdersByPlayerId) &&
          _mapEquals(buildUnitOrdersByPlayerId, other.buildUnitOrdersByPlayerId) &&
          _mapEquals(workOrdersByPlayerId, other.workOrdersByPlayerId) &&
          _mapEquals(diplomaticOrdersByPlayerId, other.diplomaticOrdersByPlayerId) &&
          _mapEquals(researchOrdersByPlayerId, other.researchOrdersByPlayerId);

  @override
  int get hashCode => Object.hash(
        runtimeType,
        Object.hashAll(
          moveOrdersByPlayerId.entries.map(
            (e) => Object.hashAll(e.value),
          ),
        ),
        Object.hashAll(
          buildUnitOrdersByPlayerId.entries.map(
            (e) => Object.hashAll(e.value),
          ),
        ),
        Object.hashAll(
          workOrdersByPlayerId.entries.map(
            (e) => Object.hashAll(e.value),
          ),
        ),
        Object.hashAll(
          diplomaticOrdersByPlayerId.entries.map(
            (e) => Object.hashAll(e.value),
          ),
        ),
        Object.hashAll(
          researchOrdersByPlayerId.entries.map(
            (e) => Object.hashAll(e.value),
          ),
        ),
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

/// Move a unit to an adjacent province.
/// SPEC/program/orders.md
class MoveOrder {
  const MoveOrder({
    required this.unitId,
    required this.destinationProvinceId,
  });

  final String unitId;
  final String destinationProvinceId;

  Map<String, dynamic> toJson() => {
        'unitId': unitId,
        'destinationProvinceId': destinationProvinceId,
      };

  static MoveOrder fromJson(Map<String, dynamic> json) {
    return MoveOrder(
      unitId: json['unitId'] as String,
      destinationProvinceId: json['destinationProvinceId'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoveOrder &&
          runtimeType == other.runtimeType &&
          unitId == other.unitId &&
          destinationProvinceId == other.destinationProvinceId;

  @override
  int get hashCode => Object.hash(unitId, destinationProvinceId);
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
    return BuildUnitOrder(
      unitType: json['unitType'] as String,
      isMilitary: json['isMilitary'] as bool? ?? false,
      spawnProvinceId: json['spawnProvinceId'] as String,
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
/// SPEC/program/orders.md
class WorkOrder {
  const WorkOrder({
    required this.unitId,
    required this.target,
  });

  final String unitId;
  final String target;

  Map<String, dynamic> toJson() => {
        'unitId': unitId,
        'target': target,
      };

  static WorkOrder fromJson(Map<String, dynamic> json) {
    return WorkOrder(
      unitId: json['unitId'] as String,
      target: json['target'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkOrder &&
          runtimeType == other.runtimeType &&
          unitId == other.unitId &&
          target == other.target;

  @override
  int get hashCode => Object.hash(unitId, target);
}

/// Funding level for research per slot. Maps to treasury cost and research
/// points per turn. SPEC/program/research-resolution.md
enum ResearchFundingLevel {
  none,
  low,
  medium,
  high,
  maximum,
}

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
    final fundingRaw = json['funding'] as String? ?? ResearchFundingLevel.none.name;
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
