/// One map province in a region. SPEC/game/world-model.
class Province {
  const Province({
    required this.id,
    required this.regionId,
    this.ownerId,
    this.displayName,
  });

  final String id;
  final String regionId;
  final String? ownerId;
  /// Optional human-readable name (from ruleset naming config).
  final String? displayName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'regionId': regionId,
        'ownerId': ownerId,
        if (displayName != null) 'displayName': displayName,
      };

  static Province fromJson(Map<String, dynamic> json) {
    return Province(
      id: json['id'] as String,
      regionId: json['regionId'] as String,
      ownerId: json['ownerId'] as String?,
      displayName: json['displayName'] as String?,
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
          displayName == other.displayName;

  @override
  int get hashCode => Object.hash(id, regionId, ownerId, displayName);
}
