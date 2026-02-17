/// One map province in a region. SPEC/game/world-model.
/// Phase 3: fortLevel (0–3), terrain for combat. SPEC/game/siege-mechanics.md.
class Province {
  const Province({
    required this.id,
    required this.regionId,
    this.ownerId,
    this.displayName,
    this.fortLevel = 0,
    this.terrain = 'plains',
  });

  final String id;
  final String regionId;
  final String? ownerId;
  /// Optional human-readable name (from ruleset naming config).
  final String? displayName;

  /// Fort level 0–3. 0 = field battle; 1+ = siege. SPEC/game/siege-mechanics.md.
  final int fortLevel;

  /// Terrain type for combat modifiers (plains, forest, hills, mountain, swamp).
  final String terrain;

  Map<String, dynamic> toJson() => {
        'id': id,
        'regionId': regionId,
        'ownerId': ownerId,
        if (displayName != null) 'displayName': displayName,
        if (fortLevel != 0) 'fortLevel': fortLevel,
        if (terrain != 'plains') 'terrain': terrain,
      };

  static Province fromJson(Map<String, dynamic> json) {
    return Province(
      id: json['id'] as String,
      regionId: json['regionId'] as String,
      ownerId: json['ownerId'] as String?,
      displayName: json['displayName'] as String?,
      fortLevel: (json['fortLevel'] as int?) ?? 0,
      terrain: json['terrain'] as String? ?? 'plains',
    );
  }

  Province copyWith({
    String? id,
    String? regionId,
    String? ownerId,
    String? displayName,
    int? fortLevel,
    String? terrain,
  }) {
    return Province(
      id: id ?? this.id,
      regionId: regionId ?? this.regionId,
      ownerId: ownerId ?? this.ownerId,
      displayName: displayName ?? this.displayName,
      fortLevel: fortLevel ?? this.fortLevel,
      terrain: terrain ?? this.terrain,
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
          terrain == other.terrain;

  @override
  int get hashCode =>
      Object.hash(id, regionId, ownerId, displayName, fortLevel, terrain);
}
