/// Per-player orders for the current turn. Phase 1 stub; full order types in Phase 2+.
/// SPEC/game/world-model.
class Orders {
  const Orders({this.byPlayerId = const {}});

  /// Player id -> order payload (stub: empty map or minimal structure).
  final Map<String, Map<String, dynamic>> byPlayerId;

  Map<String, dynamic> toJson() => {
        'byPlayerId': byPlayerId,
      };

  static Orders fromJson(Map<String, dynamic> json) {
    final raw = json['byPlayerId'] as Map<dynamic, dynamic>? ?? {};
    final byPlayerId = raw.map(
      (k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v as Map)),
    );
    return Orders(byPlayerId: byPlayerId);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Orders && runtimeType == other.runtimeType && byPlayerId == other.byPlayerId;

  @override
  int get hashCode => Object.hash(runtimeType, byPlayerId);
}
