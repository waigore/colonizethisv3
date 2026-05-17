import 'capital_tile.dart';
import 'province_id.dart';

/// Tribe faction. SPEC/game/factions.md.
/// New World only; capital assigned at game setup.
/// Phase 3: effectiveMilitaryLevel for combat (always 1; no parity). SPEC/game/factions.md.
class Tribe {
  const Tribe({
    required this.id,
    this.displayName,
    this.capitalProvinceId,
    this.capitalTile,
    this.effectiveMilitaryLevel = 1,
  });

  final String id;
  final String? displayName;
  final String? capitalProvinceId;
  final CapitalTile? capitalTile;

  /// Combat: set to 1 at start of Combat phase (no parity; tribes easily conquered). SPEC/game/factions.md.
  final int effectiveMilitaryLevel;

  Map<String, dynamic> toJson() => {
    'id': id,
    if (displayName != null) 'displayName': displayName,
    if (capitalProvinceId != null) 'capitalProvinceId': capitalProvinceId,
    if (capitalTile != null) 'capitalTile': capitalTile!.toJson(),
    if (effectiveMilitaryLevel != 1)
      'effectiveMilitaryLevel': effectiveMilitaryLevel,
  };

  static Tribe fromJson(Map<String, dynamic> json) {
    final capitalTileRaw = json['capitalTile'];
    return Tribe(
      id: json['id'] as String,
      displayName: json['displayName'] as String?,
      capitalProvinceId: ProvinceId.requirePrefixedOrNull(
        json['capitalProvinceId'] as String?,
        fieldName: 'Tribe.capitalProvinceId',
      ),
      capitalTile: capitalTileRaw is Map<String, dynamic>
          ? CapitalTile.fromJson(capitalTileRaw)
          : (capitalTileRaw is Map<Object?, Object?>
                ? CapitalTile.fromJson(
                    Map<String, dynamic>.from(capitalTileRaw),
                  )
                : null),
      effectiveMilitaryLevel: (json['effectiveMilitaryLevel'] as int?) ?? 1,
    );
  }

  Tribe copyWith({
    String? id,
    String? displayName,
    String? capitalProvinceId,
    CapitalTile? capitalTile,
    int? effectiveMilitaryLevel,
  }) {
    return Tribe(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      capitalProvinceId: capitalProvinceId ?? this.capitalProvinceId,
      capitalTile: capitalTile ?? this.capitalTile,
      effectiveMilitaryLevel:
          effectiveMilitaryLevel ?? this.effectiveMilitaryLevel,
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
          capitalTile == other.capitalTile &&
          effectiveMilitaryLevel == other.effectiveMilitaryLevel;

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    capitalProvinceId,
    capitalTile,
    effectiveMilitaryLevel,
  );
}
