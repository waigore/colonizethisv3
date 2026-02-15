/// One map tile in a region. SPEC/game/world-model.
class Province {
  const Province({
    required this.id,
    required this.regionId,
    this.ownerId,
  });

  final String id;
  final String regionId;
  final String? ownerId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'regionId': regionId,
        'ownerId': ownerId,
      };

  static Province fromJson(Map<String, dynamic> json) {
    return Province(
      id: json['id'] as String,
      regionId: json['regionId'] as String,
      ownerId: json['ownerId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Province &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          regionId == other.regionId &&
          ownerId == other.ownerId;

  @override
  int get hashCode => Object.hash(id, regionId, ownerId);
}
