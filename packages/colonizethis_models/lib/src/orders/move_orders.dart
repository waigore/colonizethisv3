import '../model_validation_exception.dart';
import '../province_id.dart';

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
