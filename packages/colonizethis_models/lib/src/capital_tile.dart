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

  /// Full province id (regionId|localId). Tile keys normalize the second segment
  /// by stripping region prefix when present and otherwise preserving legacy bare ids.
  final String provinceId;
  final int x;
  final int y;

  /// Tile key for use in connectivity and extraction: "regionId|localId|x|y".
  String toTileKey() =>
      '$regionId|${ProvinceId.isPrefixed(provinceId) ? ProvinceId.localIdFrom(provinceId) : provinceId}|$x|$y';

  static String tileKey(String regionId, String provinceId, int x, int y) =>
      '$regionId|${ProvinceId.isPrefixed(provinceId) ? ProvinceId.localIdFrom(provinceId) : provinceId}|$x|$y';

  /// Parses a stored town/capital tile key `regionId|localId|x|y`.
  /// [expectedProvinceId] must be the full id `regionId|localId` and match the key.
  /// Throws [FormatException] if the string is empty, has fewer than four segments,
  /// has non-integer x/y, or the implied province id does not equal [expectedProvinceId].
  static CapitalTile parseTownTileKey(
    String townTileKey,
    String expectedProvinceId,
  ) {
    final trimmed = townTileKey.trim();
    if (trimmed.isEmpty) {
      throw FormatException(
        'townTileKey is empty for province $expectedProvinceId',
      );
    }
    final parts = trimmed.split('|');
    if (parts.length < 4) {
      throw FormatException(
        'townTileKey must have at least 4 pipe-separated segments: "$townTileKey"',
      );
    }
    final regionId = parts[0];
    final localId = parts[1];
    final x = int.tryParse(parts[2]);
    final y = int.tryParse(parts[3]);
    if (x == null || y == null) {
      throw FormatException(
        'townTileKey x and y must be integers: "$townTileKey"',
      );
    }
    final fullProv = '$regionId|$localId';
    if (fullProv != expectedProvinceId) {
      throw FormatException(
        'townTileKey implies province "$fullProv" but expected "$expectedProvinceId"',
      );
    }
    return CapitalTile(regionId: regionId, provinceId: fullProv, x: x, y: y);
  }

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
