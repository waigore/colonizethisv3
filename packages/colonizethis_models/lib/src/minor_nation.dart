import 'capital_tile.dart';
import 'province_id.dart';

/// Minor Nation faction. SPEC/game/factions.md.
/// Old World only; capital assigned at game setup.
/// Phase 3: effectiveMilitaryLevel for combat parity. SPEC/game/factions.md.
class MinorNation {
  const MinorNation({
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

  /// Combat parity: set to max GP military level at start of Combat phase. SPEC/game/factions.md.
  final int effectiveMilitaryLevel;

  Map<String, dynamic> toJson() => {
    'id': id,
    if (displayName != null) 'displayName': displayName,
    if (capitalProvinceId != null) 'capitalProvinceId': capitalProvinceId,
    if (capitalTile != null) 'capitalTile': capitalTile!.toJson(),
    if (effectiveMilitaryLevel != 1)
      'effectiveMilitaryLevel': effectiveMilitaryLevel,
  };

  static MinorNation fromJson(Map<String, dynamic> json) {
    final capitalTileRaw = json['capitalTile'];
    return MinorNation(
      id: json['id'] as String,
      displayName: json['displayName'] as String?,
      capitalProvinceId: ProvinceId.requirePrefixedOrNull(
        json['capitalProvinceId'] as String?,
        fieldName: 'MinorNation.capitalProvinceId',
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

  MinorNation copyWith({
    String? id,
    String? displayName,
    String? capitalProvinceId,
    CapitalTile? capitalTile,
    int? effectiveMilitaryLevel,
  }) {
    return MinorNation(
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
      other is MinorNation &&
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
