import 'province_id.dart';

/// Land military army: container for regiment unit ids. SPEC/game/military-armies.md.
class Army {
  const Army({
    required this.id,
    required this.ownerId,
    required this.regionId,
    required this.stationedProvinceId,
    required this.regimentUnitIds,
    this.isHomeArmy = false,
  });

  final String id;
  final String ownerId;
  final String regionId;

  /// Prefixed province id where this army is stationed.
  final String stationedProvinceId;
  final List<String> regimentUnitIds;
  final bool isHomeArmy;

  Army copyWith({
    String? id,
    String? ownerId,
    String? regionId,
    String? stationedProvinceId,
    List<String>? regimentUnitIds,
    bool? isHomeArmy,
  }) {
    return Army(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      regionId: regionId ?? this.regionId,
      stationedProvinceId: stationedProvinceId ?? this.stationedProvinceId,
      regimentUnitIds: regimentUnitIds ?? this.regimentUnitIds,
      isHomeArmy: isHomeArmy ?? this.isHomeArmy,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'regionId': regionId,
    'stationedProvinceId': stationedProvinceId,
    'regimentUnitIds': regimentUnitIds,
    if (isHomeArmy) 'isHomeArmy': true,
  };

  static Army fromJson(Map<String, dynamic> json) {
    final idsRaw = json['regimentUnitIds'] as List<dynamic>? ?? [];
    return Army(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      regionId: json['regionId'] as String,
      stationedProvinceId: ProvinceId.requirePrefixed(
        json['stationedProvinceId'] as String,
        fieldName: 'Army.stationedProvinceId',
      ),
      regimentUnitIds: idsRaw.map((e) => e.toString()).toList(),
      isHomeArmy: json['isHomeArmy'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Army &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ownerId == other.ownerId &&
          regionId == other.regionId &&
          stationedProvinceId == other.stationedProvinceId &&
          _listEquals(regimentUnitIds, other.regimentUnitIds) &&
          isHomeArmy == other.isHomeArmy;

  @override
  int get hashCode => Object.hash(
    id,
    ownerId,
    regionId,
    stationedProvinceId,
    Object.hashAll(regimentUnitIds),
    isHomeArmy,
  );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
