import 'region_data.dart';
import 'turn_state.dart';

/// Snapshot at a point in time. Turn state + region data. SPEC/game/world-model.
class WorldState {
  const WorldState({
    required this.turnState,
    required this.oldWorld,
    required this.newWorld,
  });

  final TurnState turnState;
  final RegionData oldWorld;
  final RegionData newWorld;

  Map<String, dynamic> toJson() => {
        'turnState': turnState.toJson(),
        'oldWorld': oldWorld.toJson(),
        'newWorld': newWorld.toJson(),
      };

  static WorldState fromJson(Map<String, dynamic> json) {
    return WorldState(
      turnState: TurnState.fromJson(Map<String, dynamic>.from(json['turnState'] as Map)),
      oldWorld: RegionData.fromJson(Map<String, dynamic>.from(json['oldWorld'] as Map)),
      newWorld: RegionData.fromJson(Map<String, dynamic>.from(json['newWorld'] as Map)),
    );
  }

  WorldState copyWith({
    TurnState? turnState,
    RegionData? oldWorld,
    RegionData? newWorld,
  }) {
    return WorldState(
      turnState: turnState ?? this.turnState,
      oldWorld: oldWorld ?? this.oldWorld,
      newWorld: newWorld ?? this.newWorld,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldState &&
          runtimeType == other.runtimeType &&
          turnState == other.turnState &&
          oldWorld == other.oldWorld &&
          newWorld == other.newWorld;

  @override
  int get hashCode => Object.hash(turnState, oldWorld, newWorld);
}
