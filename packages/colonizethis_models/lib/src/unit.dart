/// Military or civilian unit. SPEC/game/world-model. Phase 2+ adds strength, movement.
class Unit {
  const Unit({
    required this.id,
    required this.type,
    required this.ownerId,
    required this.provinceId,
  });

  final String id;
  final String type;
  final String ownerId;
  final String provinceId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'ownerId': ownerId,
        'provinceId': provinceId,
      };

  static Unit fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'] as String,
      type: json['type'] as String,
      ownerId: json['ownerId'] as String,
      provinceId: json['provinceId'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Unit &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          ownerId == other.ownerId &&
          provinceId == other.provinceId;

  @override
  int get hashCode => Object.hash(id, type, ownerId, provinceId);
}
