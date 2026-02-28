/// General: abstract commander for combat. No map location; assignment at combat time.
/// SPEC/game/military-generals.md. Regiment types: SPEC/game/military-units.md.
class General {
  const General({
    required this.id,
    required this.ownerId,
    this.medals = 0,
  });

  final String id;
  final String ownerId;

  /// Experience medals (0–4); affects initiative, deployment, and morale aura. SPEC/game/military-generals.md.
  final int medals;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        if (medals != 0) 'medals': medals,
      };

  static General fromJson(Map<String, dynamic> json) {
    return General(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      medals: (json['medals'] as int?) ?? 0,
    );
  }

  General copyWith({
    String? id,
    String? ownerId,
    int? medals,
  }) {
    return General(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      medals: medals ?? this.medals,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is General &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ownerId == other.ownerId &&
          medals == other.medals;

  @override
  int get hashCode => Object.hash(id, ownerId, medals);
}
