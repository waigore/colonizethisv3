/// Victory type and finished-game victory state.
///
/// Extracted from `game.dart` so the Game aggregate stays under the models
/// 500 non-comment-line cap (Refs #4068). SPEC/game/victory.md.

/// Victory type. Phase 5: military only (31+ OW provinces). SPEC/game/victory.md.
enum VictoryType { military }

extension VictoryTypeJson on VictoryType {
  static VictoryType fromJson(String value) {
    return VictoryType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => VictoryType.military,
    );
  }

  String toJson() => name;
}

/// Victory state for a finished game.
class VictoryState {
  const VictoryState({
    required this.winnerPlayerId,
    required this.type,
    required this.turnNumber,
  });

  final String winnerPlayerId;
  final VictoryType type;
  final int turnNumber;

  Map<String, dynamic> toJson() => {
    'winnerPlayerId': winnerPlayerId,
    'type': type.toJson(),
    'turnNumber': turnNumber,
  };

  static VictoryState fromJson(Map<String, dynamic> json) {
    return VictoryState(
      winnerPlayerId: json['winnerPlayerId'] as String,
      type: VictoryTypeJson.fromJson(json['type'] as String),
      turnNumber: json['turnNumber'] as int,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VictoryState &&
          runtimeType == other.runtimeType &&
          winnerPlayerId == other.winnerPlayerId &&
          type == other.type &&
          turnNumber == other.turnNumber;

  @override
  int get hashCode => Object.hash(winnerPlayerId, type, turnNumber);
}
