/// Military or civilian unit. SPEC/game/world-model.
/// Phase 3: medals (0–4) for military experience per SPEC/game/military-units.md.
class Unit {
  const Unit({
    required this.id,
    required this.type,
    required this.ownerId,
    required this.provinceId,
    this.status = UnitStatus.idle,
    this.movementPoints = 0,
    this.medals = 0,
  });

  final String id;
  final String type;
  final String ownerId;
  final String provinceId;
  final UnitStatus status;
  final int movementPoints;

  /// Experience medals (0–4); multiplies FPN/FPM in combat. SPEC/game/military-units.md.
  final int medals;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'ownerId': ownerId,
        'provinceId': provinceId,
        'status': status.name,
        'movementPoints': movementPoints,
        if (medals != 0) 'medals': medals,
      };

  static Unit fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'] as String,
      type: json['type'] as String,
      ownerId: json['ownerId'] as String,
      provinceId: json['provinceId'] as String,
      status: _statusFromJson(json['status'] as String?),
      movementPoints: (json['movementPoints'] as int?) ?? 0,
      medals: (json['medals'] as int?) ?? 0,
    );
  }

  Unit copyWith({
    String? id,
    String? type,
    String? ownerId,
    String? provinceId,
    UnitStatus? status,
    int? movementPoints,
    int? medals,
  }) {
    return Unit(
      id: id ?? this.id,
      type: type ?? this.type,
      ownerId: ownerId ?? this.ownerId,
      provinceId: provinceId ?? this.provinceId,
      status: status ?? this.status,
      movementPoints: movementPoints ?? this.movementPoints,
      medals: medals ?? this.medals,
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
          movementPoints == other.movementPoints &&
          medals == other.medals;

  @override
  int get hashCode =>
      Object.hash(id, type, ownerId, provinceId, status, movementPoints, medals);
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
