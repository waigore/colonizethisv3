/// Fleet mission. SPEC/game/ships-and-naval.md, naval-movement-resolution.md.
enum FleetMission {
  none,
  patrol,
  blockade,
  beachhead,
  defend,
}

/// Fleet: owner, location (sea zone), ships, mission. SPEC/game/ships-and-naval.md.
class Fleet {
  const Fleet({
    required this.id,
    required this.ownerId,
    required this.seaZoneId,
    required this.regionId,
    this.shipTypeIds = const [],
    this.mission = FleetMission.none,
    this.targetPortId,
    this.targetProvinceId,
  });

  final String id;
  final String ownerId;
  final String seaZoneId;
  final String regionId;
  /// Ship type ids (e.g. 'carrack', 'fluyte'). Order/count per type can be extended.
  final List<String> shipTypeIds;
  final FleetMission mission;
  final String? targetPortId;
  final String? targetProvinceId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'seaZoneId': seaZoneId,
        'regionId': regionId,
        'shipTypeIds': List<String>.from(shipTypeIds),
        'mission': mission.name,
        if (targetPortId != null) 'targetPortId': targetPortId,
        if (targetProvinceId != null) 'targetProvinceId': targetProvinceId,
      };

  static Fleet fromJson(Map<String, dynamic> json) {
    final shipsRaw = json['shipTypeIds'] as List<dynamic>? ?? [];
    final missionStr = json['mission'] as String? ?? 'none';
    final mission = FleetMission.values.firstWhere(
      (e) => e.name == missionStr,
      orElse: () => FleetMission.none,
    );
    return Fleet(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      seaZoneId: json['seaZoneId'] as String,
      regionId: json['regionId'] as String,
      shipTypeIds: shipsRaw.map((e) => e.toString()).toList(),
      mission: mission,
      targetPortId: json['targetPortId'] as String?,
      targetProvinceId: json['targetProvinceId'] as String?,
    );
  }

  Fleet copyWith({
    String? id,
    String? ownerId,
    String? seaZoneId,
    String? regionId,
    List<String>? shipTypeIds,
    FleetMission? mission,
    String? targetPortId,
    String? targetProvinceId,
  }) {
    return Fleet(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      seaZoneId: seaZoneId ?? this.seaZoneId,
      regionId: regionId ?? this.regionId,
      shipTypeIds: shipTypeIds ?? this.shipTypeIds,
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
          regionId == other.regionId &&
          _listEquals(shipTypeIds, other.shipTypeIds) &&
          mission == other.mission &&
          targetPortId == other.targetPortId &&
          targetProvinceId == other.targetProvinceId;

  @override
  int get hashCode => Object.hash(id, ownerId, seaZoneId, regionId, Object.hashAll(shipTypeIds), mission, targetPortId, targetProvinceId);

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
