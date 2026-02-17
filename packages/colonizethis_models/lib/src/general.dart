/// General leading an army. SPEC/game/military-units.md.
/// Phase 3: minimal model for initiative and combat.
class General {
  const General({
    required this.id,
    required this.ownerId,
    this.medals = 0,
    this.provinceId,
  });

  final String id;
  final String ownerId;

  /// Experience medals (0–4); affects initiative and deployment. SPEC/game/military-units.md.
  final int medals;

  /// Province where general is attached to an army. Null if unassigned.
  final String? provinceId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        if (medals != 0) 'medals': medals,
        if (provinceId != null) 'provinceId': provinceId,
      };

  static General fromJson(Map<String, dynamic> json) {
    return General(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      medals: (json['medals'] as int?) ?? 0,
      provinceId: json['provinceId'] as String?,
    );
  }

  General copyWith({
    String? id,
    String? ownerId,
    int? medals,
    String? provinceId,
  }) {
    return General(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      medals: medals ?? this.medals,
      provinceId: provinceId ?? this.provinceId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is General &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ownerId == other.ownerId &&
          medals == other.medals &&
          provinceId == other.provinceId;

  @override
  int get hashCode => Object.hash(id, ownerId, medals, provinceId);
}
