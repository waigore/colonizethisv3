/// Great Power. SPEC/game/world-model.
class Player {
  const Player({
    required this.id,
    required this.displayName,
    required this.isHuman,
  });

  final String id;
  final String displayName;
  final bool isHuman;

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'isHuman': isHuman,
      };

  static Player fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      isHuman: json['isHuman'] as bool,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          displayName == other.displayName &&
          isHuman == other.isHuman;

  @override
  int get hashCode => Object.hash(id, displayName, isHuman);
}
