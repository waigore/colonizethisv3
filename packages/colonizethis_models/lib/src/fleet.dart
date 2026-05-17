import 'ship_instance.dart';
import 'model_validation_exception.dart';

/// Fleet mission. SPEC/game/ships-and-naval.md, naval-movement-resolution.md.
enum FleetMission { none, patrol, blockade, beachhead, defend }

/// Next `ship_<n>` id is [n] where n >= this value. SPEC/game/ships-and-naval.md.
int inferNextShipInstanceSeqFromFleets(Iterable<Fleet> fleets) {
  var max = 0;
  for (final f in fleets) {
    final fromFleet = _maxShipSeqFromFleetShips(f.ships);
    if (fromFleet > max) max = fromFleet;
  }
  return max + 1;
}

int _maxShipSeqFromFleetShips(List<ShipInstance> ships) {
  var max = 0;
  for (final s in ships) {
    if (!s.id.startsWith('ship_')) continue;
    final n = int.tryParse(s.id.substring(5));
    if (n != null && n > max) max = n;
  }
  return max;
}

/// Fleet: owner, location (at sea: seaZoneId; in port: inPortAtProvinceId), ships, mission.
/// SPEC/game/ships-and-naval.md. Exactly one of [seaZoneId] or [inPortAtProvinceId] is set.
///
/// Pass either [ships] or [shipTypeIds] (legacy convenience); not both non-empty.
class Fleet {
  Fleet({
    required this.id,
    required this.ownerId,
    this.seaZoneId,
    this.inPortAtProvinceId,
    required this.regionId,
    List<ShipInstance> ships = const [],
    List<String>? shipTypeIds,
    this.mission = FleetMission.none,
    this.targetPortId,
    this.targetProvinceId,
  }) : ships = _coerceShips(id, ships, shipTypeIds);

  static List<ShipInstance> _coerceShips(
    String fleetId,
    List<ShipInstance> ships,
    List<String>? shipTypeIds,
  ) {
    if (ships.isNotEmpty) {
      if (shipTypeIds != null && shipTypeIds.isNotEmpty) {
        throw ModelValidationException(
          'Fleet $fleetId: pass only ships or shipTypeIds, not both',
        );
      }
      return List<ShipInstance>.from(ships);
    }
    if (shipTypeIds != null && shipTypeIds.isNotEmpty) {
      return legacyShipInstancesForFleet(fleetId, shipTypeIds);
    }
    return const [];
  }

  final String id;
  final String ownerId;

  /// When non-null, fleet is at sea in this sea zone. When null, fleet is in port ([inPortAtProvinceId] set).
  final String? seaZoneId;

  /// When non-null, fleet is in port at this province (prefixed id). When null, fleet is at sea ([seaZoneId] set).
  final String? inPortAtProvinceId;
  final String regionId;

  /// Ship instances (unique [ShipInstance.id] per hull). Order is significant for display.
  final List<ShipInstance> ships;

  /// Catalog type id per instance; same length as [ships]. For aggregation and stats.
  List<String> get shipTypeIds => ships.map((s) => s.typeId).toList();

  final FleetMission mission;
  final String? targetPortId;
  final String? targetProvinceId;

  /// True if this fleet is at sea (has seaZoneId). False when in port.
  bool get isAtSea => seaZoneId != null;

  /// True if this fleet is in port (has inPortAtProvinceId).
  bool get isInPort => inPortAtProvinceId != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    if (seaZoneId != null) 'seaZoneId': seaZoneId,
    if (inPortAtProvinceId != null) 'inPortAtProvinceId': inPortAtProvinceId,
    'regionId': regionId,
    'ships': ships.map((s) => s.toJson()).toList(),
    'mission': mission.name,
    if (targetPortId != null) 'targetPortId': targetPortId,
    if (targetProvinceId != null) 'targetProvinceId': targetProvinceId,
  };

  static Fleet fromJson(Map<String, dynamic> json) {
    final fleetId = json['id'] as String;
    final List<ShipInstance> ships;
    if (json.containsKey('ships')) {
      final shipsRaw = json['ships'] as List<dynamic>? ?? [];
      ships = shipsRaw
          .map(
            (e) => ShipInstance.fromJson(
              Map<String, dynamic>.from(e as Map<Object?, Object?>),
            ),
          )
          .toList();
    } else {
      final legacy = json['shipTypeIds'] as List<dynamic>? ?? [];
      ships = legacyShipInstancesForFleet(
        fleetId,
        legacy.map((e) => e.toString()).toList(),
      );
    }
    final missionStr = json['mission'] as String? ?? 'none';
    final mission = FleetMission.values.firstWhere(
      (e) => e.name == missionStr,
      orElse: () => FleetMission.none,
    );
    return Fleet(
      id: fleetId,
      ownerId: json['ownerId'] as String,
      seaZoneId: json['seaZoneId'] as String?,
      inPortAtProvinceId: json['inPortAtProvinceId'] as String?,
      regionId: json['regionId'] as String,
      ships: ships,
      mission: mission,
      targetPortId: json['targetPortId'] as String?,
      targetProvinceId: json['targetProvinceId'] as String?,
    );
  }

  Fleet copyWith({
    String? id,
    String? ownerId,
    String? seaZoneId,
    String? inPortAtProvinceId,
    String? regionId,
    List<ShipInstance>? ships,
    FleetMission? mission,
    String? targetPortId,
    String? targetProvinceId,
  }) {
    return Fleet(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      seaZoneId: seaZoneId ?? this.seaZoneId,
      inPortAtProvinceId: inPortAtProvinceId ?? this.inPortAtProvinceId,
      regionId: regionId ?? this.regionId,
      ships: ships ?? this.ships,
      mission: mission ?? this.mission,
      targetPortId: targetPortId ?? this.targetPortId,
      targetProvinceId: targetProvinceId ?? this.targetProvinceId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Fleet &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ownerId == other.ownerId &&
          seaZoneId == other.seaZoneId &&
          inPortAtProvinceId == other.inPortAtProvinceId &&
          regionId == other.regionId &&
          _listEqualsShips(ships, other.ships) &&
          mission == other.mission &&
          targetPortId == other.targetPortId &&
          targetProvinceId == other.targetProvinceId;

  @override
  int get hashCode => Object.hash(
    id,
    ownerId,
    seaZoneId,
    inPortAtProvinceId,
    regionId,
    Object.hashAll(ships),
    mission,
    targetPortId,
    targetProvinceId,
  );

  static bool _listEqualsShips(List<ShipInstance> a, List<ShipInstance> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
