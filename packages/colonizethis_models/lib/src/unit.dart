/// Military or civilian unit. SPEC/game/world-model.
class Unit {
  const Unit({
    required this.id,
    required this.type,
    required this.ownerId,
    required this.provinceId,
    this.status = UnitStatus.idle,
    this.movementPoints = 0,
  });

  final String id;
  final String type;
  final String ownerId;
  final String provinceId;
  final UnitStatus status;
  final int movementPoints;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'ownerId': ownerId,
        'provinceId': provinceId,
        'status': status.name,
        'movementPoints': movementPoints,
      };

  static Unit fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'] as String,
      type: json['type'] as String,
      ownerId: json['ownerId'] as String,
      provinceId: json['provinceId'] as String,
      status: _statusFromJson(json['status'] as String?),
      movementPoints: (json['movementPoints'] as int?) ?? 0,
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
          provinceId == other.provinceId &&
          status == other.status &&
          movementPoints == other.movementPoints;

  @override
  int get hashCode => Object.hash(id, type, ownerId, provinceId, status, movementPoints);
}

/// Minimal status for Phase 2 work and movement.
enum UnitStatus {
  idle,
  working,
  done,
}

UnitStatus _statusFromJson(String? value) {
  if (value == null) return UnitStatus.idle;
  return UnitStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => UnitStatus.idle,
  );
}
