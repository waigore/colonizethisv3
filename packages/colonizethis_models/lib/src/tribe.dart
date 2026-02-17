import 'capital_tile.dart';

/// Tribe faction. SPEC/game/factions.md.
/// New World only; capital assigned at game setup.
class Tribe {
  const Tribe({
    required this.id,
    this.displayName,
    this.capitalProvinceId,
    this.capitalTile,
  });

  final String id;
  final String? displayName;
  final String? capitalProvinceId;
  final CapitalTile? capitalTile;

  Map<String, dynamic> toJson() => {
        'id': id,
        if (displayName != null) 'displayName': displayName,
        if (capitalProvinceId != null) 'capitalProvinceId': capitalProvinceId,
        if (capitalTile != null) 'capitalTile': capitalTile!.toJson(),
      };

  static Tribe fromJson(Map<String, dynamic> json) {
    final capitalTileRaw = json['capitalTile'];
    return Tribe(
      id: json['id'] as String,
      displayName: json['displayName'] as String?,
      capitalProvinceId: json['capitalProvinceId'] as String?,
      capitalTile: capitalTileRaw is Map<String, dynamic>
          ? CapitalTile.fromJson(capitalTileRaw)
          : (capitalTileRaw is Map
              ? CapitalTile.fromJson(Map<String, dynamic>.from(capitalTileRaw))
              : null),
    );
  }

  Tribe copyWith({
    String? id,
    String? displayName,
    String? capitalProvinceId,
    CapitalTile? capitalTile,
  }) {
    return Tribe(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      capitalProvinceId: capitalProvinceId ?? this.capitalProvinceId,
      capitalTile: capitalTile ?? this.capitalTile,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tribe &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          displayName == other.displayName &&
          capitalProvinceId == other.capitalProvinceId &&
          capitalTile == other.capitalTile;

  @override
  int get hashCode => Object.hash(id, displayName, capitalProvinceId, capitalTile);
}
