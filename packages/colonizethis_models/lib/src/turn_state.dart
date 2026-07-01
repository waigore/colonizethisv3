import 'model_validation_exception.dart';

/// Turn phase in resolution sequence. SPEC/program/turn-resolution.
/// SPEC/program/turn-resolution-phases.md
enum TurnPhase {
  orders,
  extraction,
  richesToTreasury,
  production,
  consumption,
  research,
  diplomacy,
  spyResolution,
  movement,
  minorRegimentUpgrade,
  navalInterceptionCombat,
  combat,
  buildWork,
  worldMarket,
  endOfTurn,
}

extension TurnPhaseJson on TurnPhase {
  static TurnPhase fromJson(String value) {
    return TurnPhase.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ModelValidationException.value(
        value,
        'value',
        'Unknown TurnPhase',
      ),
    );
  }

  String toJson() => name;
}

/// Turn state: phase and turn number. Part of WorldState.
class TurnState {
  const TurnState({required this.phase, required this.turnNumber});

  final TurnPhase phase;
  final int turnNumber;

  Map<String, dynamic> toJson() => {
    'phase': phase.toJson(),
    'turnNumber': turnNumber,
  };

  static TurnState fromJson(Map<String, dynamic> json) {
    return TurnState(
      phase: TurnPhaseJson.fromJson(json['phase'] as String),
      turnNumber: json['turnNumber'] as int,
    );
  }

  TurnState copyWith({TurnPhase? phase, int? turnNumber}) {
    return TurnState(
      phase: phase ?? this.phase,
      turnNumber: turnNumber ?? this.turnNumber,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TurnState &&
          runtimeType == other.runtimeType &&
          phase == other.phase &&
          turnNumber == other.turnNumber;

  @override
  int get hashCode => Object.hash(phase, turnNumber);
}
