/// Per-player orders for the current turn.
/// SPEC/game/world-model.
/// SPEC/program/orders.md
class Orders {
  const Orders({
    this.moveOrdersByPlayerId = const {},
    this.buildUnitOrdersByPlayerId = const {},
    this.workOrdersByPlayerId = const {},
  });

  /// Player id -> list of move orders.
  final Map<String, List<MoveOrder>> moveOrdersByPlayerId;
  /// Player id -> list of build-unit orders.
  final Map<String, List<BuildUnitOrder>> buildUnitOrdersByPlayerId;
  /// Player id -> list of work orders.
  final Map<String, List<WorkOrder>> workOrdersByPlayerId;

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

    return Orders(
      moveOrdersByPlayerId: moveByPlayerId,
      buildUnitOrdersByPlayerId: buildByPlayerId,
      workOrdersByPlayerId: workByPlayerId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Orders &&
          runtimeType == other.runtimeType &&
          _mapEquals(moveOrdersByPlayerId, other.moveOrdersByPlayerId) &&
          _mapEquals(buildUnitOrdersByPlayerId, other.buildUnitOrdersByPlayerId) &&
          _mapEquals(workOrdersByPlayerId, other.workOrdersByPlayerId);

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
