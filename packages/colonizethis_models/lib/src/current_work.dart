/// Multi-turn work in progress for a civilian. SPEC/program/development-resolution.md.
class CurrentWork {
  const CurrentWork({
    required this.workTarget,
    required this.tileKey,
    required this.totalTurns,
    required this.remainingTurns,
  });

  final String workTarget;
  final String tileKey;
  final int totalTurns;
  final int remainingTurns;

  Map<String, dynamic> toJson() => {
        'workTarget': workTarget,
        'tileKey': tileKey,
        'totalTurns': totalTurns,
        'remainingTurns': remainingTurns,
      };

  static CurrentWork fromJson(Map<String, dynamic> json) {
    return CurrentWork(
      workTarget: json['workTarget'] as String,
      tileKey: json['tileKey'] as String,
      totalTurns: (json['totalTurns'] as int?) ?? 0,
      remainingTurns: (json['remainingTurns'] as int?) ?? 0,
    );
  }

  CurrentWork copyWith({
    String? workTarget,
    String? tileKey,
    int? totalTurns,
    int? remainingTurns,
  }) {
    return CurrentWork(
      workTarget: workTarget ?? this.workTarget,
      tileKey: tileKey ?? this.tileKey,
      totalTurns: totalTurns ?? this.totalTurns,
      remainingTurns: remainingTurns ?? this.remainingTurns,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrentWork &&
          runtimeType == other.runtimeType &&
          workTarget == other.workTarget &&
          tileKey == other.tileKey &&
          totalTurns == other.totalTurns &&
          remainingTurns == other.remainingTurns;

  @override
  int get hashCode => Object.hash(workTarget, tileKey, totalTurns, remainingTurns);
}
