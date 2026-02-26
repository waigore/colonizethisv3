import 'province_id.dart';

/// Capital tile position within a province. SPEC/game/capital-and-connectivity.
class CapitalTile {
  const CapitalTile({
    required this.regionId,
    required this.provinceId,
    required this.x,
    required this.y,
  });

  final String regionId;
  /// Full province id (regionId|localId). Use [ProvinceId.localIdFrom] for tile key second segment.
  final String provinceId;
  final int x;
  final int y;

  /// Tile key for use in connectivity and extraction: "regionId|localId|x|y".
  String toTileKey() =>
      '$regionId|${ProvinceId.localIdFrom(provinceId)}|$x|$y';

  static String tileKey(String regionId, String provinceId, int x, int y) =>
      '$regionId|${ProvinceId.localIdFrom(provinceId)}|$x|$y';

  Map<String, dynamic> toJson() => {
        'regionId': regionId,
        'provinceId': provinceId,
        'x': x,
        'y': y,
      };

  static CapitalTile? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return CapitalTile(
      regionId: json['regionId'] as String,
      provinceId: json['provinceId'] as String,
      x: json['x'] as int,
      y: json['y'] as int,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CapitalTile &&
          runtimeType == other.runtimeType &&
          regionId == other.regionId &&
          provinceId == other.provinceId &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => Object.hash(regionId, provinceId, x, y);
}
