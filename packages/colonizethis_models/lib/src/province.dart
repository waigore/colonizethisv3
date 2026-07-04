import 'province_id.dart';

/// Valid town development levels (1–4). Level 0 is abolished (Refs #3870).
const int kTownDevelopmentLevelMin = 1;
const int kTownDevelopmentLevelMax = 4;

/// Coerces legacy saves and clamps out-of-range values to 1–4.
int normalizeTownDevelopmentLevel(int? raw) {
  final value = raw ?? kTownDevelopmentLevelMin;
  if (value < kTownDevelopmentLevelMin) return kTownDevelopmentLevelMin;
  if (value > kTownDevelopmentLevelMax) return kTownDevelopmentLevelMax;
  return value;
}

/// One map province in a region. SPEC/game/world-model.
/// Phase 3: fortLevel (0–3), terrain for combat. SPEC/game/siege-mechanics.md.
/// Town: townTileKey and townDevelopmentLevel for extraction. SPEC/game/capital-and-connectivity.md.
class Province {
  const Province({
    required this.id,
    required this.regionId,
    this.ownerId,
    this.displayName,
    this.fortLevel = 0,
    this.terrain = 'plains',
    this.townTileKey,
    this.townDevelopmentLevel = kTownDevelopmentLevelMin,
  });

  final String id;
  final String regionId;
  final String? ownerId;

  /// Optional human-readable name (from ruleset naming config).
  final String? displayName;

  /// Fort level 0–3. 0 = field battle; 1+ = siege. SPEC/game/siege-mechanics.md.
  final int fortLevel;

  /// Terrain type for combat modifiers (plains, forest, hills, mountain, swamp, desert).
  final String terrain;

  /// Tile key of the province's town (for extraction connectivity). Set at game init. SPEC/game/capital-and-connectivity.md.
  final String? townTileKey;

  /// Town development level 1–4. Raised by Builder upgrade_town work. Limits extraction. SPEC/game/extraction-and-improvements.md.
  final int townDevelopmentLevel;

  Map<String, dynamic> toJson() => {
    'id': id,
    'regionId': regionId,
    'ownerId': ownerId,
    if (displayName != null) 'displayName': displayName,
    if (fortLevel != 0) 'fortLevel': fortLevel,
    if (terrain != 'plains') 'terrain': terrain,
    if (townTileKey != null) 'townTileKey': townTileKey,
    if (townDevelopmentLevel != kTownDevelopmentLevelMin)
      'townDevelopmentLevel': townDevelopmentLevel,
  };

  static Province fromJson(Map<String, dynamic> json) {
    final provinceId = ProvinceId.requirePrefixed(
      json['id'] as String,
      fieldName: 'Province.id',
    );
    return Province(
      id: provinceId,
      regionId: json['regionId'] as String,
      ownerId: json['ownerId'] as String?,
      displayName: json['displayName'] as String?,
      fortLevel: (json['fortLevel'] as int?) ?? 0,
      terrain: json['terrain'] as String? ?? 'plains',
      townTileKey: json['townTileKey'] as String?,
      townDevelopmentLevel: normalizeTownDevelopmentLevel(
        json['townDevelopmentLevel'] as int?,
      ),
    );
  }

  Province copyWith({
    String? id,
    String? regionId,
    String? ownerId,
    String? displayName,
    int? fortLevel,
    String? terrain,
    String? townTileKey,
    int? townDevelopmentLevel,
  }) {
    return Province(
      id: id ?? this.id,
      regionId: regionId ?? this.regionId,
      ownerId: ownerId ?? this.ownerId,
      displayName: displayName ?? this.displayName,
      fortLevel: fortLevel ?? this.fortLevel,
      terrain: terrain ?? this.terrain,
      townTileKey: townTileKey ?? this.townTileKey,
      townDevelopmentLevel: townDevelopmentLevel ?? this.townDevelopmentLevel,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Province &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          regionId == other.regionId &&
          ownerId == other.ownerId &&
          displayName == other.displayName &&
          fortLevel == other.fortLevel &&
          terrain == other.terrain &&
          townTileKey == other.townTileKey &&
          townDevelopmentLevel == other.townDevelopmentLevel;

  @override
  int get hashCode => Object.hash(
    id,
    regionId,
    ownerId,
    displayName,
    fortLevel,
    terrain,
    townTileKey,
    townDevelopmentLevel,
  );
}
